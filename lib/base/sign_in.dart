import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oneofus/base/fancy_splash.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/delegate_keys_route.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/ui/my_checkbox.dart';
import 'package:oneofus/prefs.dart';

import '../oneofus/crypto/crypto.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/util.dart';
import 'my_keys.dart';

const Map<String, String> _headers = {
  'Content-Type': 'application/json; charset=UTF-8',
};

/// See notes for V1/V2 "sign in parameters" in Nerdster project.
Future<bool> validateSignIn(String scanned) async {
  try {
    Json received = jsonDecode(scanned);
    return (received.containsKey('uri') || received.containsKey('url')) &&
        (received.containsKey('publicKey') || received.containsKey('encryptionPk')) &&
        received.containsKey('domain');
  } catch (e) {
    return false;
  }
}

Future<void> signIn(String scanned, BuildContext context) async {
  assert(await validateSignIn(scanned));
  final Json received = jsonDecode(scanned);
  final String urlKey = received.containsKey('url') ? 'url' : 'uri';
  final String encryptionPkKey =
      received.containsKey('encryptionPk') ? 'encryptionPk' : 'publicKey';

  final String domain = received['domain']!;

  // Encrypt delegate key pair, include Oneofus public key for center
  final Json pkePublicKeyJson = received[encryptionPkKey]!;
  final String session = getToken(pkePublicKeyJson);
  final PkePublicKey webPkePublicKey = await crypto.parsePkePublicKey(pkePublicKeyJson);
  final PkeKeyPair myPkeKeyPair = await crypto.createPke();
  final PkePublicKey myPkePublicKey = await myPkeKeyPair.publicKey;
  // Oneofus center without delegate 'sign in' should be allowed.
  Json? delegateKeyPairJson = MyKeys.getDelegateKeyPair(domain);
  if (!b(delegateKeyPairJson)) {
    bool create = (await createDelegateOrNot(domain, context))!;
    if (create) {
      TrustStatement? statement = await createNewDelegateKey(domain, context);
      if (b(statement)) {
        if (context.mounted) await prepareX(context); // redundant?
        delegateKeyPairJson = MyKeys.getDelegateKeyPair(domain);
      }
    }
  }

  final Map<String, dynamic> send = {
    'date': clock.nowIso, // time so that I can delete these at some point in the future.
    'identity': MyKeys.oneofusPublicKey,
    'session': session,
    'endpoint': Fetcher.getEndpoint(kOneofusDomain),
  };

  String? delegateCleartext;
  if (b(delegateKeyPairJson)) {
    send['ephemeralPK'] = await myPkePublicKey.json;

    // Do encrypt on iOS (was: Don't encrypt on iOS)
    // bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    delegateCleartext = encoder.convert(delegateKeyPairJson);
    // if (isIOS) {
    //   send['delegateCleartext'] = delegateCleartext;
    // } else {
    String delegateCiphertext = await myPkeKeyPair.encrypt(delegateCleartext, webPkePublicKey);
    send['delegateCiphertext'] = delegateCiphertext;
    // }
  }

  Uri uri = Uri.parse(received[urlKey]);
  if (fireChoice == FireChoice.emulator) {
    // 10.0.2.2 is a magic alias inside the Android Emulator that maps to 127.0.0.1 (localhost) on your development machine.
    // This is not the right check (checks if fire is emulator, not if Android is, fire emulator is the only time we use 127.0.0.1)
    uri = uri.replace(host: '10.0.2.2');
  }
  // print('uri=$uri');

  // Enforce that POST domain URI matches delegate domain.
  if (fireChoice == FireChoice.prod) {
    List<String> ss = uri.host.split('.');
    String uriDomain = '${ss[ss.length - 2]}.${ss[ss.length - 1]}';
    if (uriDomain != domain) throw Exception('$uriDomain != $domain');
  }
  http.Response response = await http.post(uri, headers: _headers, body: jsonEncode(send));
  // print('response.statusCode: ${response.statusCode}'); // (201 expected)

  Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));

  List<String> credentialTypes = ['- identity public key'];
  if (b(delegateKeyPairJson)) credentialTypes.add(('delegate public/private key pair'));

  keyFancyAnimation.currentState?.throwQr();

  if (!Prefs.skipCredentialsSent.value) {
    await alert(
        'Sent to $domain',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\n${credentialTypes.join('\n- ')}'),
            MyCheckbox(Prefs.skipCredentialsSent, "Don't show again")
          ],
        ),
        ['Okay'],
        context);
  }
}

Future<bool?> createDelegateOrNot(String domain, BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Create Delegate Key or Not?'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            readOnly: true,
            maxLines: null,
            controller: TextEditingController()
              ..text = '''
You're being asked to sign in using a delegate key for domain: $domain.
You don't have a delegate key for $domain. In case you do, back out and import it.
In case you don't, you can continue by:
- creating a delegate key for use on $domain, or
- signing in using as yourself (your one-of-us.net identity) but without write permissions at $domain.
''',
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Create Delegate Key',
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          TextButton(
            child: const Text(
              'Continue without',
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      );
    },
  );
}

/// chatGPT regarding encryption on iOS:
/// With your use of standard end-to-end encryption, the combo is:
// Info.plist
// <key>ITSAppUsesNonExemptEncryption</key>
// <false/>
// App Store Connect → Export Compliance
// “Does your app use encryption?” → Yes
// “Is your use exempt?” → Yes (standard consumer encryption)
//
// That’s it. You do not need extra export filings for typical client→server crypto (HTTPS/TLS, standard public-key, CryptoKit/Security, etc.).
