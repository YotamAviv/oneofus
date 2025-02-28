import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/delegate_keys_route.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/statement.dart';
import 'package:oneofus/oneofus/trust_statement.dart';

import '../oneofus/crypto/crypto.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/util.dart';
import 'my_keys.dart';

const Map<String, String> _headers = {
  'Content-Type': 'application/json; charset=UTF-8',
};

Future<bool> validateSignIn(String text) async {
  try {
    Json received = jsonDecode(text);
    return received.containsKey('method') &&
        received.containsKey('session') &&
        received.containsKey('publicKey');
  } catch (e) {
    return false;
  }
}

Future<void> signIn(String scanned, BuildContext context) async {
  Json received = jsonDecode(scanned);
  String session = received['session']!;
  String domain = received['domain']!;

  // Encrypt delegate key pair, include Oneofus public key for center
  Json pkePublicKeyJson = received['publicKey']!;
  PkePublicKey webPkePublicKey = await crypto.parsePkePublicKey(pkePublicKeyJson);
  PkeKeyPair myPkeKeyPair = await crypto.createPke();
  PkePublicKey myPkePublicKey = await myPkeKeyPair.publicKey;
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

  Map<String, dynamic> send = {
    'date': clock.nowIso, // time so that I can delete these at some point in the future.
    'one-of-us.net': MyKeys.oneofusPublicKey,
  };

  String? delegateCleartext;
  if (b(delegateKeyPairJson)) {
    send['publicKey'] = await myPkePublicKey.json;

    // Don't encrypt on iOS
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    delegateCleartext = encoder.convert(delegateKeyPairJson);
    if (isIOS) {
      send['delegateCleartext'] = delegateCleartext;
    } else {
      String delegateCiphertext = await myPkeKeyPair.encrypt(delegateCleartext, webPkePublicKey);
      send['delegateCiphertext'] = delegateCiphertext;
    }
  }

  assert(received['method'] == 'POST');
  send['session'] = session;
  Uri uri = Uri.parse(received['uri']);
  if (kFireChoice == FireChoice.emulator) {
    uri = uri.replace(port: 5001, host: '10.0.2.2', path: '/nerdster/us-central1/signin');
  }
  // Enforce that POST domain URI matches delegate domain.
  if (kFireChoice == FireChoice.prod) {
    List<String> ss = uri.host.split('.');
    String uriDomain = '${ss[ss.length - 2]}.${ss[ss.length - 1]}';
    if (uriDomain != domain) throw Exception('$uriDomain != $domain');
  }
  http.Response response = await http.post(uri, headers: _headers, body: jsonEncode(send));
  print('response.statusCode: ${response.statusCode}'); // (201 expected)

  Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
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

var sampleSignIn = {
  "domain": "nerdster.org",
  "publicKey": {
    "crv": "X25519",
    "kty": "OKP",
    "x": "vVGxbPqAwNpGUCuYio5c2WHVuG3rCeP2WaoIQtsIGxE"
  },
  "session": "05167cbeaa42acb5e680961648afd24ddf15a3ec",
  "method": "POST",
  "uri": "https://signin.nerdster.org/signin"
};