import 'package:flutter/material.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/oneofus/statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/ui/linky.dart';

import 'base/my_keys.dart';
import 'base/my_statements.dart';
import 'modify_statement_route.dart';
import 'oneofus/jsonish.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/util.dart';
import 'statement_action_picker.dart';
import 'widgets/qr_scanner.dart';

const String _descTop = '''You reference other folks' public keys in {trust, block} statements. 
These form your (and our) one-of-us network.''';
const String _descVerbs = '''trust: human, capable, acting in good faith.
block: bots, spammers, bad actors, careless, confused, ...''';
const Map<TrustVerb, String> _descVerb = {
  TrustVerb.trust: '''moniker: First name is a typical choice.
comment: Optional, could be about your relationship or the circumstances.''',
  TrustVerb.block:
      '''comment: Recommended but not required. Why are you choosing to block this key?''',
  TrustVerb.clear: '''No fields to fill out (you're erasing after all).''',
};

const RouteSpec trustRouteSpec =
    RouteSpec([TrustVerb.trust, TrustVerb.block], _descTop, _descVerbs, _descVerb);

class TrustsRoute extends StatelessWidget {
  const TrustsRoute({super.key});
  static const spec = trustRouteSpec;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(formatVerbs(spec.verbs))),
        body: SafeArea(
            child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
              Linky(spec.descTop),
              kDivider,
              StatementActionPicker(spec),
              kDivider,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton(
                    onPressed: () async {
                      Json? jsonPublicKey = await QrScanner.scanPublicKey(context);
                      if (!b(jsonPublicKey)) return;
                      if (!context.mounted) return;
                      await startTrust(jsonPublicKey!, context);
                    },
                    child: const Text('New Trust or block')),
              ]),
            ])));
  }
}

Future<TrustStatement?> startTrust(Json subjectJson, context) async {
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
    TrustStatement? statement = await ModifyStatementRoute.show(prototype, TrustsRoute.spec, context);
    return statement;
  } catch (e) {
    await alertException(context, e);
    return null;
  }
}
