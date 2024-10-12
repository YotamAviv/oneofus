import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oneofus/field_editor.dart';
import 'package:oneofus/oneofus/crypto/crypto.dart';
import 'package:oneofus/widgets/qr_scanner.dart';

import 'oneofus/jsonish.dart';
import 'oneofus/trust_statement.dart';
import 'oneofus/util.dart';

/// A delegate key revokeAt is the token of a statement signed by
/// the delegate key at a different service than ours (different domain, who knows..)
/// As we revoke this token, we could scan a Nerdster statement and
/// - get the time from that statement
/// - verify that it is signed by this key
/// But later when we list revoked delegate keys, we won't know the time;
/// we'll only know the token.

class DelegateRevokeAtEditor extends FieldEditor {
  final TrustStatement statement;
  final ValueNotifier<String?> pickedToken = ValueNotifier<String?>(null);

  DelegateRevokeAtEditor(this.statement, {super.key}) : super('revokeAt') {
    if (b(statement.revokeAt)) {
      pickedToken.value = statement.revokeAt!;
    }
  }

  @override
  String? get value => pickedToken.value;

  @override
  State<StatefulWidget> createState() => _DelegateRevokeAtEditorState();
}

class _DelegateRevokeAtEditorState extends State<DelegateRevokeAtEditor> {
  @override
  Widget build(BuildContext context) {
    String revokedAt;
    List<Widget> widgets = <Widget>[];
    if (b(widget.pickedToken.value)) {
      revokedAt = widget.pickedToken.value!;
      widgets.add(InkWell(
          onTap: () {
            widget.pickedToken.value = null;
            setState(() {});
          },
          child: const Text('[Clear]',
              style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline))));
    } else {
      revokedAt = '<not revoked>';
      widgets.add(InkWell(
          onTap: () async {
            await _scanDelegateRevokedAt(context);
          },
          child: const Text('[Scan]',
              style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline))));
      widgets.add(const Text(' '));
      widgets.add(InkWell(
          onTap: () {
            widget.pickedToken.value = 'since always';
            setState(() {});
          },
          child: const Text('"since always"',
              style: TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline))));
    }

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              labelText: 'revokeAt',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
            ),
            child: Row(children: [
              Flexible(
                child: Text(overflow: TextOverflow.ellipsis, revokedAt),
              ),
              const Spacer(),
              ...widgets,
            ])));
  }

  Future<void> _scanDelegateRevokedAt(BuildContext context) async {
    String? scanned = await QrScanner.scan('Scan statement QR', _validateDelegateRevokedAt, context,
        text: 'Scan a statement JSON or statement token QR code from the delegate service.');
    if (b(scanned)) {
      String? token = tryDecodeHex(scanned!);
      if (b(token)) {
        widget.pickedToken.value = token!;
      } else {
        String? token = await tryDecodeStatement(scanned!);
        widget.pickedToken.value = token!;
      }
      setState(() {});
    }
  }

  String? tryDecodeHex(String scanned) {
    try {
      if (scanned.length > 30 && scanned.length < 50) {
        RegExp hexadecimal = RegExp(r'^[0-9a-fA-F]+$');
        if (b(hexadecimal.stringMatch(scanned))) {
          return scanned;
        }
      }
    } catch (e) {
      print(e);
      print('scannerDelegateStatementValidate($scanned) returning: false');
    }
    return null;
  }

  Future<String?> tryDecodeStatement(String scanned) async {
    try {
      Json statementJson = jsonDecode(scanned);
      Json iKey = statementJson['I']!;
      OouPublicKey iPublicKey = await crypto.parsePublicKey(iKey);
      return Jsonish(statementJson).token;
    } catch (e) {
      print(e);
      print('scannerDelegateStatementValidate($scanned) returning: false');
    }
    return null;
  }

  Future<bool> _validateDelegateRevokedAt(String scanned) async {
    return b(tryDecodeHex(scanned)) || b(await tryDecodeStatement(scanned));
  }
}
