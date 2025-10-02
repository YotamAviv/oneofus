import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../oneofus/util.dart';
import '../setting_type.dart';

class Setting<T> implements ValueListenable<T> {
  final SettingType type; // Enum for type-safe code references
  final ValueNotifier<T> _notifier;

  Setting._(this.type) : _notifier = ValueNotifier<T>(type.defaultValue);

  static Setting<T> get<T>(SettingType type) => _instances[type]! as Setting<T>;
  static final List<Setting> all = _instances.values.toList();

  String get name => type.name;
  ValueNotifier<T> get notifier => _notifier;
  List<String> get aliases => type.aliases;
  T get defaultValue => type.defaultValue;
  bool get persist => type.persist;
  bool get param => type.param;

  @override
  T get value => _notifier.value;

  set value(T newValue) => _notifier.value = newValue;

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _notifier.removeListener(listener);

  // Helper method to parse string values into type T
  T _parseValue(String value) {
    if (T == bool) return bs(value) as T;
    if (T == int) return int.parse(value) as T;
    if (T == String) return value as T;
    if (T == List<String>) return value.split(',') as T;
    throw Exception('Unsupported type: $T');
  }

  void updateFromQueryParam(Map<String, String> params) {
    if (!param) return;
    String? paramValue;
    if (b(params[name])) {
      paramValue = params[name];
    } else {
      for (String alias in aliases) {
        if (b(params[alias])) {
          paramValue = params[alias];
          break;
        }
      }
    }
    if (paramValue != null) _notifier.value = _parseValue(paramValue);
  }

  void addToParams(Map<String, String> params) {
    if (!param) return;
    if (_notifier.value != defaultValue) {
      if (T == List<String>) {
        params[name] = (_notifier.value as List<String>).join(',');
      } else {
        params[name] = _notifier.value.toString();
      }
    }
  }

  Future<void> loadFromStorage(FlutterSecureStorage storage) async {
    if (!persist) return;
    try {
      String? value = await storage.read(key: name);
      if (!b(value)) {
        for (String alias in aliases) {
          value = await storage.read(key: alias);
          if (b(value)) break;
        }
      }
      if (b(value)) {
        _notifier.value = _parseValue(value!);
      }
    } catch (e) {
      print(e);
    }
  }

  void addStorageListener(FlutterSecureStorage storage) {
    if (!persist) return;
    _notifier.addListener(() async {
      if (T == List<String>) {
        await storage.write(key: name, value: (_notifier.value as List<String>).join(','));
      } else {
        await storage.write(key: name, value: _notifier.value.toString());
      }
    });
  }

  // Cache for singleton Setting instances
  static final Map<SettingType, Setting> _instances = {
    for (var type in SettingType.values) type: _createSetting(type),
  };

  // Private factory method for creating instances
  static Setting _createSetting(SettingType type) {
    if (type.type == bool) {
      return Setting<bool>._(type);
    } else if (type.type == int) {
      return Setting<int>._(type);
    } else if (type.type == String) {
      return Setting<String>._(type);
    } else if (type.type == List<String>) {
      return Setting<List<String>>._(type);
    }
    throw Exception('Unauthorized type for SettingType: ${type.type}');
  }
}

class Prefs {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Map<Setting, dynamic> snapshot() {
    return {for (var setting in Setting.all) setting: setting.value};
  }

  static void restore(Map<Setting, dynamic> snapshot) {
    for (final entry in snapshot.entries) {
      entry.key.value = entry.value;
    }
  }

  static void restoreDefaultValues() {
    for (final setting in Setting.all) {
      setting.value = setting.defaultValue;
    }
  }

  static Future<void> init() async {
    await Future.wait(
      Setting.all
          .where((setting) => setting.persist)
          .map((setting) => setting.loadFromStorage(_storage)),
    );

    Map<String, String> params = Uri.base.queryParameters;
    for (final setting in Setting.all) {
      setting.updateFromQueryParam(params);
    }

    for (final setting in Setting.all.where((setting) => setting.persist)) {
      setting.addStorageListener(_storage);
    }
  }

  static void setParams(Map<String, String> params) {
    for (final setting in Setting.all) {
      setting.addToParams(params);
    }
  }

  Prefs._();
}
