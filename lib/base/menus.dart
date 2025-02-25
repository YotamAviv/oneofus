import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:oneofus/base/about.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/distincter.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/fire_factory.dart';
import 'package:oneofus/oneofus/fire_util.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/ui/my_checkbox.dart';
import 'package:oneofus/prefs.dart';
import 'package:oneofus/share.dart';
import 'package:oneofus/widgets/demo_statement_route.dart';

import '../delegate_keys_route.dart';
import '../misc/backup.dart';
import '../misc/import_export.dart';
import '../oneofus/util.dart';
import '../oneofus_keys_route.dart';
import '../trusts_route.dart';
import 'my_keys.dart';

/// Catch-all that should be called before doing anything.
Future<void> prepareX(BuildContext context) async {
  try {
    context.loaderOverlay.show();
    // TODO: Jsonish.wipeCache(); // With this not commented out, crypto verify is slow all the time.
    Fetcher.clear();
    clearDistincterCache(); // Redundant? Should this be somewhere deeper?
    await MyStatements.load();
  } catch (e) {
    // BUG: I've never caught the exception, only see it in the logs. Firebase seems to revert to a cache.
    print('**************** $e');
    await alertException(context, e);
  } finally {
    context.loaderOverlay.hide();
  }
}

String formatVerbs(Iterable<TrustVerb> verbs) {
  return Set.of(verbs.where((v) => v != TrustVerb.clear).map((v) => v.label)).toString();
}

Widget buildStateMenu(context) {
  return SubmenuButton(menuChildren: <Widget>[
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const TrustsRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: Text('My network: ${formatVerbs(TrustsRoute.spec.verbs)}')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const DelegateKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: Text('My authorized services: ${formatVerbs(DelegateKeysRoute.spec.verbs)}')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const OneofusKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: Text('My equivalent one-of-us keys: ${formatVerbs(OneofusKeysRoute.spec.verbs)}')),
  ], child: const Text('State'));
}

Widget buildEtcMenu(context) {
  return SubmenuButton(
    menuChildren: [
      SubmenuButton(menuChildren: [
        MenuItemButton(
            onPressed: () async {
              await sharePublicKeyQr();
            },
            child: const Text('QR code')),
        MenuItemButton(
            onPressed: () async {
              await sharePublicKeyText();
            },
            child: const Text('JSON text')),
      ], child: const Text('Share my public key')),
      MenuItemButton(
          onPressed: () async {
            await prepareX(context);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ImportExport(),
              ),
            );
            if (context.mounted) await prepareX(context);
            if (context.mounted) await encourageDelegateRepInvariant(context);
          },
          child: const Text('Import/Export...')),
      SubmenuButton(menuChildren: [
        MyCheckbox(Prefs.skipLgtm, 'Skip statement reviews'),
        // MyCheckbox(Prefs.showDevMenu, 'show DEV menu'),
      ], child: const Text('Prefs')),
    ],
    child: const Text('/etc'),
  );
}

Widget buildHelpMenu(context) {
  return SubmenuButton(menuChildren: <Widget>[
    MenuItemButton(
        onPressed: () async {
          await alert(
              'Congratulations',
              '''You posses a public/private cryptographic key pair!

- Your public key is displayed in both QR and text on the main screen. Other folks with the app can scan that to one-of-us trust you as a responsible human.

- Click the QR icon to scan other folks' keys to trust them. Doing so will use your private key to sign a trust statement and publish it to grow your (and our) trust network of responsible humans.

- Click the QR icon to sign in to a delegate partner.

https://one-of-us.net 
''',
              ['Okay'],
              context);
        },
        child: const Text('Congratulations')),
    MenuItemButton(
        onPressed: () async {
          await alert(
              'Main screen',
              '''The QR code front and center is your public key (the gibberish below is the text).
                    
Your public/private key pair is stored on your phone and is used to sign and publish trust statements.

Click the QR icon (bottom right) to scan someone else's public key to one-of-us trust them.

Click the QR icon (bottom right) to sign in to a delegate partner (the Nerd'ster) as yourself''',
              ['Okay'],
              context);
        },
        child: const Text('Main screen')),
    MenuItemButton(
        onPressed: () async {
          await showDemoKeys(context);
        },
        child: const Text('Keys')),
    MenuItemButton(
        onPressed: () async {
          await showDemoStatements(context);
        },
        child: const Text('Statements')),
    MenuItemButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => About.singleton));
        },
        child: const Text('About')),
  ], child: const Text('?'));
}

class DevMenu extends StatefulWidget {
  const DevMenu({super.key});

  @override
  State<StatefulWidget> createState() => DevMenuState();
}

class DevMenuState extends State<DevMenu> {
  @override
  void initState() {
    super.initState();
    Prefs.dev.addListener(listener);
  }

  @override
  void dispose() {
    super.dispose();
    Prefs.dev.removeListener(listener);
  }

  void listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (Prefs.dev.value) {
      return buildDevMenu(context);
    } else {
      return SizedBox();
    }
  }
}

String display(List l) {
  return l.map((x) => x is DateTime ? formatUiDatetime(x) : x.toString()).join('\n');
}

Widget buildDevMenu(BuildContext context) {
  const String kOneofusCol = 'firecheck: phone:oneofus';
  return SubmenuButton(menuChildren: <Widget>[
    SubmenuButton(menuChildren: [
      MenuItemButton(
          onPressed: () async {
            try {
              context.loaderOverlay.show();
              List out = await checkRead(FireFactory.find(kOneofusDomain), kOneofusCol);
              context.loaderOverlay.hide();
              await alert('Fire check', display(out), ['okay'], context);
            } catch (e) {
              await alertException(context, e);
            } finally {
              context.loaderOverlay.hide();
            }
          },
          child: const Text('oneofus read')),
      MenuItemButton(
          onPressed: () async {
            try {
              context.loaderOverlay.show();
              List out = await checkWrite(FireFactory.find(kOneofusDomain), kOneofusCol);
              context.loaderOverlay.hide();
              await alert('Fire check', display(out), ['okay'], context);
            } catch (e) {
              await alertException(context, e);
            } finally {
              context.loaderOverlay.hide();
            }
          },
          child: const Text('oneofus write')),
    ], child: const Text('Firebase check')),
    MenuItemButton(
        onPressed: () async {
          await backup();
        },
        child: const Text('backup')),
    MenuItemButton(
        onPressed: () async {
          String? okay = await alert('Wipe all data? Really?', '', ['Okay', 'Cancel'], context);
          if (b(okay) && okay! == 'Okay') {
            await MyKeys.wipe();
          }
        },
        child: const Text('wipe')),
  ], child: const Text('dev'));
}

List<Widget> buildMenus(context) {
  return [
    buildStateMenu(context),
    buildEtcMenu(context),
    // SizedBox(width: 50,),
    // const MenuTitle(['one-', 'of-', 'us.', 'net']),
    DevMenu(),
    buildHelpMenu(context),
  ];
}
