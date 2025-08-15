import 'package:flutter/material.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/modify_statement_route.dart';
import 'package:oneofus/oneofus/crypto/crypto.dart';
import 'package:oneofus/oneofus/jsonish.dart';
import 'package:oneofus/oneofus/statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/oneofus/util.dart';
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
/// The crux of the biscuit: How much work will this be? A lot, and it will require unit tests.
/// A local delegate key pair can become no longer associated with you when the user does a
/// variety of things.
/// - clear a delegate statement, maybe (seems obvious, but there could be an equivalent
///   that's claimed it.)
/// - clear a Oneofus key replace
/// - modify revokeAt for a replaced Oneofus key
/// - The user can also overwrite his private key by creating a new delegate key for a domain when
///   one already exists
/// Warnings that I can't promise to get right, and so I'll not even try:
/// - local delegate key becomes disassociated
/// Warnings that I can get right:
///  'You currently have a delegate key pair for $domain on this device. Overwrite it?'
/// - TODO: Warn at import keys
///  'This will overwrite all existing keys.'
///
/// So: Check invariant after any possible change and offer the user:
///   'You currently have a delegate key pair for $domain on this device, but it is not associated with you. Claim it or delete it?'
///

const String _descTop =
    '''Delegate keys allow other services to state stuff as you.
You can revoke these at any time (including retroactively).''';
const String _descVerbs = '''delegate: Claim this delegate key as yours (revoked or not).
clear: disassociate yourself from this key.''';
const Map<TrustVerb, String> _descVerb = {
  TrustVerb.delegate: '''domain: The partner service's domain name (eg. nerdster.org).
revokeAt: Choose among: <not revoked>, revoked <since always>, or revoked at a particular past statement.
comment: Optional note.''',
  TrustVerb.clear: '''No fields to fill out (you're erasing after all).''',
};

class DelegateKeysRoute extends StatelessWidget {
  static const RouteSpec spec = RouteSpec([TrustVerb.delegate], _descTop, _descVerbs, _descVerb);

  const DelegateKeysRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(formatVerbs(spec.verbs))),
        body: SafeArea(
            child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
              Linky(_descTop),
              kDivider,
              const StatementActionPicker(spec),
              kDivider,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton(
                    onPressed: () async {
                      await createNewDelegateKey(null, context);
                    },
                    child: const Text('Create new delegate key')),
                OutlinedButton(
                    onPressed: () async {
                      await claimDelegateKey(context);
                    },
                    child: const Text('Claim existing delegate key')),
              ]),
            ])));
  }
}

Future<TrustStatement?> createNewDelegateKey(String? domain, BuildContext context) async {
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
  TrustStatement? ts2 = await ModifyStatementRoute.show(ts, DelegateKeysRoute.spec, context);
  if (ts2 != null) {
    assert(ts2.domain!.length > 1);
    await MyKeys.storeDelegateKey(delegateKeyPair, ts2.domain!);
    assert(MyKeys.getDelegateToken(ts2.domain!) == getToken(delegatePublicKeyJson));
  }
  return ts2;
}

Future<TrustStatement?> claimDelegateKey(BuildContext context) async {
  String? scanned = await QrScanner.scan('Scan key', validateKey, context);
  if (b(scanned)) {
    Json subjectKeyJson = await parsePublicKey(scanned!);
    return await stateClaimDelegateKey(subjectKeyJson, context);
  }
  return null;
}

Future<TrustStatement?> stateClaimDelegateKey(Json subjectJson, BuildContext context,
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
    TrustStatement? statement = await ModifyStatementRoute.show(prototype, DelegateKeysRoute.spec, context);
    return statement;
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
            TrustStatement? statement = await stateClaimDelegateKey(publicKeyJson, domain: domain, context);
          }
        } else if (claimOdelete == 'Delete') {
          await MyKeys.deleteDelegateKey(domain);
        }
      }
    }
  }
}
