import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/oneofus/ui/alert.dart';

import 'base/my_keys.dart';
import 'modify_statement_route.dart';
import 'base/my_statements.dart';
import 'oneofus/jsonish.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/util.dart';
import 'statement_action_picker.dart';
import 'widgets/qr_scanner.dart';

String _descTop0 = '''You reference other folks' public keys in {trust, block} statements: 
Trust: {human, capable, acting in good faith}
Block: {bots, spammers, and other bad actors}
These statements form your (and our) one-of-us network.''';

String _descBottom = '''.''';

class TrustsRoute extends StatelessWidget {
  static const Set<TrustVerb> verbs = {TrustVerb.trust, TrustVerb.block};

  const TrustsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(formatVerbs(verbs))),
        body: SafeArea(
            child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
              Linky(_descTop0),
              const Divider(height: 10, thickness: 2),
              const StatementActionPicker(verbs),
              const Divider(height: 10, thickness: 2),
              Linky(_descBottom),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton(
                    onPressed: () async {
                      Json? jsonPublicKey = await QrScanner.scanPublicKey(context);
                      if (!b(jsonPublicKey)) return;
                      if (!context.mounted) return;
                      Jsonish? jsonish = await startTrust(jsonPublicKey!, context);
                    },
                    child: const Text('New Trust or block')),
              ]),
            ])));
  }
}

Future<Jsonish?> startTrust(Json subjectJson, context) async {
  try {
    String subjectToken = Jsonish(subjectJson).token;

    // Checks
    if (subjectToken == MyKeys.oneofusToken) {
      await alert('''That's you''', '''Don't trust your own key.''', ['Okay'], context);
      return null;
    }
    Iterable<TrustStatement> myReplaces = (MyStatements.getByVerbs(const {TrustVerb.replace}))
        .where((s) => s.subjectToken == subjectToken);
    if (myReplaces.isNotEmpty) {
      await alert('''That's you''', '''This is one of your equivalent keys.
If you need to clear or change that, go to menu => Keys => one-of-us... and clear or change your statement replacing that key.''',
          ['Okay'], context);
      return null;
    }
    Iterable<TrustStatement> myDelegates = (MyStatements.getByVerbs(const {TrustVerb.delegate}))
        .where((s) => s.subjectToken == subjectToken);
    if (myDelegates.isNotEmpty) {
      await alert('''That's you''', '''This is one of your delegate keys.
If you need to clear or change that, go to menu => Keys => Delegates... and clear or change your statement delegating that key.''',
          ['Okay'], context);
      return null;
    }

    TrustStatement prototype;
    // TODO: Verify this is correct and working as intended. If I scan a key that one of my equivs trusted, what's desired?
    // Regardless: Don't crash (assert(false)).
    Iterable<TrustStatement> myTrustsBlocks =
        (MyStatements.getByVerbs(const {TrustVerb.trust, TrustVerb.block}))
            .where((s) => s.subjectToken == subjectToken);
    bool fresh;
    if (myTrustsBlocks.isNotEmpty) {
      assert(myTrustsBlocks.length == 1);
      prototype = myTrustsBlocks.first;
      fresh = false;
    } else {
      Json prototypeJson = {
        "statement": kOneofusDomain,
        "time": clock.nowIso,
        "I": MyKeys.oneofusPublicKey,
        TrustVerb.trust.label: subjectJson,
      };
      prototype = TrustStatement(Jsonish(prototypeJson));
      fresh = true;
    }

    // Shouldn't need to check for clear (distincter)
    Jsonish? jsonish = await ModifyStatementRoute.show(
        prototype, const [TrustVerb.trust, TrustVerb.block], context);
    return jsonish;
  } catch (e) {
    await alertException(context, e);
    return null;
  }
}
