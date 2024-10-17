import 'package:flutter/material.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/trusts_route.dart';
import 'package:oneofus/widgets/demo_statement_route.dart';

import 'base/my_keys.dart';
import 'modify_statement_route.dart';
import 'oneofus/jsonish.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/ui/alert.dart';
import 'oneofus/util.dart';
import 'statement_action_picker.dart';
import 'widgets/qr_scanner.dart';

// TODO(2): Show the statements with different colors for shadowed and conflicting blocks.

String _descTop0 = '''This app has your one-of-us public/private key pair and uses it to sign structured statements (like trust in others, for example).
Similarly, others may use their apps and keys to sign statements referencing your public key, which represents your identity.
Stuff happens (lost phone, compromised keys, apps reinstalled, ...), and so sometimes new keys are needed, but people should maintain their singular identities.
This is facilitated by "replace" statements (ie, my new key replaces my lost key, but I'm still the same person).''';

 String _descBottom = '''- Choose "Claim existing .." if you have used a one-of-us key before, but it's not the one on this device.
 - Choose "Replace.." if you suspect that the key on this device has been compromised.''';

class OneofusKeysRoute extends StatelessWidget {
  static const Set<TrustVerb> verbs = {TrustVerb.replace};

  const OneofusKeysRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('${formatVerbs(verbs)} Statements')),
        body: SafeArea(
            child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
              Linky(_descTop0),
              const StatementActionPicker(verbs),
              Linky(_descBottom),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                OutlinedButton(
                    onPressed: () async {
                      String? okay = await alert(
                          'Be sure',
                          '''In case you've re-installed the app, lost track of key, or something else, it's good to claim any past keys that you've used so that they are associated with your current one-of-us key.

But do make sure that you don't accidentally claim somebody else's key (that's the type of act that will get you blocked).

https://RTFM#claim-oneofus-key''',
                          ['Okay', 'Cancel'],
                          context);
                      if (match(okay, 'Okay')) {
                        if (context.mounted) await claimKey(context);
                      }
                    },
                    child: const Text('Claim existing one-of-us key')),
                OutlinedButton(
                    onPressed: () async {
                      Jsonish? jsonish;
                      if (context.mounted) jsonish = await replaceMyKey(context);
                    },
                    child: const Text('Replace my current one-of-us key')),
              ]),
            ])));
  }
}

Future<Jsonish?> claimKey(BuildContext context) async {
  String? scanned =
      await QrScanner.scan('public key QR code to replace', validatePublicKeyJson, context);
  if (b(scanned)) {
    Json subjectKeyJson = await parsePublicKey(scanned!);
    // NOTE: The check for context.mounted (see below) breaks things.
    // if (context.mounted) return await stateReplaceKey(subjectKeyJson, context);
    //
    return await stateReplaceKey(subjectKeyJson, context);
  }
  return null;
}

/// - Replacing a key that he's never used is fine. It may be the case that someone was
///   trusted, is new to this, maybe lost or compromised his private key before ever using it, ..
/// - revokeAt: anything other than a statement token made by this key> should make this key
///   just blocked.
///
/// This code is not transactional (update Key storage and Fire statements), but it's trying..
/// 1) alert the user: cancel/continue
/// 2) do it
///   - create new key but don't persist it; use Keys.xxxContingentOneofus.
///   - create statement replacing at time of last statement
///   - let the user edit that statement
///   - after LGTM
///     - state statement
///     - persist new key
///
/// Delegate keys:
/// - Offer the user a choice? 'Claim local delegate keys' or 'Lose local delegate key pairs'
/// - Claiming a delegate key involves issuing a statement, and we usually let the user edit and
/// LGTM those. Might be nice to do the same here. But I won't; it's too complicated and will
/// confuse the user. Instead:
/// TODO: Warn the user when he clears an 'replace' statement that he's going to abandon keys.
Future<Jsonish?> replaceMyKey(BuildContext context) async {
  try {
    Json current = MyKeys.oneofusPublicKey;
    await MyKeys.setContingentOneofus(await crypto.createKeyPair());
    if (context.mounted) {
      Jsonish? jsonish = await stateReplaceKey(current, context);
      if (b(jsonish)) {
        await MyKeys.confirmContingentOneofus();
      }
      return jsonish;
    }
  } catch (e) {
    // TODO: Check if this catch is necessary. Should probably have one higher up the stack.
    if (context.mounted) await alertException(context, e);
  } finally {
    await MyKeys.rejectContingentOneofus();
  }
  return null;
}

Future<Jsonish?> stateReplaceKey(Json subjectJson, BuildContext context) async {
  try {
    String subjectToken = getToken(subjectJson);

    // Checks
    if (subjectToken == MyKeys.oneofusToken) {
      await alert(
          '''That's you''',
          '''Use the "Replace my Key" button to replace your own key instead.''',
          ['Okay'],
          context);
      return null;
    }
    Iterable<TrustStatement> mine = MyStatements.getBySubject(subjectToken);
    if (mine.isNotEmpty) {
      TrustStatement ts = mine.first;
      switch (ts.verb) {
        case TrustVerb.trust:
          await alert(
              'That appears to be the trust key held by "${ts.moniker}".', '', ['Okay'], context);
          return null;
        case TrustVerb.block:
          await alert("You've blocked this key.", 'comment: ${ts.comment}', ['Okay'], context);
          return null;
        case TrustVerb.replace:
          await alert(
              'This is one of your equivalent keys.', 'comment: ${ts.comment}', ['Okay'], context);
          return null;
        case TrustVerb.delegate:
          await alert(
              'This is one of your delegate keys.', 'domain: ${ts.domain}', ['Okay'], context);
          return null;
        default:
          throw Exception('Unexpected');
      }
    }

    Iterable<TrustStatement> allStatementsNoDistinctNoVerify =
        (await Fetcher(subjectToken, kOneofusDomain).fetchAllNoVerify()).cast<TrustStatement>();
    String revokeAt;
    if (allStatementsNoDistinctNoVerify.isEmpty) {
      String? okay = await alert(
          'Replacing an unused key',
          '''No statements made by your current one-of-us key were found,  
and so it will be revoked since always rather than revoked at a particular, last valid statement.
https://RTFM#replace-oneofus-key.''',
          ['Okay', 'Cancel'],
          context);
      if (!match(okay, 'Okay')) {
        return null;
      }
      revokeAt = 'since always';
    } else {
      String? okay = await alert(
          'Replacing (and revoking) a key',
          '''This key will be replaced and revoked as of the last statement made by it, but you can change that value so that it will be revoked even earlier, at a particular last valid statement.
https://RTFM#replace-oneofus-key.''',
          ['Okay', 'Cancel'],
          context);
      if (!match(okay, 'Okay')) {
        return null;
      }
      // Revoke at the most recent statement made by that key
      String token = getToken(subjectJson);
      revokeAt = allStatementsNoDistinctNoVerify.last.token;
    }

    Json prototypeJson = {
      "statement": kOneofusDomain,
      "time": clock.nowIso,
      "I": MyKeys.oneofusPublicKey,
      TrustVerb.replace.label: subjectJson,
      "with": {"revokeAt": revokeAt}
    };
    TrustStatement prototype = TrustStatement(Jsonish(prototypeJson));

    assert(prototype.subjectToken == subjectToken);
    Jsonish? jsonish = await ModifyStatementRoute.show(
        prototype, [TrustVerb.replace], true, context,
        subjectKeyDemo: myEquivalentKey);
    return jsonish;
  } catch (e, stackTrace) {
    if (context.mounted) {
      await alertException(context, e, stackTrace: stackTrace);
    }
    return null;
  }
}
