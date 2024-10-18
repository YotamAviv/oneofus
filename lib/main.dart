import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'base/my_keys.dart';
import 'oneofus/fire_factory.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/fire_util.dart';
import 'base/base.dart';
import 'fire/nerdster_fire.dart';
import 'package:flutter/material.dart';

enum FireChoice {
  fake,
  emulator,
  prod;
}

const FireChoice _fire = FireChoice.fake;
const int? slowPushMillis = 500;
const bool kDev = false;
const bool exceptionWhenTryingToPush = false;
// TODO: also simulate slow fetch.

const bool fireCheckRead = false;
const bool fireCheckWrite = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_fire != FireChoice.fake) {
    await oneofusFireInit();
    await nerdsterFireInit();
    if (_fire == FireChoice.emulator) {
      NerdsterFire.nerdsterFirestore.useFirestoreEmulator('localhost', 8080);
      // $ firebase --project=nerdster emulators:start
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
      // $ firebase --project=one-of-us-net -config=oneofus-nerdster.firebase.json emulators:start
    }
    FireFactory.registerFire(kOneofusDomain, FirebaseFirestore.instance);
    FireFactory.registerFire('nerdster.org', NerdsterFire.nerdsterFirestore);
  } else {
    FireFactory.registerFire(kOneofusDomain, FakeFirebaseFirestore());
    FireFactory.registerFire('nerdster.org', FakeFirebaseFirestore());
  }

  if (fireCheckWrite) {
    await checkWrite(
        'firecheck:ONE-OF-US-nerdster.org', FireFactory.find('nerdster.org'));
    await checkWrite(
        'firecheck:ONE-OF-US-one-of-us.net', FireFactory.find('one-of-us.net'));
  }
  if (fireCheckRead) {
    await checkRead(
        'firecheck:ONE-OF-US-nerdster.org', FireFactory.find('nerdster.org'));
    await checkRead(
        'firecheck:ONE-OF-US-one-of-us.net', FireFactory.find('one-of-us.net'));
  }

  TrustStatement.init();
  await MyKeys.init();

  runApp(
    const MaterialApp(
      title: 'ONE-OF-US.NET',
      home: Base(),
    ),
  );
}
