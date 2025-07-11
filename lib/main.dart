import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:oneofus/base/about.dart';
import 'package:oneofus/fire/firebase_options.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/prefs.dart';

import 'base/base.dart';
import 'base/my_keys.dart';
import 'oneofus/fire_factory.dart';
import 'oneofus/trust_statement.dart';

enum FireChoice {
  fake,
  emulator,
  prod;
}

const FireChoice fireChoice = FireChoice.prod;
const int? slowPushMillis = null;
const bool exceptionWhenTryingToPush = false;
// TODO: also simulate slow fetch.

// TODO: Phone rotation, d'oh!
// Try: https://stackoverflow.com/questions/49418332/flutter-how-to-prevent-device-orientation-changes-and-force-portrait

class ErrorCorruptor implements Corruptor {
  @override
  void corrupt(String token, String error, String? details) =>
      throw ('Corrupt!: $token, $error, $details');
}
final Corruptor corruptor = ErrorCorruptor();

typedef TranslateFn = dynamic Function(dynamic);
TranslateFn? translateFn;

const domain2statementType = {
  kOneofusDomain: kOneofusType,
};

const Map<FireChoice, Map<String, (String, String)>> exportUrl = {
  FireChoice.prod: {
    kOneofusDomain: ('export.one-of-us.net', '')
  },
  FireChoice.emulator: {
    kOneofusDomain: ('127.0.0.1:5002', 'one-of-us-net/us-central1/export'),
  },
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (fireChoice != FireChoice.fake) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (fireChoice == FireChoice.emulator) {
      // $ firebase --project=one-of-us-net -config=oneofus-nerdster.firebase.json emulators:start
      // $ firebase --project=nerdster emulators:start
      // (Just using 192.168.1.97 for emulator didn't work for accessing emulator fromm real phone.)
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    }
    FireFactory.register(kOneofusDomain, FirebaseFirestore.instance, null);
  } else {
    FireFactory.register(kOneofusDomain, FakeFirebaseFirestore(), null);
  }

  await About.init();
  TrustStatement.init();
  await MyKeys.init();
  await Prefs.init();

  runApp(
    GlobalLoaderOverlay(
        child: const MaterialApp(
            debugShowCheckedModeBanner: false, title: 'ONE-OF-US.NET', home: Base())),
  );
}

var yotam = {"crv": "Ed25519", "kty": "OKP", "x": "Fenc6ziXKt69EWZY-5wPxbJNX9rk3CDRVSAEnA8kJVo"};
