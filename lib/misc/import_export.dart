import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import '../base/my_keys.dart';
import '../oneofus/ok_cancel.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

class ImportExport extends StatefulWidget {
  const ImportExport({super.key});

  @override
  State<StatefulWidget> createState() => ImportExportState();
}

class ImportExportState extends State<ImportExport> {
  final TextEditingController controller = TextEditingController()
    ..text = _encoder.convert(MyKeys.export());

  ImportExportState();

  @override
  Widget build(BuildContext context) {
    VoidCallback? onPaste;
    if (controller.text != _encoder.convert(MyKeys.export())) {
      onPaste = () async {
        try {
          dynamic content = jsonDecode(controller.text);
          await MyKeys.import(content);
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
                  style: GoogleFonts.courierPrime(
                      fontSize: 14, color: Colors.black))),
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
                        await Clipboard.setData(
                            ClipboardData(text: controller.text));
                      }),
                  const SizedBox(width: 5),
                  OutlinedButton(
                      child: Row(
                        children: [
                          const Text('Paste'),
                          const SizedBox(width: 5),
                          const Icon(Icons.paste),
                        ],
                      ),
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
