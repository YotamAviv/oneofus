import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/oneofus/fire_factory.dart';
import 'package:oneofus/oneofus/jsonish.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:path_provider/path_provider.dart';

/// - open 'Device Explorer'
/// - find path /data/user/0/net.oneofus.app/app_flutter/
/// - right click to copy to computer (maybe to ~/nerdster-data)
/// - backup:
///   tar -czf ~/backups/nerdster-data.`date2`.tgz nerdster-data
///
/// DEFER: Save from both Oneofus and Nerdster
/// DEFER: Bring in NerdBase and backup entire network.

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
const kNerdsterDomain = 'nerdster.org';

Future<void> backup() async {
  print(kOneofusDomain);
  for (String t in [MyKeys.oneofusToken, ...MyStatements.equivalentKeys]) {
    await Backup.backup(FireFactory.find(kOneofusDomain), t);
  }

  print(kNerdsterDomain);
  Iterable<TrustStatement> delegateStatements = MyStatements.getByVerbs({TrustVerb.delegate});
  Iterable<TrustStatement> nerdsterDelegateStatements =
      delegateStatements.where((s) => s.domain == 'nerdster.org');
  Iterable<String> myNerdsterDelegateKeys = nerdsterDelegateStatements.map((s) => s.subjectToken);
  for (String t in myNerdsterDelegateKeys) {
    await Backup.backup(FireFactory.find(kNerdsterDomain), t);
  }
  print('done');
}

class Backup {
  static backup(FirebaseFirestore fire, String token) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory directory = await Directory('${appDocDir.path}/$token').create();

    final fireStatements = fire.collection(token).doc('statements').collection('statements');
    QuerySnapshot<Map<String, dynamic>> snapshots = await fireStatements
        .orderBy('time', descending: true)
        .get()
        .catchError((e) => print("Error completing: $e"));
    print('token=$token, snapshots.docs.length=${snapshots.docs.length}');
    for (var docSnapshot in snapshots.docs) {
      String id = docSnapshot.id;
      File file = File('${directory.path}/$id');
      Json data = docSnapshot.data();
      String string = _encoder.convert(data);
      await file.writeAsString(string);
      // print(string);
      print('wrote $file');
    }
  }
}
