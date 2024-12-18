import 'package:flutter/cupertino.dart';

class Prefs {
  static ValueNotifier<bool> skipLgtm = ValueNotifier<bool>(false);
  static ValueNotifier<bool> skipVerify = ValueNotifier<bool>(false);
  static ValueNotifier<bool> dev = ValueNotifier<bool>(false);
}

