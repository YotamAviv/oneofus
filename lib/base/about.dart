import 'package:flutter/material.dart';
import 'package:oneofus/oneofus/ui/linky.dart';
import 'package:oneofus/prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';

class About extends StatelessWidget {
  static late final About singleton;

  final PackageInfo _packageInfo;
  const About._internal(this._packageInfo, {super.key});

  static Future<void> init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    singleton = About._internal(packageInfo);
  }

  @override
  Widget build(BuildContext context) {
    int taps = 0;
    return Scaffold(
        appBar: AppBar(title: const Text('ONE-OF-US.NET')),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20.0), children: [
            Linky('''Home: https://one-of-us.net'''),
            Linky('''Contact: contact@one-of-us.net'''),
            Linky('''Abuse: abuse@one-of-us.net'''),
            const SizedBox(height: 10),
            Linky('Privacy policy: https://www.one-of-us.net/policy'),
            Linky('Terms and conditions: https://www.one-of-us.net/terms'),
            const SizedBox(height: 10),
            Text('Package name: ${_packageInfo.packageName}'),
            Text('Version: ${_packageInfo.version}'),
            GestureDetector(
                onTap: () {
                  taps++;
                  if (taps >= 7) {
                    Prefs.dev.value = true;
                    print('You are now a developer.');
                  }
                },
                child: Text('Build number: ${_packageInfo.buildNumber}')),
          ]),
        ));
  }
}
