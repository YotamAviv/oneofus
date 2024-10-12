import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oneofus/field_editor.dart';
import 'package:oneofus/oneofus/ui/lower_case_text_formatter.dart';
import 'package:oneofus/oneofus/util.dart';

class TextEditor extends FieldEditor {
  final TextEditingController controller = TextEditingController();

  final int? maxLines;
  final int? minLength;
  final bool? lowercase;

  @override
  String? get value => controller.text.isNotEmpty ? controller.text : null;

  TextEditor(
    super.field,
    String? value, {
    this.minLength,
    this.maxLines,
    this.lowercase,
    super.key,
  }) {
    controller.text = value ?? '';
  }

  @override
  State<StatefulWidget> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  _TextEditorState();

  @override
  void initState() {
    super.initState();
    if (b(widget.minLength)) {
      widget.errorState.value = widget.controller.text.length < widget.minLength!;
      widget.controller.addListener(() {
        widget.errorState.value = widget.controller.text.length < widget.minLength!;
      });
      widget.errorState.addListener(() {
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = widget.errorState.value ? Colors.red : Colors.black;
    List<TextInputFormatter>? inputFormatters =
        bb(widget.lowercase) ? [LowerCaseTextFormatter()] : null;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              labelText: widget.field,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
              labelStyle: TextStyle(
                color: color,
              ),
            ),
            child: TextField(
              style: TextStyle(color: color),
              controller: widget.controller,
              inputFormatters: inputFormatters,
              maxLines: widget.maxLines,
            )));
  }
}
