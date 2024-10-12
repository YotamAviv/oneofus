import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'oneofus/jsonish.dart';

class ConfirmStatementRoute extends StatelessWidget {
  final Json json;
  const ConfirmStatementRoute(this.json, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Confirm Statement')),
        body: ListView(children: [
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
          OutlinedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: const Text('LGTM')),
        ]));
  }
}
