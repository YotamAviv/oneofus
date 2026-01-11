import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:oneofus/fire/firebase_options.dart';
import 'package:oneofus/oneofus/endpoint.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/prefs.dart';
import 'package:oneofus/v2/main_scaffold.dart';

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

const domain2statementType = {
  kOneofusDomain: kOneofusType,
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (fireChoice != FireChoice.fake) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (fireChoice == FireChoice.emulator) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    }
    FireFactory.register(kOneofusDomain, FirebaseFirestore.instance, null);
  } else {
    FireFactory.register(kOneofusDomain, FakeFirebaseFirestore(), null);
  }

  switch (fireChoice) {
    case FireChoice.fake:
      throw UnimplementedError();
    case FireChoice.emulator:
      Fetcher.initEndpoint(kOneofusDomain,
          const Endpoint('http', '127.0.0.1', 'one-of-us-net/us-central1/export', port: 5002));
    case FireChoice.prod:
      Fetcher.initEndpoint(kOneofusDomain, const Endpoint('https', 'export.one-of-us.net', ''));
  }

  TrustStatement.init();
  await MyKeys.init();
  await Prefs.init();

  runApp(
    GlobalLoaderOverlay(
        child: const MaterialApp(
      title: 'ONE-OF-US.NET',
      home: MainScaffold(), // Use the new v2 scaffold
    )),
  );
}
