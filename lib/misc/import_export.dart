import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import '../base/my_keys.dart';
import '../oneofus/ok_cancel.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

class Export extends StatelessWidget {
  final dynamic content;
  const Export(this.content, {super.key});
  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();
    final String text = _encoder.convert(content);
    return Scaffold(
        appBar: AppBar(title: const Text('Export')),
        body: Stack(alignment: Alignment.bottomRight, children: [
          Scrollbar(
              controller: scrollController,
              child: TextField(
                  scrollController: scrollController,
                  controller: TextEditingController()..text = text,
                  maxLines: 15,
                  readOnly: true,
                  style: GoogleFonts.courierPrime(fontSize: 14, color: Colors.black))),
          FloatingActionButton(
              heroTag: 'Copy',
              tooltip: 'Copy',
              child: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
              })
        ]));
  }
}

class Import extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  Import({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Import')),
        body: Scrollbar(
          child: Column(children: [
            Stack(alignment: Alignment.bottomRight, children: [
              TextField(
                  controller: controller,
                  maxLines: 15,
                  style: GoogleFonts.courierPrime(fontSize: 14, color: Colors.black)),
              IconButton(
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    String? clipboardText = clipboardData?.text;
                    print('clipboardText=$clipboardText');
                    controller.text = clipboardText!;
                  },
                  icon: const Icon(Icons.paste, color: Colors.black))
            ]),
            const Spacer(flex: 5),
            OkCancel(() {
              try {
                dynamic content = jsonDecode(controller.text);
                MyKeys.import(content);
                Navigator.pop(context);
              } catch(e) {
                alertException(context, e);
              }
            }, 'Import'),
          ]),
        ));
  }
}
