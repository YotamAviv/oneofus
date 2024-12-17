import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneofus/delegate_keys_route.dart';
import 'package:oneofus/base/menus.dart';

import 'my_keys.dart';
import '../fire/nerdster_fire.dart';
import '../oneofus/crypto/crypto.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/util.dart';

final FirebaseFirestore _nerdsterFire = NerdsterFire.nerdsterFirestore;

Future<bool> validateSignIn(String text) async {
  try {
    Json received = jsonDecode(text);
    String session = received['session']!;
    Json pkePublicKeyJson = received['publicKey']!;
  } catch (e) {
    print(e);
    return false;
  }
  return true;
}

Future<void> signIn(String text, BuildContext context) async {
  Json received = jsonDecode(text);
  print(received);
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
    delegateCleartext = encoder.convert(delegateKeyPairJson);
    String delegateCiphertext = await myPkeKeyPair.encrypt(delegateCleartext, webPkePublicKey);
    send['publicKey'] = await myPkePublicKey.json;
    send['delegateCiphertext'] = delegateCiphertext;
  }

  // TODO: HTTP POST instead.
  final sessionCollection = _nerdsterFire.collection('sessions').doc('doc').collection(session);
  await sessionCollection.doc('doc').set(send).then((doc) => print("inserted send"),
      // TODO: Handle in case asynch DB write succeeds or fails.
      onError: (e) => print("signIn error: $e"));

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
