import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/oneofus/jsonish.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/util.dart';
import '../base/my_keys.dart';
import '../oneofus/ok_cancel.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

class ImportExport extends StatefulWidget {
  const ImportExport({super.key});

  @override
  State<StatefulWidget> createState() => ImportExportState();

  static Json internal2display(Json internal) => _swap(kOneofusDomain, kIdentity, internal);

  static Json display2internal(Json display) => _swap(kIdentity, kOneofusDomain, display);

  static Json _swap(String from, String to, Json json) {
    final Map<String, dynamic> result = {};
    // 1. Insert renamed key first
    if (json.containsKey(from)) result[to] = json[from];
    // 2. Insert the rest of the entries, skipping the renamed one
    json.forEach((key, value) {
      if (key != from) result[key] = value;
    });
    return result;
  }
}

const String kIdentity = 'identity';

class ImportExportState extends State<ImportExport> {
  final TextEditingController controller = TextEditingController()
    ..text = _encoder.convert(ImportExport.internal2display(MyKeys.export()));

  ImportExportState();

  @override
  Widget build(BuildContext context) {
    VoidCallback? onPaste;
    if (controller.text != _encoder.convert(ImportExport.internal2display(MyKeys.export()))) {
      onPaste = () async {
        try {
          Json content = jsonDecode(controller.text);
          // all values should be public/private key pairs
          content.forEach((key, value) async {
            await crypto.parseKeyPair(value);
          });
          await MyKeys.import(ImportExport.display2internal(content));
          await alert('New keys imported', '', ['Okay'], context);
          Navigator.pop(context);
        } catch (e) {
          await alertException(context, e);
        }
      };
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Import / Export')),
        body: Column(children: [
          Expanded(
              child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  readOnly: true,
                  style: GoogleFonts.courierPrime(fontSize: 14, color: Colors.black))),
          // ListView(shrinkWrap: true,
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                      child: Row(
                        children: [
                          const Text('Copy'),
                          const SizedBox(width: 5),
                          const Icon(Icons.copy),
                        ],
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: controller.text));
                      }),
                  const SizedBox(width: 5),
                  OutlinedButton(
                      child: Row(children: [
                        const Text('Paste'),
                        const SizedBox(width: 5),
                        const Icon(Icons.paste)
                      ]),
                      onPressed: () async {
                        ClipboardData? clipboardData =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        String? clipboardText = clipboardData!.text;
                        setState(() {
                          controller.text = clipboardText!;
                        });
                      }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CONSIDER: "Revert", "Done", "Back", "Cancel" and helpful enable/disable.
                  OutlinedButton(
                      onPressed: onPaste,
                      child: Row(
                        children: [
                          const Text('Import'),
                        ],
                      )),
                ],
              ),
            ],
          ),
        ]));
  }
}

var dummy = {
  "one-of-us.net": {
    "crv": "Ed25519",
    "d": "dS87_gD1ZQ1bzgFYz4DIsCNcdBpQlen1zs7hx32-Mi0",
    "kty": "OKP",
    "x": "3EacrkjWVwZQrPHRC1loK_zvwSn5uqh9NI4vMY62Wlc"
  },
  "aaa": {
    "crv": "Ed25519",
    "d": "vMpQkC8rpweklvmVbhqxYwWJb9mC40-XB2Jf6kVRiOg",
    "kty": "OKP",
    "x": "fq1GivyvIA_E5VE0XfZSr5PUdh0glWnJdklxU_wx1JY"
  },
  "bbb": {
    "crv": "Ed25519",
    "d": "xe0Yvveix_uMD_-bdVgwb_xssnG9L7Ndm_5v4h6071s",
    "kty": "OKP",
    "x": "YjZWA7NmmPoObhEUW0xrY965fX6VCj0ImftO1_Ku8eI"
  },
  "ccc": {
    "crv": "Ed25519",
    "d": "pUplOcZTaxqYwwYRO8G7vaboT4i9E53mJmMf4wGLcaU",
    "kty": "OKP",
    "x": "GLfqXm2enD992JkY8Fifgb2by5XoE74zdyZt9bgSuW4"
  }
};

var dummy2 = {
  "one-of-us.net": {
    "crv": "Ed25519",
    "d": "dS87_gD1ZQ1bzgFYz4DIsCNcdBpQlen1zs7hx32-Mi0",
    "kty": "OKP",
    "x": "3EacrkjWVwZQrPHRC1loK_zvwSn5uqh9NI4vMY62Wlc"
  },
  "aaa": {
    "crv": "Ed25519",
    "d": "vMpQkC8rpweklvmVbhqxYwWJb9mC40-XB2Jf6kVRiOg",
    "kty": "OKP",
    "x": "fq1GivyvIA_E5VE0XfZSr5PUdh0glWnJdklxU_wx1JY"
  }
};

var dummyMissingOneofus = {
  "aaa": {
    "crv": "Ed25519",
    "d": "vMpQkC8rpweklvmVbhqxYwWJb9mC40-XB2Jf6kVRiOg",
    "kty": "OKP",
    "x": "fq1GivyvIA_E5VE0XfZSr5PUdh0glWnJdklxU_wx1JY"
  },
  "bbb": {
    "crv": "Ed25519",
    "d": "xe0Yvveix_uMD_-bdVgwb_xssnG9L7Ndm_5v4h6071s",
    "kty": "OKP",
    "x": "YjZWA7NmmPoObhEUW0xrY965fX6VCj0ImftO1_Ku8eI"
  },
  "ccc": {
    "crv": "Ed25519",
    "d": "pUplOcZTaxqYwwYRO8G7vaboT4i9E53mJmMf4wGLcaU",
    "kty": "OKP",
    "x": "GLfqXm2enD992JkY8Fifgb2by5XoE74zdyZt9bgSuW4"
  }
};
