import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/delegate_revoke_at_editor.dart';
import 'package:oneofus/field_editor.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus_revoke_at_editor.dart';
import 'package:oneofus/text_editor.dart';
import 'package:oneofus/widgets/key_widget.dart';
import 'package:oneofus/widgets/loading.dart';

import 'base/my_keys.dart';
import 'confirm_statement_route.dart';
import 'oneofus/crypto/crypto.dart';
import 'oneofus/fetcher.dart';
import 'oneofus/jsonish.dart';
import 'oneofus/oou_signer.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/util.dart';
import 'widgets/statement_widget.dart';

/// Issue a new statement based on an existing statement
/// - keep same subject
/// - issue using current (active) Oneofus key
/// - update fields, stuff like:
///   - verb (restricted to choices)
///   - domain (only if started as null (Kludgey))
///   - moniker
///   - comment
///   - revokeAt
///
/// There are quite a few checks that ended up here. Oh, wel...
class ModifyStatementRoute extends StatefulWidget {
  final TrustStatement statement;
  final List<TrustVerb> choices;
  final KeyWidget? subjectKeyDemo;

  const ModifyStatementRoute(this.statement, this.choices, {this.subjectKeyDemo, super.key});

  @override
  State<StatefulWidget> createState() => _ModifyStatementRouteState();

  // TODO(3): Understand what a "MaterialPageRoute" is and consider getting rid of these "show" helpers.
  static Future<Jsonish?> show(
      TrustStatement statement, List<TrustVerb> choices, BuildContext context,
      {KeyWidget? subjectKeyDemo}) async {
    Jsonish? out = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            ModifyStatementRoute(statement, choices, subjectKeyDemo: subjectKeyDemo)));
    return out;
  }
}

class _ModifyStatementRouteState extends State<ModifyStatementRoute> {
  TrustVerb? choice;
  List<FieldEditor>? editorWidgets;
  ValueNotifier<bool> errors = ValueNotifier<bool>(false);
  bool pushInitiated = false;

  @override
  void initState() {
    super.initState();
    // I was getting errors related to widget "currently being built",
    // and this seems to have fixed it.
    errors.addListener(() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.choices.length == 1 && !b(choice)) {
      // Don't know why, but build is being called twice, don't want to call _makeEditors twice.
      choice = widget.choices.first;
      _makeEditors(widget.statement, choice!);
    }

    List<Widget> choices = <Widget>[];
    for (TrustVerb verb in widget.choices) {
      VoidCallback? onPressed = makeOnPressed(verb);
      ButtonStyle? style;
      if (b(onPressed) && b(choice)) {
        Color color = errors.value ? Colors.red : Colors.green;
        style = OutlinedButton.styleFrom(side: BorderSide(width: 3.0, color: color));
      }
      choices.add(OutlinedButton(
          onPressed: !errors.value ? onPressed : null, style: style, child: Text(verb.label)));
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Edit Statement')),
        body: ListView(children: [
          if (widget.statement.iToken != MyKeys.oneofusToken) const Text('''NOTE:
This statement was signed by one of your replaced, equivalent keys, not by your active key.            
If you restate this statement with your active key, the old statement signed by your old key will not be overwritten.'''),
          StatementWidget(
            widget.statement,
            null,
            subjectKeyDemo: widget.subjectKeyDemo,
          ),
          if (choice != null)
            Column(
              children: editorWidgets!,
            ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: choices),
        ]));
  }

  // (This 'makeOnPressed' is a bit screwy and confusing, sorry;)
  Function()? makeOnPressed(TrustVerb thisChoice) {
    if (pushInitiated) {
      // Don't let the user Fetcher.push again
      return null;
    }
    if (choice == null) {
      return () async {
        if (await _checkChoice(thisChoice)) {
          choice = thisChoice;
          _makeEditors(widget.statement, choice!);
          setState(() {});
        }
      };
    } else if (choice == thisChoice) {
      return () async {
        Json json = _prepare();
        // Perform checks (overwrite delegate key? lose delegate key?)
        bool okayToContinue = await _prePush(json);
        if (!okayToContinue) {
          if (mounted) Navigator.pop(context, null);
          return;
        }
        bool? lgtm = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ConfirmStatementRoute(json)),
        );
        if (b(lgtm) && lgtm!) {
          setState(() {
            pushInitiated = true;
          });
          if (mounted) {
            Jsonish? jsonish = await _state(json, context);
            Navigator.pop(context, jsonish);
          }
        }
      };
    } else {
      // (onPressed == null makes button disabled)
      return null;
    }
  }

  // return true if okay to continue.
  Future<bool> _prePush(Json json) async {
    // Check if user will overwrite a local delegate key pair.
    if (choice == TrustVerb.delegate) {
      TrustStatement contingentStatement = TrustStatement(Jsonish(json));
      String domain = contingentStatement.domain!;
      String? localDelegateToken = MyKeys.getDelegateToken(domain);
      String contingentDelegateToken = contingentStatement.subjectToken;
      if (b(localDelegateToken) && localDelegateToken != contingentDelegateToken) {
        String? overwrite = await alert(
            'overwrite local key pair?',
            '''You currently have a delegate key pair for $domain on this device. Overwrite it?''',
            ['Overwrite', 'Cancel'],
            context);
        return match(overwrite, 'Overwrite');
      }
    }
    return true;
  }

  Future<bool> _checkChoice(TrustVerb verb) async {
    // warn re: blocks
    if (verb == TrustVerb.block) {
      String? okay = await alert(
          'Block? Really?',
          '''Blocking a one-of-us key is harsh!
You should only block a key in case you have strong reason to believe that the key
- does not represent a real person
- or maybe it does represent a person, but that person is not acting in good faith (eg. blocks indiscriminately, trusts fake "Elon", etc..)
- or maybe that person trusts too carelessly or just doesn't get it (eg. scans QR keys from Instagram)
https://RTFM#block-oneofus-key
''',
          ['Okay', 'Cancel'],
          context);
      return match(okay, 'Okay');
    }
    if (verb == TrustVerb.clear && widget.statement.iToken != MyKeys.oneofusToken) {
      String? okay = await alert('''Can't, sorry..''',
          '''You stated this with a past, equivalent key pair, and this app no longer has the matching private key.
You should be able to {trust, block, delegate} this key using your current, active key, and that will likely override whatever your equivalent key has stated.
http://RTFM#equivalent-key-baggage
''', ['Okay'], context);
      return false;
    }
    if (verb == TrustVerb.clear && widget.statement.verb == TrustVerb.replace) {
      String? okay = await alert(
          'Careful..',
          '''When you clear a replace statement, a key that used to be understood as representing you may no longer  be understood to represent you.
Folks may be using that key to trust you or follow you.
If you've used that key to trust others but have not re-stated that trust using your current key, then the path of trust from you to them may be cleared as well.
https://RTFM#clear-replace
https://RTFM#revoke-equivalent
''',
          ['Okay', 'Cancel'],
          context);
      return match(okay, 'Okay');
    }
    if (verb == TrustVerb.clear && widget.statement.verb == TrustVerb.delegate) {
      String? okay = await alert(
          'Careful..',
          '''When you clear a delegate statement, a key that used to be understood as representing you may no longer be understood to represent you.
https://RTFM#clear-delegate
https://RTFM#revoke-delegate
''',
          ['Okay', 'Cancel'],
          context);
      return match(okay, 'Okay');
    }
    return true;
  }

  Json _prepare() {
    Json iKey = MyKeys.oneofusPublicKey;
    Map<String, String> map = {};
    for (FieldEditor w in editorWidgets!) {
      if (b(w.value)) {
        map[w.field] = w.value!;
      }
    }
    // We don't allow changing domain, and so if a delegate statement is being edited we don't
    // show an editor and use the domain from the prototype statement.
    String? domain = widget.statement.domain ?? map['domain'];
    Json json = TrustStatement.make(iKey, widget.statement.subject, choice!,
        moniker: map['moniker'],
        comment: map['comment'],
        revokeAt: map['revokeAt'],
        domain: domain);
    return json;
  }

  Future<Jsonish?> _state(json, BuildContext context) async {
    String token = MyKeys.oneofusToken;
    Fetcher f = Fetcher(token, kOneofusDomain);
    await f.fetch();
    OouKeyPair oneofusKeyPair = await crypto.parseKeyPair(MyKeys.oneofusKeyPair);
    OouSigner signer = await OouSigner.make(oneofusKeyPair);

    Jsonish? jsonish;
    try {
      Loading.push(context);

      if (b(slowPushMillis)) {
        for (int i = (slowPushMillis! ~/ 100); i > 0; i--) {
          print('slow... ... ... ... ... ... ... ... ... ... $i.');
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      if (exceptionWhenTryingToPush) {
        print('throwing bogus, intentional Exception.. ');
        throw Exception('bogus, intentional');
      }

      jsonish = await f.push(json, signer);
    } catch (e) {
      print('caught Exception: $e.');
      // DEFER: Report back to me.
      await alertException(context, e);
    } finally {
      Loading.pop(context);
    }

    if (context.mounted) await prepareX(context); // redundant?
    return jsonish;
  }

  void _makeEditors(TrustStatement statement, TrustVerb verb) {
    assert(!b(editorWidgets));
    if (b(editorWidgets)) {
      // I'm not sure why, but sometimes this gets called again, maybe the
      // addPostFrameCallback thing..
      return;
    }

    switch (verb) {
      case TrustVerb.trust:
        editorWidgets = [
          TextEditor('moniker', statement.moniker, minLength: 3),
          TextEditor('comment', statement.comment, maxLines: 3),
        ];
      case TrustVerb.block:
        editorWidgets = [
          TextEditor('comment', statement.comment, maxLines: 3),
        ];
      case TrustVerb.replace:
        editorWidgets = [
          TextEditor('comment', statement.comment, maxLines: 3, minLength: 3),
          OneofusRevokeAtEditor(statement),
        ];
      case TrustVerb.delegate:
        if (b(widget.statement.domain)) {
          editorWidgets = [
            TextEditor('comment', statement.comment, maxLines: 3),
            DelegateRevokeAtEditor(statement),
          ];
        } else {
          editorWidgets = [
            TextEditor('domain', statement.domain, minLength: 3, lowercase: true,),
            TextEditor('comment', statement.comment, maxLines: 3),
            DelegateRevokeAtEditor(statement),
          ];
        }
      case TrustVerb.clear:
        editorWidgets = [];
    }

    for (FieldEditor w in editorWidgets!) {
      w.errorState.addListener(() {
        errors.value = editorWidgets!.any((w) => w.errorState.value);
      });
    }
  }
}
