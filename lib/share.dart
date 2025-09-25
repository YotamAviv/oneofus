import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePublicKeyQr() async {
  final directory = await getApplicationDocumentsDirectory();
  Uint8List image = await _toQrImageData(encoder.convert(MyKeys.oneofusPublicKey));
  final imagePath = await File('${directory.path}/${MyKeys.oneofusToken}.png').create();
  await imagePath.writeAsBytes(image);
  ShareResult shareResult =
      await Share.shareXFiles([XFile(imagePath.path)], subject: "one-of-us.net public key QR");
}

Future<void> sharePublicKeyText() async {
  ShareResult shareResult = await Share.share(encoder.convert(MyKeys.oneofusPublicKey),
      subject: "one-of-us.net public key text");
}

const String homeUrl = 'https://one-of-us.net';

Future<void> shareHomeLinkQR() async {
  final directory = await getApplicationDocumentsDirectory();
  Uint8List image = await _toQrImageData(homeUrl);
  final imagePath = await File('${directory.path}/homeLink.png').create();
  await imagePath.writeAsBytes(image);
  ShareResult shareResult =
      await Share.shareXFiles([XFile(imagePath.path)], subject: "https://one-of-us.net");
}

Future<void> shareHomeLinkText() async {
  ShareResult shareResult = await Share.share(homeUrl, subject: homeUrl);
}

Future<Uint8List> _toQrImageData(String text) async {
  final ui.Image image = await QrPainter(
    data: text,
    version: QrVersions.auto,
    gapless: true,
  ).toImage(300);
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
