import 'package:flutter/material.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/main.dart';
import 'package:oneofus/oneofus/distincter.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/fire_factory.dart';
import 'package:oneofus/oneofus/fire_util.dart';
import 'package:oneofus/oneofus/jsonish.dart';
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
    // TODO: Jsonish.wipeCache(); // With this not commented out, crypto verify is slow all the time.
    Fetcher.clear();
    clearDistinct(); // Redundant? Should this be somewhere deeper?
    await MyStatements.load();
  } finally {
    // TODO: FIX: Happens reliably when I import my keys
  //   E/flutter (22245): [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: Looking up a deactivated widget's ancestor is unsafe.
  // E/flutter (22245): At this point the state of the widget's element tree is no longer stable.
  // E/flutter (22245): To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
  // E/flutter (22245): #0      Element._debugCheckStateIsActiveForAncestorLookup.<anonymous closure> (package:flutter/src/widgets/framework.dart:4873:9)
  // E/flutter (22245): #1      Element._debugCheckStateIsActiveForAncestorLookup (package:flutter/src/widgets/framework.dart:4887:6)
  // E/flutter (22245): #2      Element.findAncestorStateOfType (package:flutter/src/widgets/framework.dart:4958:12)
  // E/flutter (22245): #3      Navigator.of (package:flutter/src/widgets/navigator.dart:2781:40)
  // E/flutter (22245): #4      Navigator.pop (package:flutter/src/widgets/navigator.dart:2665:15)
  // E/flutter (22245): #5      Loading.pop (package:oneofus/widgets/loading.dart:10:15)
  // E/flutter (22245): #6      prepareX (package:oneofus/base/menus.dart:35:13)

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
  return SubmenuButton(menuChildren: <Widget>[
    MenuItemButton(
        onPressed: () async {
          await checkRead(FireFactory.find(kOneofusDomain), kOneofusCol);
        },
        child: const Text('checkfire: oneofus, read')),
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
