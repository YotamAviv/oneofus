import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:oneofus/oneofus/jsonish.dart';

import '../oneofus/util.dart';

class QrScanner extends StatefulWidget {
  final String title;
  final String? text;
  final Future<bool> Function(String) validator;

  const QrScanner(this.title, this.validator, {super.key, this.text});

  @override
  State<QrScanner> createState() => _QrScannerState();

  static Future<String?> scan(
      String title, Future<bool> Function(String) validator, BuildContext context,
      {String? text}) async {
    String? scanned = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => QrScanner(
                title,
                validator,
                text: text,
              )),
    );
    return scanned;
  }

  static Future<Json?> scanPublicKey(BuildContext context) async {
    String? string = await QrScanner.scan('Scan a public key QR Code', validatePublicKeyJson, context);
    if (b(string)) {
      if (!context.mounted) return null;
      Json json = await parsePublicKey(string!);
      return json;
    }
    return null;
  }
}

class _QrScannerState extends State<QrScanner> {
  Barcode? barcode;
  bool handled = false;

  void handleBarcode(BarcodeCapture barcodes) async {
    if (mounted) {
      barcode = barcodes.barcodes.firstOrNull;
      String? scanned = barcode!.rawValue;
      if (b(barcode) && b(scanned) && !handled) {
        bool valid = await widget.validator(scanned!);
        if (valid) {
          handled = true;
          // History included calling Navigator.pop here, which was problematic,
          // Kudos: https://stackoverflow.com/questions/55618717/error-thrown-on-navigator-pop-until-debuglocked-is-not-true
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(scanned);
          });
        }
      }
      setState(() {});
    }
  }

  void handlePaste() async {
    if (mounted) {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      String? clipboardText = clipboardData?.text;
      print('clipboardText=$clipboardText');
      if (b(clipboardText) && !handled) {
        bool valid = await widget.validator(clipboardText!);
        if (valid) {
          handled = true;
          Navigator.of(context).pop(clipboardText);
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEFER: Revisit this. I copy/pated this from an example, and this
    // seems to where I should display info about stuff that didn't pass validate.
    String barcodeDisplay;
    if (barcode == null) {
      barcodeDisplay = 'Scan QR...';
    } else if (barcode!.displayValue == null) {
      barcodeDisplay = 'No value.';
    } else {
      barcodeDisplay = barcode!.displayValue!;
    }

    const textStyle = TextStyle(color: Colors.white);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: handleBarcode,
          ),
          if (b(widget.text))
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                alignment: Alignment.topCenter,
                height: 100,
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Center(child: Text(style: textStyle, widget.text!)),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Center(
                        child: Text(
                      barcodeDisplay,
                      overflow: TextOverflow.fade,
                      style: textStyle,
                    )),
                  ),
                  const Spacer(),
                  const Text(
                    'Or paste',
                    style: textStyle,
                  ),
                  IconButton(
                      onPressed: () {
                        handlePaste();
                      },
                      icon: const Icon(Icons.paste, color: Colors.white))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> validatePublicKeyJson(String string) async {
  try {
    Json publicKeyJson = jsonDecode(string);
    await crypto.parsePublicKey(publicKeyJson);
    return true;
  } catch (e) {
    print('scannerJsonValidate($string) returning: false');
    return false;
  }
}

