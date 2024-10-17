import 'package:flutter/material.dart';
import 'package:oneofus/oneofus/show_qr.dart';
import 'package:oneofus/oneofus/trust_statement.dart';

import '../base/my_keys.dart';
import '../base/my_statements.dart';
import '../oneofus/util.dart';

/// Make it clear that this is a key, and try to show if it's my active, equivalent, revoked, blocked, etc..
/// CONSIDER: Show [QR, token, allow copy option].
/// CONSIDER: If it's supposed to be one of my keys, then include a number.

enum KeyType {
  oneofus,
  delegate,
  other;
}

// NOTE: This app (phone app, only has my statements) doesn't know if someone else's
// key has been blocked or replaced.
class KeyWidget extends StatelessWidget {
  final String keyToken;
  final KeyType keyType;
  final bool local;
  final bool revoked; // ignored for other folks' keys.
  late final String? tooltip;

  factory KeyWidget(String keyToken) {
    TrustStatement? delegateStatement;
    List<TrustStatement> delegateStatements = MyStatements.getByVerbs({TrustVerb.delegate});
    Iterable<TrustStatement> tokenDelegateStatements =
        delegateStatements.where((TrustStatement s) => s.subjectToken == keyToken);
    if (tokenDelegateStatements.isNotEmpty) {
      // This happens when I replace a key and re-delegate. assert(tokenDelegateStatements.length == 1);
      delegateStatement = tokenDelegateStatements.first;
    }

    TrustStatement? blockStatement;
    List<TrustStatement> blockStatements = MyStatements.getByVerbs({TrustVerb.block});
    Iterable<TrustStatement> tokenBlockStatements =
        blockStatements.where((TrustStatement s) => s.subjectToken == keyToken);
    if (tokenBlockStatements.isNotEmpty) {
      // This fires when an equivalent has blocked: assert(tokenBlockStatements.length == 1);
      blockStatement = tokenBlockStatements.first;
    }

    bool local = MyKeys.getLocalDelegateKeys().contains(keyToken) || keyToken == MyKeys.oneofusToken;
    bool revoked;
    KeyType keyType;
    if (keyToken == MyKeys.oneofusToken) {
      keyType = KeyType.oneofus;
      revoked = false; // DEFER: Make sure you haven't revoked yourself.
    } else if (MyStatements.equivalentKeys.contains(keyToken)) {
      keyType = KeyType.oneofus;
      revoked = true;
    } else if (b(delegateStatement)) {
      keyType = KeyType.delegate;
      revoked = b(delegateStatement!.revokeAt);
    } else {
      keyType = KeyType.other;
      revoked = b(blockStatement); // DEFER: blocked or revoked
    }
    return KeyWidget.skip(keyToken, local, keyType, revoked);
  }

  KeyWidget.skip(this.keyToken, this.local, this.keyType, this.revoked, {super.key}) {
    String activeS = revoked ? 'revoked or blocked' : 'valid';
    if (local) {
      if (keyType == KeyType.oneofus) {
        tooltip = 'My $activeS Oneofus key';
      } else {
        tooltip = 'An $activeS delegate key of mine';
      }
    } else {
      if (keyType == KeyType.oneofus) {
        assert(revoked);
        tooltip = 'An equivalent, replaced Oneofus key of mine';
      } else if (keyType == KeyType.delegate) {
        tooltip = 'A lost, $activeS delegate key of mine';
      } else {
        tooltip = 'Someone else\'s $activeS key';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (keyType) {
      case KeyType.oneofus:
        color = local ? Colors.green.shade700 : Colors.green.shade100;
      case KeyType.delegate:
        color = local ? Colors.blue.shade700 : Colors.blue.shade100;
      case KeyType.other:
        color = Colors.black38;
    }

    IconData iconData = !revoked ? Icons.key_outlined : Icons.key_off_outlined;

    return InkWell(
        // onTap: (() => {qr.showBig(context)}),
        onDoubleTap: () {
          ShowQr(keyToken).show(context);
        },
        child: Tooltip(
          message: tooltip,
          child: Icon(
            iconData,
            // fill: 0.0, (Doesn't change anything I can see)
            color: color,
          ),
        ));
  }
}
