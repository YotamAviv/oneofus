import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/prefs.dart';
import 'package:oneofus/trusts_route.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../oneofus/jsonish.dart';
import '../oneofus/util.dart';
import '../widgets/qr_scanner.dart';
import 'my_keys.dart';
import 'sign_in.dart';

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
          if (Prefs.dev.value)
            FloatingActionButton(
                heroTag: 'Copy',
                tooltip: 'Copy',
                child: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(
                      text: encoder.convert(MyKeys.oneofusPublicKey)));
                }),
          if (Prefs.dev.value) const SizedBox(width: 8),
          const Spacer(),
          FloatingActionButton(
              tooltip: '''Scan someone's key QR to trust or a delegate site's QR to sign-in''',
              child: const Icon(Icons.qr_code_2),
              onPressed: () async {
                String? scanned = await QrScanner.scan(
                    'Scan key QR to trust or Delegate QR sign-in', validateKeyOrSignIn, context);
                if (b(scanned)) {
                  if (context.mounted) await prepareX(context);
                  if (await validateKey(scanned!)) {
                    Json jsonPublicKey = await parsePublicKey(scanned);
                    await startTrust(jsonPublicKey, context);
                  } else {
                    assert(await validateSignIn(scanned));
                    try {
                      await signIn(scanned, context);
                    } catch(e, stackTrace) {
                      print('*** signIn exception: $e');
                      print(stackTrace);
                      await alertException(context, e);
                    }
                  }
                }
              }),
        ],
      ),
    ]);
  }
}

Future<bool> validateKeyOrSignIn(String s) async {
  bool key = await validateKey(s);
  bool signIn = await validateSignIn(s);
  return key || signIn;
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
    double size = min(availSize.width, availSize.height) * 0.80;
    String dataString = encoder.convert(data);
    return Column(
      // shrinkWrap: true,
      // mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 20),
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
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Colors.black)),
      ],
    );
  }
}
