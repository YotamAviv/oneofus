import 'package:flutter/material.dart';
import 'package:oneofus/delegate_keys_route.dart';
import 'package:oneofus/oneofus/crypto/crypto.dart';
import 'package:oneofus/oneofus/util.dart';
import 'package:oneofus/oneofus/ui/alert.dart';

import 'fancy_splash.dart';
import '../misc/import_export.dart';
import 'my_keys.dart';
import 'menus.dart';

class Base extends StatefulWidget {
  const Base({super.key});

  @override
  State<StatefulWidget> createState() => _BaseState();
}

class _BaseState extends State<Base> {
  @override
  void initState() {
    super.initState();
    MyKeys.publicExportNotifier.addListener(listener);
  }

  @override
  void dispose() {
    MyKeys.publicExportNotifier.removeListener(listener);
    super.dispose();
  }

  void listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (MyKeys.publicExportNotifier.value.isEmpty) {
      return const NoKeys();
    } else {
      return Scaffold(
          body: SafeArea(
              child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Expanded(child: MenuBar(children: buildMenus(context))),
        ]),
        const FancySplash()
      ])));
    }
  }
}

class NoKeys extends StatelessWidget {
  const NoKeys({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text('You have no key on this device.', style: TextStyle(fontSize: 20)),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          OutlinedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImportExport(),
                  ),
                );
                // TODO: This "if (context.mounted)" seems wrong. Same elsewhere.
                // BUG: MINOR: prepareX throws exception if nothing was imported and back was chosen.
                if (context.mounted) await prepareX(context);
                if (context.mounted) await encourageDelegateRepInvariant(context);
              },
              child: const Text('Import key(s)')),
          const Spacer(),
          OutlinedButton(
              onPressed: () async {
                await alert(
                    'Claim your lost key',
                    '''1) Choose "Create a new key" for now.
2) Next, use menu => State => "My equivalent one-of-us keys: {replace}". This is where you'll be asked to identify your lost key and state that your new key replaces it.
3) Finally, inform your comrades and associates who one-of-us trusted your old key and ask them to trust your new key.
https://RTFM#replace''',
                    ['Okay'],
                    context);
              },
              child: const Text('Claim lost key')),
          const Spacer(),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
              onPressed: () async {
                OouKeyPair newKeyPair = await crypto.createKeyPair();
                await alert(
                    'Congratulations',
                    '''You're about to posses a public/private cryptographic key pair!

- Your public key is displayed in both QR and text on the main screen. Other folks with the app can scan that to one-of-us trust you as a responsible human.

- Use the person_add icon to scan other folks' screens to trust them. Doing so will use your private key to sign a trust statement and publish it to grow your (and our) trust network of responsible humans. 
''',
                    ['Okay'],
                    context);
                await MyKeys.storeOneofusKey(newKeyPair);
              },
              child: const Text('Create new key')),
        ],
      ),
    ])));
  }
}
