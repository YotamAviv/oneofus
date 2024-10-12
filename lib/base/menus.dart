import 'package:flutter/material.dart';
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

Widget buildKeysMenu(context) {
  return SubmenuButton(menuChildren: <Widget>[
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const OneofusKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: const Text('one-of-us...')),
    MenuItemButton(
        onPressed: () async {
          await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const DelegateKeysRoute()));
          if (context.mounted) await prepareX(context);
          if (context.mounted) await encourageDelegateRepInvariant(context);
        },
        child: const Text('Delegates ...')),
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
    ], child: const Text('Import / Export')),
  ], child: const Text('Keys'));
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

Widget buildHelpMenu(context) {
  return MenuItemButton(
      onPressed: () async {
        await showDemoStatements(context);
      },
      child: const Text('?'));
}

Widget buildDebugMenu(context) {
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
  ], child: const Text('Debug'));
}

List<Widget> buildMenus(context) {
  return [
    buildKeysMenu(context),
    buildTrustMenu(context),
    // const MenuTitle(['one-', 'of-', 'us.', 'net']),
    if (devMenu) buildDebugMenu(context),
    buildHelpMenu(context),
  ];
}
