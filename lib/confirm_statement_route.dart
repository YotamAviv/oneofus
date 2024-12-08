import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/oneofus/ui/my_checkbox.dart';
import 'package:oneofus/prefs.dart';

import 'oneofus/jsonish.dart';

class ConfirmStatementRoute extends StatelessWidget {
  final Json json;
  const ConfirmStatementRoute(this.json, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Confirm Statement')),
        body: ListView(children: [
          Linky('''For your review: This app intends to:
- Sign the statemet below using your one-of-us key
- Publish it at: https://export.one-of-us.net/?token=${MyKeys.oneofusToken}'''),
          TextField(
            enabled: false,
            style: GoogleFonts.courierPrime(
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontSize: 14,
            ),
            controller: TextEditingController()..text = Jsonish.encoder.convert(json),
            maxLines: null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 2),
              OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Looks good')),
              const SizedBox(width: 2),
              MyCheckbox(Prefs.skipLgtm, '''Don't show again'''),
              const SizedBox(width: 2),
            ],
          )
        ]));
  }
}
