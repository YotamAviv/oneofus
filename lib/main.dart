import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:oneofus/fire/nerdster_fire.dart';

import 'base/base.dart';
import 'base/my_keys.dart';
import 'oneofus/fire_factory.dart';
import 'oneofus/trust_statement.dart';

enum FireChoice {
  fake,
  emulator,
  prod;
}

const FireChoice _fire = FireChoice.prod;
const int? slowPushMillis = null;
const bool kDev = false;
const bool exceptionWhenTryingToPush = false;
// TODO: also simulate slow fetch.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_fire != FireChoice.fake) {
    await oneofusFireInit();
    await nerdsterFireInit();
    if (_fire == FireChoice.emulator) {
      NerdsterFire.nerdsterFirestore.useFirestoreEmulator('localhost', 8080);
      // (Just using 192.168.1.97 for emulator didn't work.)
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

  TrustStatement.init();
  await MyKeys.init();

  runApp(
    GlobalLoaderOverlay(child: const MaterialApp(title: 'ONE-OF-US.NET', home: const Base())),
  );
}
