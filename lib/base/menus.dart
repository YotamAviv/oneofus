import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/distincter.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/fire_factory.dart';
import 'package:oneofus/oneofus/fire_util.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/ui/my_checkbox.dart';
import 'package:oneofus/share.dart';
import 'package:oneofus/widgets/demo_statement_route.dart';

import '../delegate_keys_route.dart';
import '../misc/backup.dart';
import '../misc/import_export.dart';
import '../oneofus_keys_route.dart';
import '../trusts_route.dart';
import 'my_keys.dart';

class Prefs {
  static ValueNotifier<bool> skipLgtm = ValueNotifier<bool>(false);
}

/// Catch-all that should be called before doing anything.
Future<void> prepareX(BuildContext context) async {
  try {
    context.loaderOverlay.show();

    // TODO: Jsonish.wipeCache(); // With this not commented out, crypto verify is slow all the time.
    Fetcher.clear();
    clearDistinct(); // Redundant? Should this be somewhere deeper?
    await MyStatements.load();
  } finally {
    context.loaderOverlay.hide();
  }
}

String formatVerbs(Iterable<TrustVerb> verbs) {
  return Set.of(verbs.where((v) => v != TrustVerb.clear).map((v) => v.label)).toString();
}

Widget buildKeysMenu2(context) {
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
        child: Text('My network: ${formatVerbs(TrustsRoute.verbs)}')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const DelegateKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: Text('My authorized services: ${formatVerbs(DelegateKeysRoute.verbs)}')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const OneofusKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: Text('My equivalent one-of-us keys: ${formatVerbs(OneofusKeysRoute.verbs)}')),
  ], child: const Text('state'));
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
      SubmenuButton(menuChildren: [
        MenuItemButton(
            onPressed: () async {
              await prepareX(context);
              if (context.mounted) await encourageDelegateRepInvariant(context);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Import(),
                ),
              );
              if (context.mounted) await prepareX(context);
              if (context.mounted) await encourageDelegateRepInvariant(context);
            },
            child: const Text('Import...')),
        MenuItemButton(
            onPressed: () async {
              await prepareX(context);
              var content = MyKeys.export();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Export(content),
                ),
              );
            },
            child: const Text('Export...')),
      ], child: const Text('Import / Export private keys')),
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
          await showDemoStatements(context);
        },
        child: const Text('statements')),
    MenuItemButton(
        onPressed: () async {
          await showDemoKeys(context);
        },
        child: const Text('keys')),
  ], child: const Text('?'));
}

// TODO: Add functionality: 7 clicks to be a developer.
Widget buildDevMenu(context) {
  const String kOneofusCol = 'firecheck: phone:oneofus';
  const String kNerdsterCol = 'firecheck: phone:nerdster';
  return SubmenuButton(menuChildren: <Widget>[
    SubmenuButton(menuChildren: [
      MenuItemButton(
          onPressed: () async {
            await checkRead(FireFactory.find(kOneofusDomain), kOneofusCol);
          },
          child: const Text('oneofus read')),
      MenuItemButton(
          onPressed: () async {
            await checkWrite(FireFactory.find(kOneofusDomain), kOneofusCol);
          },
          child: const Text('oneofus write')),
      MenuItemButton(
          onPressed: () async {
            await checkRead(FireFactory.find(kNerdsterDomain), kNerdsterCol);
          },
          child: const Text('nerdster read')),
      MenuItemButton(
          onPressed: () async {
            await checkWrite(FireFactory.find(kNerdsterDomain), kNerdsterCol);
          },
          child: const Text('nerdster write')),
    ], child: const Text('Firebase check')),
    MenuItemButton(
        onPressed: () async {
          try {
            context.loadingOverlay.show();
            await backup();
          } finally {
            context.loadingOverlay.hide();
          }
        },
        child: const Text('backup')),
    MenuItemButton(
        onPressed: () async {
          await MyKeys.wipe(context);
        },
        child: const Text('wipe')),
  ], child: const Text('dev'));
}

List<Widget> buildMenus(context) {
  return [
    buildKeysMenu2(context),
    // buildKeysMenu(context),
    // buildTrustMenu(context),
    buildEtcMenu(context),
    // SizedBox(width: 50,),
    // const MenuTitle(['one-', 'of-', 'us.', 'net']),
    if (kDev) buildDevMenu(context),
    buildHelpMenu(context),
  ];
}
