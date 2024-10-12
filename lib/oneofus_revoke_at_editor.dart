import 'package:flutter/material.dart';
import 'package:oneofus/field_editor.dart';
import 'package:oneofus/modify_statement_route.dart';
import 'package:oneofus/pick_revoked_at_statement_route.dart';

import 'oneofus/jsonish.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/util.dart';

class OneofusRevokeAtEditor extends FieldEditor {
  final TrustStatement statement;
  final ValueNotifier<String> picked = ValueNotifier<String>('temp, null not allowed');

  OneofusRevokeAtEditor(this.statement, {super.key}) : super('revokeAt') {
    picked.value = statement.revokeAt!;
  }

  @override
  String? get value => picked.value;

  @override
  State<StatefulWidget> createState() => _RevokeAtEditorState();
}

class _RevokeAtEditorState extends State<OneofusRevokeAtEditor> {
  @override
  void initState() {
    super.initState();
    widget.errorState.value = !b(widget.picked.value);
    widget.picked.addListener(() {
      widget.errorState.value = !b(widget.picked.value);
    });
    widget.errorState.addListener(() {
      setState(() {});
    });
  }

  String timeDisplayFromRevokedAt(String revokedAt) {
    if (revokedAt == 'since always') {
      return 'since always';
    } else {
      Jsonish? jsonish = Jsonish.find(revokedAt);
      if (b(jsonish) && b(jsonish!.json['time'])) {
        try {
          DateTime time = parseIso(jsonish!.json['time']);
          return formatUiDatetime(time);
        } catch (e, stackTrace) {
          print(e);
        }
      }
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    Color color = widget.errorState.value ? Colors.red : Colors.black;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              labelText: 'revokeAt',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
              labelStyle: TextStyle(
                color: color,
              ),
            ),
            child: Row(children: [
              Flexible(
                  child: InkWell(
                      onTap: () async {
                        String? picked = await PickRevokeAtStatementRoute.pick(
                            widget.statement.subjectToken, context);
                        setState(() {
                          if (b(picked)) {
                            widget.picked.value = picked!;
                          }
                        });
                      },
                      child: Text(widget.picked.value,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.blueAccent, decoration: TextDecoration.underline)))),
              const Spacer(),
              Text('@${timeDisplayFromRevokedAt(widget.picked.value)}'),
            ])));
  }
}
