import 'package:flutter/material.dart';
import 'package:oneofus/share.dart';
import 'package:oneofus/widgets/demo_statement_route.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/menu_title.dart';
import 'package:oneofus/widgets/loading.dart';

import '../misc/backup.dart';
import '../delegate_keys_route.dart';
import '../misc/import_export.dart';
import 'my_keys.dart';
import '../oneofus_keys_route.dart';
import '../trusts_route.dart';

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
        child: const Text('My network: [trust, block] people')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const DelegateKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: const Text('My services: [delegate] authority')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const OneofusKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: const Text('My identity: [replace] (or claim) my own keys')),
  ], child: const Text('Sign'));
}

Widget buildTrustMenu(context) {
  return MenuItemButton(
      onPressed: () async {
        await prepareX(context);
        if (context.mounted) await encourageDelegateRepInvariant(context);
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const TrustsRoute()));
        if (context.mounted) await prepareX(context);
        if (context.mounted) await encourageDelegateRepInvariant(context);
      },
      child: const Text('Trust...'));
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
    ],
    child: const Text('Etc'),
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
  ], child: const Text('Dev'));
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
