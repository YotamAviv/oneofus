import 'package:flutter/cupertino.dart';

abstract class FieldEditor extends StatefulWidget {
  final String field;
  final ValueNotifier<bool> errorState = ValueNotifier<bool>(false);

  FieldEditor(this.field, {super.key});

  String? get value;
}
