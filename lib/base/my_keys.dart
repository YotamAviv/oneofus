import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oneofus/oneofus/ui/alert.dart';

import '../oneofus/crypto/crypto.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/trust_statement.dart';
import '../oneofus/util.dart';

/// CONSIDER: Switch delegate storge key from domain to token
/// CONSIDER: Oneofus key changes? We'll still need to store the key you use as that's where it
/// all starts, and so only change if it simplifies.
/// Without change, we have {'one-of-us.org' : keyPair}
/// With change, we have {token: keyPair} and also {'one-of-us.org' : token}
/// It might make things simpler for identifying which keys are local (I have private key pair for)
/// PROS:
/// - less confusion?
/// - definitely less confusing regarding fire state / local state and delegate keys.
/// CONS:
/// - harder to export?
///   - okay to export as is.
///   - can change later.
///   - what's a user going to do with the export anyway?
/// - weak: my installation (I can deal) and Hille's (already messed up)
/// - wrong: requires Fire queries to sign in?
///   - service shows QR with 'domain'
///   - phone then has to look up current delegate for that - But I should have that all in MyStatements for delegate key interface

/// Equivalent Oneofus keys:
/// Show my replaced keys and offer
/// - Re-replace / completely revoke
/// - Claim a different, replaced key
/// Either requires picking the most recent valid statement signed by key.
/// This is hard to do if there are fraudulent, backdated entries;
/// Fetcher should crash or complain otherwise in case there backdated
/// statements. In case this happens, we can recommend to revoke the key entirely.

/// Delegate keys:
/// Creating delegate keys per org upon sign in attempt is not enough as
/// might want copy/paste sign in, and so need explicit create delegate key for org.
/// But also be able to get there with QR sign in attempt.
/// Per host
/// - revoke at statement
/// - block
/// - create new

/// TODO(5): Save last statement tokens for statements made on this device

class MyKeys {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Unfortunate: I started out with one storage model and then made this simpler, but goofed a bit.
  // kOneofusDomain is used both as the key to our only storage Map, and it's also the key
  // to the one-of-us.net key in that storage Map.

  // Rep invariant: _exportNotifier has all our key pairs and is exactly
  // what we have in secure storage.
  static final ValueNotifier<Json> _exportNotifier = ValueNotifier<Json>({});

  // This one contains public keys as opposed to key pairs.
  // Stuff listens to it for change notifications.
  // (Nothing reads it as far as I know.)
  static final ValueNotifier<Json> publicExportNotifier = ValueNotifier<Json>({});

  static Future<void> init() async {
    String? value = await _storage.read(key: kOneofusDomain);
    if (b(value)) {
      _exportNotifier.value = jsonDecode((await _storage.read(key: kOneofusDomain))!);
      await _private2public();
    }
  }

  // Store one-of-us key
  // This DO NOT state TrustVerb.delegate statement; that's done elsewhere.
  static Future<void> storeOneofusKey(OouKeyPair oneofusKeyPair) async {
    assert(!b(_contingentExportNotifier));
    Json oneofusKeyPairJson = await (oneofusKeyPair).json;
    _exportNotifier.value[kOneofusDomain] = oneofusKeyPairJson;
    await _private2public();
    await _write();
  }

  // Store a delegate key
  // This DO NOT state TrustVerb.delegate statement; that's done elsewhere.
  static Future<void> storeDelegateKey(OouKeyPair delegateKeyPair, String domain) async {
    assert(!b(_contingentExportNotifier));
    assert(domain != kOneofusDomain);
    if (b(getDelegateKeyPair(domain))) {
      print('warning: overwriting a delegate key for $domain');
    }
    Json delegateKeyPairJson = await delegateKeyPair.json;
    // Update our notifiers
    _exportNotifier.value[domain] = delegateKeyPairJson;
    await _private2public();
    // Persist to storage
    await _write();
  }

  // Deletes a delegate key
  static Future<void> deleteDelegateKey(String domain) async {
    assert(!b(_contingentExportNotifier));
    assert(domain != kOneofusDomain);
    // Update our notifiers
    _exportNotifier.value.remove(domain);
    await _private2public();
    // Persist to storage
    await _write();
  }

  static Future<void> _write() async {
    await _storage.write(key: kOneofusDomain, value: encoder.convert(_exportNotifier.value));
  }

  // ---- Contingent Oneofus KeyPair : used as we're replacing our own key. It's not transactional, but I'm trying...
  static ValueNotifier<Json>? _contingentExportNotifier;

  static Future<void> setContingentOneofus(OouKeyPair contingentOneofusKeyPair) async {
    Json contingentOneofusKeyPairJson = await contingentOneofusKeyPair.json;
    assert (!b(_contingentExportNotifier));
    _contingentExportNotifier = ValueNotifier<Json>({});
    Json x = Map<String, dynamic>.from(_exportNotifier.value);
    x[kOneofusDomain] = contingentOneofusKeyPairJson;
    _contingentExportNotifier!.value = x;
    await _private2public();
  }

  static Future<void> confirmContingentOneofus() async {
    assert (b(_contingentExportNotifier));
    _exportNotifier.value = _contingentExportNotifier!.value;
    _contingentExportNotifier = null;
    await _private2public();
    await _write();
  }
  static  Future<void> rejectContingentOneofus() async {
    _contingentExportNotifier = null;
    await _private2public();
  }

  static get _useExportNotifier => _contingentExportNotifier ?? _exportNotifier;

  // Convenience...
  static Json get oneofusKeyPair => _useExportNotifier.value[kOneofusDomain]!;

  static Json get oneofusPublicKey => publicExportNotifier.value[kOneofusDomain]!;

  static String get oneofusToken => Jsonish(oneofusPublicKey).token;

  static Json? getDelegateKeyPair(String host) => _useExportNotifier.value[host];

  static Json? getDelegatePublicKey(String host) => publicExportNotifier.value[host];

  static String? getDelegateToken(String host) {
    Json? delegatePublicKey = getDelegatePublicKey(host);
    return b(delegatePublicKey) ? Jsonish(delegatePublicKey!).token : null;
  }

  // delegate keys I have key pairs for in storage.
  static Iterable<String> getLocalDelegateKeys() =>
      publicExportNotifier.value.values.map((k) => Jsonish(k).token);

  static Json export() => _useExportNotifier.value;

  static Future<void> import(Json json) async {
    // validate input (should throw exception if input is bad)
    for (var keyJson in json.values) {
      await crypto.parseKeyPair(keyJson);
    }

    _useExportNotifier.value = json;
    await _private2public();
    await _write();
  }

  /// This forms publicExportNotifier from exportNotifier, but with public
  /// keys instead of key pairs.
  /// FancySplash (and maybe others) listens to changes on publicExportNotifier.
  static Future<void> _private2public() async {
    Json publicExport = {};
    for (MapEntry<String, dynamic> e in _useExportNotifier.value.entries) {
      String host = e.key;
      Json keyPairJson = e.value as Json;
      OouKeyPair keyPair = await crypto.parseKeyPair(keyPairJson);
      Json publicKeyJson = await (await keyPair.publicKey).json;
      publicExport[host] = publicKeyJson;
    }
    publicExportNotifier.value = publicExport;
  }

  MyKeys._();

  static Future<void> wipe(BuildContext context) async {
    String? okay = await alert('Wipe all data? Really?', '', ['Okay', 'Cancel'], context);
    if (b(okay) && okay! == 'Okay') {
      await _storage.deleteAll();
      _exportNotifier.value = {};
      publicExportNotifier.value = {};
    }
  }
}
