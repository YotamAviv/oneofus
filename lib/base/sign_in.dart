import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/delegate_keys_route.dart';
import 'package:oneofus/main.dart';

import '../fire/nerdster_fire.dart';
import '../oneofus/crypto/crypto.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/util.dart';
import 'my_keys.dart';

// TODO: Eliminate Nerdster fire. Sign in using HTTP POST only.
final FirebaseFirestore _nerdsterFire = NerdsterFire.nerdsterFirestore;

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
      Jsonish? jsonish = await createNewDelegateKey(domain, context);
      if (b(jsonish)) {
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

  if (received['method'] == 'Firestore') {
    final sessionCollection = _nerdsterFire.collection('sessions').doc('doc').collection(session);
    await sessionCollection.doc('doc').set(send);
  } else {
    assert(received['method'] == 'POST');
    send['session'] = session;
    Uri uri = Uri.parse(received['uri']);
    if (kFireChoice == FireChoice.emulator) {
      uri = uri.replace(port: 5001, host: '10.0.2.2', path: '/nerdster/us-central1/signin');
    }
    // DEFER: Enforce that POST domain URI matches delegate domain.
    // As we're POSTing to cloudfunctions.net, we'd have to forward something from our domain to
    // pass this check.
    print('uri=$uri');
    print('send=$send');
    http.Response response = await http.post(uri, headers: _headers, body: jsonEncode(send));
    print('response.statusCode: ${response.statusCode}'); // (201 expected)
  }

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
