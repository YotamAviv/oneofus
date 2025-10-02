import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:oneofus/base/about.dart';
import 'package:oneofus/base/my_statements.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/fire_factory.dart';
import 'package:oneofus/oneofus/fire_util.dart';
import 'package:oneofus/oneofus/prefs.dart';
import 'package:oneofus/oneofus/trust_statement.dart';
import 'package:oneofus/oneofus/ui/alert.dart';
import 'package:oneofus/oneofus/ui/my_checkbox.dart';
import 'package:oneofus/setting_type.dart';
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
    await MyStatements.load();
  } catch (e) {
    // BUG: I've never caught the exception, only see it in the logs. Firebase seems to revert to a cache.
    print('**************** $e');
    await alertException(context, e);
    rethrow;
  } finally {
    context.loaderOverlay.hide();
  }
}

String formatVerbs(Iterable<TrustVerb> verbs) {
  return Set.of(verbs.where((v) => v != TrustVerb.clear).map((v) => v.label)).toString();
}

const iconSpacer = SizedBox(width: 3);
const divider = PopupMenuDivider(height: 4);

const String signHelp = '''Statements you sign and publish are divided into 3 groups:
- {trust, block}: which keys represent actual folks you know, or not.
- {delegate}: which keys represent you on other services
- {replace}: which keys have represented your identity in the past

Pick a group to see, state (or re-state, or clear), sign, and publish these statements.''';

const String shareHelp = '''It's challenging because it's different:
1) Help them get the app by sharing a link to $homeUrl
2) Share your public identity key

Depending on if you're in person or remote, showing or emailing may be appropriate.''';

const String settingsHelp = '''It's a good idea to back up your private keys.
Use the Import/Export menu to copy them as text and consider emailing a copy to yourself.''';

Widget buildStateMenu(BuildContext context) {
  return SubmenuButton(
    menuChildren: <Widget>[
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
      divider,
      MenuHelp(signHelp),
    ],
    child: const Row(
      children: [Icon(Icons.fingerprint), iconSpacer, Text('Sign')],
    ),
  );
}

Widget buildShareMenu(BuildContext context) {
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
              await shareHomeLinkQR();
            },
            child: const Text('QR code')),
        MenuItemButton(
            onPressed: () async {
              await shareHomeLinkText();
            },
            child: const Text('text')),
      ], child: const Text('Share link to $homeUrl')),
      divider,
      MenuHelp(shareHelp),
    ],
    child: const Row(children: [Icon(Icons.share), iconSpacer, Text('Share')]),
  );
}

Widget buildSettingsMenu(BuildContext context) {
  return SubmenuButton(
    menuChildren: [
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
        MyCheckbox(
            Setting.get<bool>(SettingType.skipLgtm).notifier, 'Statement review/confirmation',
            opposite: true),
        MyCheckbox(
            Setting.get<bool>(SettingType.skipCredentialsSent).notifier, 'Sign-in credentials sent',
            opposite: true),
        // MyCheckbox(Prefs.showDevMenu, 'show DEV menu'),
      ], child: const Text("Show/don't show")),
      divider,
      MenuHelp(settingsHelp),
    ],
    child: const Row(children: [Icon(Icons.settings), iconSpacer, Text('Settings')]),
  );
}

Widget buildHelpMenu(BuildContext context) {
  return SubmenuButton(menuChildren: <Widget>[
    MenuItemButton(onPressed: () => congratulate(context), child: const Text('Congratulations')),
    MenuItemButton(
        onPressed: () => delegateServicesHelp(context),
        child: const Text('Delegate Services Sign-in')),
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

Future<void> congratulate(BuildContext context) async {
  await alert(
      'Congratulations!',
      '''You posses a public/private cryptographic key pair!

- Your public key is displayed in both QR and text on the main screen. Other folks with the app can scan that to vouch for your humanity and identity.
(Consider backing up your private key; use the menu /etc => Import/Export to get at it.)

Use the QR icon (bottom right) to:
- scan other folks' keys to vouch for their identities. Doing so will use your private key to sign and publish a statement which will grow your (and our) identity network.
- sign in to a service using a delegate key.

https://one-of-us.net
''',
      ['Okay'],
      context);
}

Future<void> delegateServicesHelp(BuildContext context) async {
  await alert(
      'Delegate Services',
      '''Use your identity on any service

- Access https://nerdster.org on a computer.
- Initiate QR Sign-in there which should display a QR code with Sign-in Parameters for your app to scan.
- Click the QR icon on the bottom right of your phone app and show the Sign-in Parameters QR code displayed by the service to your phone app.
- In case you're prompted to create a delegate key, choose yes.

This should work with any service... (as long as it's the Nerdster ;)''',
      ['Okay'],
      context);
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
    Setting.get(SettingType.dev).notifier.addListener(listener);
  }

  @override
  void dispose() {
    super.dispose();
    Setting.get(SettingType.dev).notifier.removeListener(listener);
  }

  void listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return (Setting.get(SettingType.dev).notifier.value) ? buildDevMenu(context) : const SizedBox();
  }
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
              await alert('Fire check', _display(out), ['okay'], context);
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
              await alert('Fire check', _display(out), ['okay'], context);
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

List<Widget> buildMenus(BuildContext context) {
  return [
    buildStateMenu(context),
    buildShareMenu(context),
    buildSettingsMenu(context),
    // SizedBox(width: 50,),
    // const MenuTitle(['one-', 'of-', 'us.', 'net']),
    DevMenu(),
    buildHelpMenu(context),
  ];
}

String _display(List l) {
  return l.map((x) => x is DateTime ? formatUiDatetime(x) : x.toString()).join('\n');
}

class MenuHelp extends StatelessWidget {
  final text;

  const MenuHelp(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
