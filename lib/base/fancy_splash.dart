import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
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
          if (kDev)
            FloatingActionButton(
                heroTag: 'Copy',
                tooltip: 'Copy',
                child: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(
                      text: encoder.convert(MyKeys.oneofusPublicKey)));
                }),
          if (kDev) const SizedBox(width: 8),
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
                    Jsonish? jsonish = await startTrust(jsonPublicKey, context);
                  } else {
                    assert(await validateSignIn(scanned));
                    await signIn(scanned, context);
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
        SportRow(),
        QrImageView(
          data: dataString,
          version: QrVersions.auto,
          size: size,
        ),
        SportRow(),
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

class SportRow extends StatelessWidget {
  final String kImage1 = 'assets/images/sportdeath_large.gif';
  final String kImage2 = 'assets/images/nerd.gif';
  const SportRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // return Row(
    //   children: List.generate(
    //       7, (index) => Expanded(child: Image.asset(index == 0 || index == 6 ? kImage1 : kImage2))),
    // );
    return Row(children: [
      Expanded(child: Image.asset(kImage1)),
      ...List.generate(7, (index) => Expanded(child: SizedBox())),
      Expanded(child: Image.asset(kImage1)),
    ]);
  }
}
