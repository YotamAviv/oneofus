import 'package:flutter/material.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/ui/my_checkbox.dart';
import 'package:oneofus/share.dart';
import 'package:oneofus/widgets/demo_statement_route.dart';
import 'package:oneofus/widgets/loading.dart';

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
    Loading.push(context);
    Fetcher.clear();
    await MyStatements.load();
  } finally {
    Loading.pop(context);
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
// Prefs
        MyCheckbox(Prefs.skipLgtm, 'Skip statement reviews'),
// MyCheckbox(Prefs.showDevMenu, 'show DEV menu'),
      ], child: const Text('Prefs')),
    ],
    child: const Text('/etc'),
  );
}

Widget buildHelpMenu(context) {
  return MenuItemButton(
      onPressed: () async {
        await showDemoStatements(context);
      },
      child: const Text('?'));
}

Widget buildDevMenu(context) {
  return SubmenuButton(menuChildren: <Widget>[
    MenuItemButton(
        onPressed: () async {
          try {
            Loading.push(context);
            await backup();
          } finally {
            Loading.pop(context);
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
