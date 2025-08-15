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
          DevCopyFab(),
          const Spacer(),
          FloatingActionButton(
              tooltip: '''Scan:
- a person's public key to trust (or a bad actor's or bot's to block)
- a delegate service's sign-in parameters''',
              child: const Icon(Icons.qr_code_2),
              onPressed: () async {
                String? scanned = await QrScanner.scan(
                    'Scan key or sign-in parameters', validateKeyOrSignIn, context);
                if (b(scanned)) {
                  if (context.mounted) await prepareX(context);
                  if (await validateKey(scanned!)) {
                    Json jsonPublicKey = await parsePublicKey(scanned);
                    await startTrust(jsonPublicKey, context);
                  } else {
                    assert(await validateSignIn(scanned));
                    try {
                      await signIn(scanned, context);
                    } catch (e, stackTrace) {
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
                fontWeight: FontWeight.w700, fontSize: 10, color: Colors.black)),
      ],
    );
  }
}

// chatGPT... show FloatingActionButton when in DEV mode
class DevCopyFab extends StatefulWidget {
  const DevCopyFab({super.key});

  @override
  State<DevCopyFab> createState() => _DevCopyFabState();
}

class _DevCopyFabState extends State<DevCopyFab> {
  late bool _dev;

  void _onDevChanged() {
    if (Prefs.dev.value != _dev && mounted) {
      setState(() => _dev = Prefs.dev.value);
    }
  }

  @override
  void initState() {
    super.initState();
    _dev = Prefs.dev.value;
    Prefs.dev.addListener(_onDevChanged);
  }

  @override
  void dispose() {
    Prefs.dev.removeListener(_onDevChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_dev) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      FloatingActionButton(
        heroTag: 'Copy',
        tooltip: 'Copy',
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(text: encoder.convert(MyKeys.oneofusPublicKey)),
          );
        },
        child: const Icon(Icons.copy),
      ),
      const SizedBox(width: 8),
    ]);
  }
}
