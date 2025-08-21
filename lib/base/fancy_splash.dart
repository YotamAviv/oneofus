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

// animation by chatGPT
final keyFancyAnimation = GlobalKey<_KeyQrTextState>();

class FancySplash extends StatelessWidget {
  const FancySplash({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.bottomRight, children: [
      _KeyQrText(key: keyFancyAnimation),
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
                  await prepareX(context); // CONSIDER how I do this, who's responsible, ...
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

class _KeyQrTextState extends State<_KeyQrText> with SingleTickerProviderStateMixin {
  Json data = {};

  late final AnimationController _ctrl;
  late final Animation<Offset> _offset; // px translation
  late final Animation<double> _rot; // radians

  @override
  void initState() {
    super.initState();
    MyKeys.publicExportNotifier.addListener(listener);
    listener();

    // --- throw animation (jerky) ---
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    // A few quick “steps”: back, snap forward, overshoot, settle
    _offset = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-8, 0)), weight: 12),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-8, 0), end: const Offset(26, -8)), weight: 22),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(26, -8), end: const Offset(46, -14)), weight: 22),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(46, -14), end: const Offset(0, 0)), weight: 44),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _rot = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -3 * pi / 180), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -3 * pi / 180, end: 5 * pi / 180), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 5 * pi / 180, end: 8 * pi / 180), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 8 * pi / 180, end: 0.0), weight: 44),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  // Public method: trigger the throw
  Future<void> throwQr() async {
    if (!_ctrl.isAnimating) {
      await _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    MyKeys.publicExportNotifier.removeListener(listener);
    _ctrl.dispose();
    super.dispose();
  }

  void listener() {
    setState(() {
      data = MyKeys.publicExportNotifier.value.isNotEmpty ? MyKeys.oneofusPublicKey : {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final availSize = MediaQuery.of(context).size;
    final size = min(availSize.width, availSize.height) * 0.80;
    final dataString = encoder.convert(data);

    return Column(children: [
      const SizedBox(height: 20),
      AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.translate(
          offset: _offset.value,
          child: Transform.rotate(
            angle: _rot.value,
            child: child,
          ),
        ),
        child: QrImageView(
          data: dataString,
          version: QrVersions.auto,
          size: size,
        ),
      ),
      TextField(
        controller: TextEditingController()..text = dataString,
        maxLines: null,
        readOnly: true,
        style: GoogleFonts.courierPrime(
            fontWeight: FontWeight.w700, fontSize: 10, color: Colors.black),
      ),
    ]);
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
