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
              '''Below are trust statements signed by your active key or by any of your older, replaced, equivalent keys.
Click on them to restate and/or modify them with (with your current key only).      
RTFM: http://RTFM#re-state.'''),
          const Flexible(
            child: StatementActionPicker({
              TrustVerb.trust,
              TrustVerb.block
            }, [
              TrustVerb.trust,
              TrustVerb.clear,
              TrustVerb.block,
            ]),
          ),
          Row(children: [
            OutlinedButton(
                onPressed: () async {
                  String? scanned = await QrScanner.scan(
                      'Scan a public key QR Code', scannerJsonPublicKeyValidate, context);
                  if (b(scanned)) {
                    if (!context.mounted) return;
                    Jsonish? jsonish = await scannerTrust(scanned!, context);
                  }
                },
                child: const Text('New Trust or block')),
          ]),
        ])));
  }
}

var validJsonNotKey = {"name": "Tom"};

Future<bool> scannerJsonPublicKeyValidate(String string) async {
  try {
    Json publicKeyJson = jsonDecode(string);
    await crypto.parsePublicKey(publicKeyJson);
    return true;
  } catch (e) {
    print('scannerJsonValidate($string) returning: false');
    return false;
  }
}

Future<Jsonish?> scannerTrust(String jsonS, context) async {
  try {
    Json subjectKeyJson = await parsePublicKey(jsonS);
    String subjectToken = Jsonish(subjectKeyJson).token;

    // Check
    if (subjectToken == MyKeys.oneofusToken) {
      await alert('''That's you''', '''Don't trust your own key.''', ['Okay'], context);
      return null;
    }
    TrustStatement ts;
    Iterable<TrustStatement> myReplaces = (MyStatements.collect(const {TrustVerb.replace}))
        .where((s) => s.subjectToken == subjectToken);
    if (myReplaces.isNotEmpty) {
      await alert('''That's you''', '''This is one of your equivalent keys.
If you need to clear or change that, go to menu => Keys => one-of-us... and clear or change your statement replacing that key.''',
          ['Okay'], context);
      return null;
    }
    Iterable<TrustStatement> myDelegates = (MyStatements.collect(const {TrustVerb.delegate}))
        .where((s) => s.subjectToken == subjectToken);
    if (myDelegates.isNotEmpty) {
      await alert('''That's your delegate key''', '''This is one of your delegate keys.
If you need to clear or change that, go to menu => Keys => Delegates... and clear or change your statement delegating that key.''',
          ['Okay'], context);
      return null;
    }

    Iterable<TrustStatement> myTrustsBlocks =
        (MyStatements.collect(const {TrustVerb.trust, TrustVerb.block}))
            .where((s) => s.subjectToken == subjectToken);
    if (myTrustsBlocks.isNotEmpty) {
      assert(myTrustsBlocks.length == 1);
      ts = myTrustsBlocks.first;
    } else {
      Json statementStarterJson = {
        "statement": kOneofusDomain,
        "time": clock.nowIso,
        "I": MyKeys.oneofusPublicKey,
        TrustVerb.trust.label: subjectKeyJson,
      };
      ts = TrustStatement(Jsonish(statementStarterJson));
    }

    Jsonish? jsonish =
        await ModifyStatementRoute.show(ts, const [TrustVerb.trust, TrustVerb.block], context);
    return jsonish;
  } catch (e) {
    await alertException(context, e);
    return null;
  }
}
