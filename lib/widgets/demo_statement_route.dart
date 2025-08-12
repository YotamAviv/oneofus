import 'package:flutter/material.dart';
import 'package:oneofus/confirm_statement_route.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/widgets/statement_widget.dart';

import 'key_widget.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/trust_statement.dart';

const space = SizedBox(height: 20);

const Json dummy = {"dummy" : "dummy"};

final KeyWidget myOneofusKey = KeyWidget.skip(dummy, 'dummy', true, KeyType.oneofus, false);
final KeyWidget myEquivalentKey = KeyWidget.skip(dummy, 'dummy', false, KeyType.oneofus, true);
final KeyWidget myActiveDelegateKey = KeyWidget.skip(dummy, 'dummy', true, KeyType.delegate, false);
final KeyWidget myLostDelegateKey = KeyWidget.skip(dummy, 'dummy', false, KeyType.delegate, false);
final KeyWidget myRevokedDelegateKey = KeyWidget.skip(dummy, 'dummy', false, KeyType.delegate, true);
final KeyWidget keyIBlocked = KeyWidget.skip(dummy, 'dummy', false, KeyType.other, true);
final KeyWidget keyITrust = KeyWidget.skip(dummy, 'dummy', false, KeyType.other, false);

Future<void> showDemoKeys(context) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (context) => DemoKeysRoute()));
}

class DemoKeysRoute extends StatelessWidget {
  DemoKeysRoute({super.key});

  final Json keyX = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keys')),
      body: ListView(shrinkWrap: true, physics: const AlwaysScrollableScrollPhysics(), children: [
        const Linky('''
Your keys (private/public pairs) are stored on your phone. 
Public keys can be 
  - your active identity key (green)
  - your active one delegate keys (blue)
  - someone else's key (gray)'''),
        Row(
          children: [
            myOneofusKey,
            myActiveDelegateKey,
            keyITrust
          ],
        ),
        space,
      const Linky('''
Keys can be: replaced, revoked, or blocked (cross through icon)'''),
        Row(
          children: [
            myEquivalentKey,
            myRevokedDelegateKey,
            keyIBlocked,
          ],
        ),
      space,
      const Linky('''
The private key may be available or lost:
  - available (the private key is on your phone - dark color)
  - lost (this app does not have the private key - light color)'''),
        Row(
          children: [
            myActiveDelegateKey,
            myLostDelegateKey
          ],
        ),
        space,
        const Linky('''Read the https://manual'''),
      ]),
    );
  }
}

Future<void> showDemoStatements(context) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (context) => DemoStatementRoute()));
}

class DemoStatementRoute extends StatelessWidget {
  DemoStatementRoute({super.key});

  final Json keyX = {};

  @override
  Widget build(BuildContext context) {
    StatementWidget make(KeyWidget iKey, TrustVerb verb, KeyWidget subjectKey,
        {String? revokeAt, String? moniker, String? domain, String? comment}) {
      Json json = TrustStatement.make(keyX, keyX, verb,
          revokeAt: revokeAt, moniker: moniker, domain: domain, comment: comment);
      TrustStatement statement = TrustStatement(Jsonish(json));
      StatementWidget box = StatementWidget(statement, () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConfirmStatementRoute(json),
          ),
        );
      }, iKeyDemo: iKey, subjectKeyDemo: subjectKey);
      return box;
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Statements')),
        body: ListView(shrinkWrap: true, physics: const AlwaysScrollableScrollPhysics(), children: [
          const Linky('''Statements are 
- signed by a key (top right of statement box display)
- use a verb: trust, block, replace, delegate
- reference another key (top left of statement box display)
Different verbs may require different fields, such as: moniker, revokeAt, comment, etc..
Samples below:'''),

          space,
          const Linky(
              '''The owner of this key is human, known to me, and is capable of understanding what we're doing here.'''),
          make(myOneofusKey, TrustVerb.trust, keyITrust,
              moniker: 'Steve',
              comment:
                  'College buddy'),
          space,
          const Linky(
              '''Fraud, deception, or foolishness has been committed using this key; it is not to be trusted.'''),
          make(myOneofusKey, TrustVerb.block, keyIBlocked,
              comment: 'Optionally comment describing to you or others understands what happened'),
          // Moniker allowed?
          space,

          const Linky(
              '''This past key of mine is lost or compromised; what it has signed up to the identified revokeAt statement is to be trusted as having been stated by me..'''),
          make(myOneofusKey, TrustVerb.replace, myEquivalentKey,
              revokeAt: '<gibberish identifying last valid use>', comment: 'optional comment'),
          space,

          const Linky(
              '''I've delegated this disposable key for nerdster.org to make statements on my behalf.'''),
          make(myOneofusKey, TrustVerb.delegate, myActiveDelegateKey,
              domain: 'nerdster.org'),
          space,

          const Linky('''Read the https://manual'''),
        ]));
  }
}
