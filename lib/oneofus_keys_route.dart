import 'package:flutter/material.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/statement.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/widgets/demo_statement_route.dart';

import 'base/my_keys.dart';
import 'modify_statement_route.dart';
import 'oneofus/jsonish.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/ui/alert.dart';
import 'oneofus/util.dart';
import 'statement_action_picker.dart';
import 'widgets/qr_scanner.dart';

const String _descTop =
    '''This app holds your active one-of-us public/private key pair and uses it to sign statements.
Stuff happens (lost phones, compromised keys, apps reinstalled, ...), and sometimes replacement keys are needed.
But individuals should maintain their singular identities, and {replace} statements facilitate this (as in, "This new key replaces my lost key").''';
const String _descVerbs = '''replace: Claim this key as a former identity (one-of-us) key of yours.
clear: disassociate yourself from this key.''';
const Map<TrustVerb, String> _descVerb = {
  TrustVerb.replace: '''revokeAt: Pick the last valid statement you made using this key.
comment: A note (probably to yourself) about this key and why your replacing it.''',
  TrustVerb.clear: '''No fields to fill out (you're erasing after all).''',
};

class OneofusKeysRoute extends StatelessWidget {
  static const RouteSpec spec = RouteSpec([TrustVerb.replace], _descTop, _descVerbs, _descVerb);

  const OneofusKeysRoute({super.key});

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
                      String? okay = await alert(
                          'Be sure',
                          '''In case you've re-installed the app, lost track of key, or something else, it's good to claim any past keys that you've used so that they are associated with your current one-of-us key.

But do make sure that you don't accidentally claim somebody else's key (that's the type of act that will get you blocked).

https://manual#replace''',
                          ['Okay', 'Cancel'],
                          context);
                      if (match(okay, 'Okay')) {
                        if (context.mounted) await claimKey(context);
                      }
                    },
                    child: const Text('Claim existing one-of-us key')),
                OutlinedButton(
                    onPressed: () async {
                      TrustStatement? statement;
                      if (context.mounted) statement = await replaceMyKey(context);
                    },
                    child: const Text('Replace my current one-of-us key')),
              ]),
            ])));
  }
}

Future<TrustStatement?> claimKey(BuildContext context) async {
  String? scanned = await QrScanner.scan('public key QR code to replace', validateKey, context);
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
Future<TrustStatement?> replaceMyKey(BuildContext context) async {
  try {
    Json current = MyKeys.oneofusPublicKey;
    await MyKeys.setContingentOneofus(await crypto.createKeyPair());
    if (context.mounted) {
      TrustStatement? statement = await stateReplaceKey(current, context);
      if (b(statement)) {
        await MyKeys.confirmContingentOneofus();
      }
      return statement;
    }
  } catch (e) {
    // TODO: Check if this catch is necessary. Should probably have one higher up the stack.
    if (context.mounted) await alertException(context, e);
  } finally {
    await MyKeys.rejectContingentOneofus();
  }
  return null;
}

Future<TrustStatement?> stateReplaceKey(Json subjectJson, BuildContext context) async {
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
https://manual#replace''',
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
https://manual#replace''',
          ['Okay', 'Cancel'],
          context);
      if (!match(okay, 'Okay')) {
        return null;
      }
      // Revoke at the most recent statement made by that key. (Most recent is first not last.)
      revokeAt = allStatementsNoDistinctNoVerify.first.token;
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
    TrustStatement? statement = await ModifyStatementRoute.show(prototype, OneofusKeysRoute.spec, context,
        subjectKeyDemo: myEquivalentKey);
    return statement;
  } catch (e, stackTrace) {
    if (context.mounted) {
      await alertException(context, e, stackTrace: stackTrace);
    }
    return null;
  }
}
