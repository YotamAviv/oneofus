import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oneofus/oneofus/util.dart';

class Prefs {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Persisted
  static ValueNotifier<bool> skipLgtm = ValueNotifier<bool>(false);

  // Never change, always false.
  // Only here because Fetcher expects it due to shared code with Nerdster.
  static ValueNotifier<bool> skipVerify = ValueNotifier<bool>(false);

  // Not persisted
  static ValueNotifier<bool> dev = ValueNotifier<bool>(false);
  static ValueNotifier<bool> cloudFunctionsFetch = ValueNotifier<bool>(false);
  static ValueNotifier<bool> batchFetch = ValueNotifier<bool>(false);
  static ValueNotifier<bool> fetchRecent = ValueNotifier<bool>(false);
  static ValueNotifier<bool> slowFetch = ValueNotifier<bool>(false);

  static Future<void> init() async {
    try {
      String? skipLgtmS = await _storage.read(key: 'skipLgtm');
      if (b(skipLgtmS)) {
        skipLgtm.value = bool.parse(skipLgtmS!);
      }
    } catch (e) {
      print (e);
    }

    Prefs.skipLgtm.addListener(listener);
  }

  static Future<void> listener() async {
    await _storage.write(key: 'skipLgtm', value: Prefs.skipLgtm.value.toString());
  }
}
