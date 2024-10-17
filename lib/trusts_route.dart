import 'dart:convert';

import 'package:flutter/material.dart';
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

String trustDesc = '''You reference other folks' public key in trust/block statements: 
Trust is meant to certify that they're human, understand this, and are acting in good faith.
Block is an extreme measure and should be reserved for bots, spammers, and other bad actors.''';

class TrustsRoute extends StatelessWidget {
  const TrustsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Trust Statements')),
        // I hacked around here and in StatementPicker to make stuff scroll when
        // there's too many statements to fit, don't understand any of it.
        // Tried: CustomScrollView with SliverFillRemaining, SingleChildScrollView, etc...
        body: SafeArea(
            child: Column(children: [
          const Linky(
            // TODO: Make this text be part of StatementActionPicker
              '''Below are trust statements signed by your active key or by any of your older, replaced, equivalent keys.
Click on them to restate and/or modify them with (with your current key only).      
RTFM: http://RTFM#re-state.'''),
          const Flexible(
            child: StatementActionPicker({
              TrustVerb.trust,
              TrustVerb.block
            }, [
              TrustVerb.trust,
              TrustVerb.block,
              TrustVerb.clear,
            ]),
          ),
          Row(children: [
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
    bool newStatement;
    if (myTrustsBlocks.isNotEmpty) {
      assert(myTrustsBlocks.length == 1);
      prototype = myTrustsBlocks.first;
      newStatement = false;
    } else {
      Json prototypeJson = {
        "statement": kOneofusDomain,
        "time": clock.nowIso,
        "I": MyKeys.oneofusPublicKey,
        TrustVerb.trust.label: subjectJson,
      };
      prototype = TrustStatement(Jsonish(prototypeJson));
      newStatement = true;
    }

    Jsonish? jsonish =
        await ModifyStatementRoute.show(prototype, const [TrustVerb.trust, TrustVerb.block, TrustVerb.clear], newStatement, context);
    return jsonish;
  } catch (e) {
    await alertException(context, e);
    return null;
  }
}
