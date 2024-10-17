import 'package:flutter/material.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/modify_statement_route.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/oneofus/crypto/crypto.dart';
import 'package:oneofus/oneofus/jsonish.dart';
import 'package:oneofus/oneofus/statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/oneofus/util.dart';
import 'package:oneofus/trusts_route.dart';
import 'package:oneofus/widgets/qr_scanner.dart';

import 'oneofus/trust_statement.dart';
import 'statement_action_picker.dart';

/// 2 storages, a challenge to keep in sync:
/// - secure storage on this device: key pairs for Oneofus and delegate keys
/// - Firestore: public keys that are/were Oneofus and delegate.
///
/// Strive towards and encourage a delegate keys rep invariant:
///   Delegate key pair local (on phone) only if delegate key associated with you.
///
/// A local delegate key pair can become no longer associated with you when the user does a
/// variety of things.
/// - clear a delegate statement, maybe (seems obvious, but there could be an equivalent
///   that's claimed it.)
/// - clear a Oneofus key replace
/// - modify revokeAt for a replaced Oneofus key
/// - The user can also overwrite his private key by creating a new delegate key for a domain when
///   one already exists
/// The crux of the biscuit: How much work will this be? A lot, and it will require unit tests.

/// TODO: Update comments and thoughts to match code.
/// Warnings that I can't promise to get right, and so I'll not even try:
/// - local delegate key becomes disassociated
/// Warnings thatI can get right:
///  'You currently have a delegate key pair for $domain on this device. Overwrite it?'
/// - TODO: Warn at import keys
///  'This will overwrite all existing keys.'
///
/// I'll do the ones I can and also
/// - check invariant after any possible change and offer the user:
///   'You currently have a delegate key pair for $domain on this device, but it is not associated with you. Claim it or delete it?'

/// Definitions:
/// 'Lost key':
/// A key that represented or still represents you but which you don't have the private key.
/// 'My Oneofus keys':
/// Firebase: chain of replace statements to them.
/// (Note that any of these can be lost.)
/// 'My delegate keys':
/// Firebase: keys I've delegated using any of my Oneofus keys (includes equivalent keys).
/// (Note that any of these can be lost.)
///
/// Storing multiple key pairs the same host (or Oneofus) is not supported. A user can
/// make a mess using multiple devices, import/export, but it should be a manageable mess.
///
/// The basics:
/// Set or update 'revokeAt' for delegate keys (null okay).
/// Set or change 'comment' (null okay).
/// (no moniker)

class DelegateKeysRoute extends StatelessWidget {
  const DelegateKeysRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Delegate keys')),
        body: ListView(children: [
          const Linky(
              '''Below are 'delegate' key statements signed by your active key or by any of your older, replaced, equivalent keys.
Click on them to restate them with (with your current key only).      
https://RTFM#delegates.'''),
          const StatementActionPicker({TrustVerb.delegate}, [TrustVerb.delegate, TrustVerb.clear]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            OutlinedButton(
                onPressed: () async {
                  Jsonish? jsonish = await claimDelegateKey(context);
                },
                child: const Text('Claim existing')),
            OutlinedButton(
                onPressed: () async {
                  Jsonish? jsonish = await createNewDelegateKey(null, context);
                },
                child: const Text('Create new')),
          ]),
        ]));
  }
}

Future<Jsonish?> createNewDelegateKey(String? domain, BuildContext context) async {
  OouKeyPair delegateKeyPair = await crypto.createKeyPair();
  OouPublicKey delegatePublicKey = await delegateKeyPair.publicKey;
  Json delegatePublicKeyJson = await delegatePublicKey.json;
  Json statementStarterJson = {
    "statement": kOneofusDomain,
    "time": clock.nowIso,
    "I": MyKeys.oneofusPublicKey,
    TrustVerb.delegate.label: delegatePublicKeyJson,
    if (b(domain)) "with": {"domain": domain}
  };
  TrustStatement ts = TrustStatement(Jsonish(statementStarterJson));
  Jsonish? jsonish = await ModifyStatementRoute.show(ts, const [TrustVerb.delegate], true, context);
  if (b(jsonish)) {
    ts = Statement.make(jsonish!) as TrustStatement;
    assert(ts.domain!.length > 1);
    await MyKeys.storeDelegateKey(delegateKeyPair, ts.domain!);
    assert(MyKeys.getDelegateToken(ts.domain!) == getToken(delegatePublicKeyJson));
  }
  return jsonish;
}

Future<Jsonish?> claimDelegateKey(BuildContext context) async {
  String? scanned =
      await QrScanner.scan('Scan a public key QR code', validatePublicKeyJson, context);
  if (b(scanned)) {
    Json subjectKeyJson = await parsePublicKey(scanned!);
    return await stateClaimDelegateKey(subjectKeyJson, context);
  }
  return null;
}

Future<Jsonish?> stateClaimDelegateKey(Json subjectJson, BuildContext context,
    {String? domain}) async {
  try {
    String subjectToken = getToken(subjectJson);

    // Checks
    if (subjectToken == MyKeys.oneofusToken) {
      await alert(
          '''That's you''', '''That's your, active own one-of-us key.''', ['Okay'], context);
      return null;
    }
    // Lookup my disposition to this key
    Iterable<TrustStatement> mine = MyStatements.getBySubject(subjectToken);
    if (mine.isNotEmpty) {
      TrustStatement ts = mine.first;
      switch (ts.verb) {
        case TrustVerb.trust:
          await alert('already trust "${ts.moniker}"', '', ['Okay'], context);
          return null;
        case TrustVerb.block:
          await alert('already block', 'comment: ${ts.comment}', ['Okay'], context);
          return null;
        case TrustVerb.replace:
          await alert(
              'This is one of your equivalent keys', 'comment: ${ts.comment}', ['Okay'], context);
          return null;
        case TrustVerb.delegate:
          await alert('This is already one of your delegate keys', 'domain: ${ts.domain}', ['Okay'],
              context);
          return null;
        default:
          throw Exception('Unexpected: ${ts.verb}');
      }
    }

    Json prototypeJson = {
      "statement": kOneofusDomain,
      "time": clock.nowIso,
      "I": MyKeys.oneofusPublicKey,
      TrustVerb.delegate.label: subjectJson,
      if (b(domain)) 'with': {'domain': domain}
    };
    TrustStatement prototype = TrustStatement(Jsonish(prototypeJson));

    assert(prototype.subjectToken == subjectToken);
    Jsonish? jsonish = await ModifyStatementRoute.show(prototype, [TrustVerb.delegate], true, context);
    return jsonish;
  } catch (e, stackTrace) {
    if (context.mounted) {
      await alertException(context, e, stackTrace: stackTrace);
    }
    return null;
  }
}

Future<void> encourageDelegateRepInvariant(BuildContext context) async {
  List<TrustStatement> delegateStatements = MyStatements.getByVerbs({TrustVerb.delegate});
  bool isClaimed(String domain, String publicKeyToken) {
    for (TrustStatement statement in delegateStatements) {
      if (statement.domain == domain && statement.subjectToken == publicKeyToken) {
        // We're good. This local delegate key pair is associated with us.
        return true;
      }
    }
    return false;
  }

  for (MapEntry e in MyKeys.publicExportNotifier.value.entries) {
    String domain = e.key;
    if (domain == kOneofusDomain) {
      continue;
    }
    var publicKeyJson = e.value;
    String publicKeyToken = getToken(publicKeyJson);
    if (!isClaimed(domain, publicKeyToken)) {
      String? claimOdelete = await alert(
          'Claim or Delete?',
          '''You currently have a delegate key pair for $domain on this device, but it is not associated with you.
Claim it or Delete it?''',
          ['Claim', 'Delete', 'Ignore'],
          context);
      // null returned on back button
      if (b(claimOdelete)) {
        if (claimOdelete == 'Claim') {
          if (context.mounted) {
            Jsonish? jsonish = await stateClaimDelegateKey(publicKeyJson, domain: domain, context);
          }
        } else if (claimOdelete == 'Delete') {
          await MyKeys.deleteDelegateKey(domain);
        }
      }
    }
  }
}
