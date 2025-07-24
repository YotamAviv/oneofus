import 'package:flutter/material.dart';

import 'key_widget.dart';
import '../base/my_keys.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/trust_statement.dart';
import '../oneofus/util.dart';

// TODO(3): Show conflicts in red or pink (among my active and equivalent keys)
// Hmmm..
// - red if equiv has a block that active has trust
// - pink if active has nothing
// - even lighter if equiv matches active
// ... There are comments and monikers, too, and so this wouldn't be complete anyway.
class StatementWidget extends StatelessWidget {
  final TrustStatement statement;
  final VoidCallback? onTap;
  final KeyWidget? iKeyDemo; // used to override display (color and style)
  final KeyWidget? subjectKeyDemo; // used to override display (color and style)

  const StatementWidget(this.statement, this.onTap,
      {this.iKeyDemo, this.subjectKeyDemo, super.key});

  @override
  Widget build(BuildContext context) {
    bool myKey = statement.iToken == MyKeys.oneofusToken;
    Color borderColor = myKey ? Colors.greenAccent : Colors.black26;
    return Container(
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(border: Border.all(color: borderColor)),
        child: InkWell(
          onTap: onTap,
          child: _StatementBoxI(statement, this),
        ));
  }
}

class _StatementBoxI extends StatelessWidget {
  final TrustStatement statement;
  final StatementWidget parent;

  const _StatementBoxI(this.statement, this.parent);

  @override
  Widget build(BuildContext context) {
    Widget iKey = b(parent.iKeyDemo) ? parent.iKeyDemo! : KeyWidget(statement.i);
    Widget subjectKey =
        b(parent.subjectKeyDemo) ? parent.subjectKeyDemo! : KeyWidget(statement.subject);

    DateTime? revokeAtTime;
    if (b(statement.revokeAt)) {
      // I'm not proud of this. We can't always know the revoked time.
      // For delegate keys we sort of can't, especially if it's not a Nerdster delegate.
      // For Oneofus keys, we sort of should be able to.
      // Jsonish.find(token) can sort of find it sometimes, but it's not a full-on Fetcher.fetch(..).
      // It can get confusing, and this indeed feels KLUDGEY.
      // Jsonish.wipeCache(); // for testing, I think.
      Jsonish? revokedStatementJsonish = Jsonish.find(statement.revokeAt!);
      if (b(revokedStatementJsonish)) {
        revokeAtTime = parseIso(revokedStatementJsonish!.json['time']!);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(statement.verb.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            subjectKey,
            const SizedBox(width: 2),
            // DEFER: cutoff long strings with ...
            Tooltip(message: 'moniker', child: Text('"${statement.moniker ?? ''}"')),
            const SizedBox(width: 8),
            Tooltip(
                message: formatUiDatetime(statement.time),
                child: Text('@${formatUiDate(statement.time)}')),
            const Spacer(),
            iKey,
          ],
        ),
        if (b(statement.domain))
          Row(
            children: [
              const Text('domain:'),
              const SizedBox(width: 8),
              Text(overflow: TextOverflow.ellipsis, statement.domain!),
            ],
          ),
        if (b(statement.revokeAt))
          Row(
            children: [
              const Text('revokeAt:'),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(
                overflow: TextOverflow.ellipsis,
                statement.revokeAt!,
              )),
              const SizedBox(width: 8),
              Tooltip(
                  message: b(revokeAtTime) ? formatUiDatetime(revokeAtTime!) : '?',
                  child: Text('(${b(revokeAtTime) ? formatUiDate(revokeAtTime!) : '?'})')),
            ],
          ),
        Tooltip(
            textAlign: TextAlign.left,
            message: 'comment',
            child: Text(
              statement.comment ?? '',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              maxLines: 3,
            )),
      ],
    );
  }
}
