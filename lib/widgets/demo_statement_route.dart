import 'package:flutter/material.dart';
import 'package:oneofus/confirm_statement_route.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/oneofus/ui/rtfm_anchors.dart';
import 'package:oneofus/widgets/statement_widget.dart';

import 'key_widget.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/trust_statement.dart';

final KeyWidget myOneofusKey = KeyWidget.skip('dummy', true, KeyType.oneofus, false);
final KeyWidget myEquivalentKey = KeyWidget.skip('dummy', false, KeyType.oneofus, true);
final KeyWidget myActiveDelegateKey = KeyWidget.skip('dummy', true, KeyType.delegate, false);
final KeyWidget myLostDelegateKey = KeyWidget.skip('dummy', false, KeyType.delegate, false);
final KeyWidget keyIBlocked = KeyWidget.skip('dummy', false, KeyType.other, true);
final KeyWidget keyITrust = KeyWidget.skip('dummy', false, KeyType.other, false);

Future<void> showDemoStatements(context) async {
  DemoStatementRoute demoBoxRoute = DemoStatementRoute();
  await Navigator.of(context).push(MaterialPageRoute(builder: (context) => demoBoxRoute));
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

    const space = SizedBox(height: 20);
    return Scaffold(
        appBar: AppBar(title: const Text('Statements, Keys, oh my..')),
        body: ListView(shrinkWrap: true, physics: const AlwaysScrollableScrollPhysics(), children: [
          const Linky('''Read the https://RTFM

Statements:
- Statements are signed by keys and stored in the cloud.
- Statements are signed using someone's private key. The signing public key is referenced in the statement, and anyone can verify its authenticity.
- All one-of-us statements are also about some other key.
- The top right key in a statement box represents the signing key; top left represents the subject key.
'''),

          const Linky('''Keys:'''),
          const Linky('''
- Your keys (private/public pairs) are stored on your phone. 
- Keys can be 
  - a one-of-us key of yours (green), a delegate key of yours (blue), or someone else's (gray)
  - revoked, replaced, or blocked (cross through icon)
  - local (you have the private key on your phone - dark color) or lost (light color)'''),
          Row(
            children: [
              myOneofusKey,
              myEquivalentKey,
              myActiveDelegateKey,
              myLostDelegateKey,
              keyIBlocked,
              keyITrust
            ],
          ),

          space,
          const Linky('''Samples:'''),
          space,
          const Linky(
              '''The owner of this key is human, known to me, and is capable of understanding what we're doing here.'''),
          make(myOneofusKey, TrustVerb.trust, keyITrust,
              moniker: 'moniker',
              comment:
                  'Use the comment and moniker fields so that you and/or others know who this person is (ex. moniker: Steve, comment: coke dealer)'),
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
              '''I've delegated this disposable key for domain.com to make statements on my behalf.'''),
          make(myOneofusKey, TrustVerb.delegate, myActiveDelegateKey,
              domain: 'domain.com', comment: 'optional comment'),
        ]));
  }
}
