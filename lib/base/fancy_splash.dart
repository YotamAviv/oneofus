import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/trusts_route.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'my_keys.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/util.dart';
import 'sign_in.dart';
import '../widgets/qr_scanner.dart';

class FancySplash extends StatelessWidget {
  const FancySplash({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.bottomRight, children: [
      const _KeyQrText(),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (kDev) FloatingActionButton(
              heroTag: 'Copy',
              tooltip: 'Copy',
              child: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: encoder.convert(MyKeys.oneofusPublicKey)));
              }),
          const Spacer(),
          FloatingActionButton(
              heroTag: 'QR sign-in',
              tooltip: 'QR sign-in',
              child: const Icon(Icons.login),
              onPressed: () async {
                String? scanned =
                await QrScanner.scan('Scan QR Sign-in', scannerSignInValidate, context);
                if (b(scanned)) {
                  await signIn(scanned!, context);
                }
              }),
          FloatingActionButton(
              heroTag: 'New Trust',
              tooltip: 'New Trust',
              child: const Icon(Icons.person_add),
              onPressed: () async {
                Json? jsonPublicKey = await QrScanner.scanPublicKey(context);
                if (!b(jsonPublicKey)) return;
                if (!context.mounted) return;
                Jsonish? jsonish = await startTrust(jsonPublicKey!, context);
              }),
        ],
      ),
    ]);
  }
}

class _KeyQrText extends StatefulWidget {
  const _KeyQrText({super.key});

  @override
  State<StatefulWidget> createState() => _KeyQrTextState();
}
class _KeyQrTextState extends State<_KeyQrText> {
  Json data = {};

  @override
  initState() {
    super.initState();
    MyKeys.publicExportNotifier.addListener(listener);
    listener();
  }

  @override
  void dispose() {
    MyKeys.publicExportNotifier.removeListener(listener);
    super.dispose();
  }

  void listener() async {
    setState(() {
      // (Keys.oneofusPublicKey has a questionable null check!)
      if (MyKeys.publicExportNotifier.value.isNotEmpty) {
        data = MyKeys.oneofusPublicKey;
      } else {
        data = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size availSize = MediaQuery.of(context).size;
    double size = min(availSize.width, availSize.height) * 0.75;
    String dataString = encoder.convert(data);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        QrImageView(
          data: dataString,
          version: QrVersions.auto,
          size: size,
        ),
        TextField(
            controller: TextEditingController()..text = dataString,
            maxLines: null,
            readOnly: true,
            style: GoogleFonts.courierPrime(
                fontWeight: FontWeight.w700, fontSize: 10, color: Colors.black)),
      ],
    );
  }
}
