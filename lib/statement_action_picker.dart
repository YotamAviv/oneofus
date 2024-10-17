import 'package:flutter/material.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/oneofus/jsonish.dart';
import 'package:oneofus/oneofus/ui/linky.dart';

import 'modify_statement_route.dart';
import 'base/my_statements.dart';
import 'oneofus/trust_statement.dart';
import 'widgets/statement_widget.dart';

/// Displays statement boxes based on search verbs.
/// Allows user to choose a statement and re-state it
class StatementActionPicker extends StatefulWidget {
  final Set<TrustVerb> verbs;

  // TODO: reduce to just 'verbs'. Clear should be on us.
  const StatementActionPicker(this.verbs, {super.key});

  @override
  State<StatefulWidget> createState() => _StatementActionPickerState();
}

class _StatementActionPickerState extends State<StatementActionPicker> {
  @override
  void initState() {
    super.initState();
    // Listen to Keys, we may change what delegate keys we have.
    MyKeys.publicExportNotifier.addListener(listen);
    // listen for new statements
    MyStatements.notifier.addListener(listen);
  }

  @override
  void dispose() {
    super.dispose();
    MyKeys.publicExportNotifier.removeListener(listen);
    MyStatements.notifier.removeListener(listen);
  }

  void listen() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<TrustStatement> statements = MyStatements.getByVerbs(widget.verbs);
    List<Row> rows = <Row>[];
    for (TrustStatement statement in statements) {
      rows.add(Row(children: [
        Flexible(
            child: StatementWidget(
          statement,
          () async {

            bool fresh2 = !(MyStatements.getByI(MyKeys.oneofusToken)
                .any((s) => s.subjectToken == statement.subjectToken));
            assert(!fresh2);

            List<TrustVerb> verbs2 = List.of(widget.verbs);
            if (!fresh2) {
              verbs2.add(TrustVerb.clear);
            }

            Jsonish? jsonish =
                await ModifyStatementRoute.show(statement, verbs2, false, context);
            if (context.mounted) await prepareX(context); // redundant?
            setState(() {});
          },
        ))
      ]));
    }
    return Column(children: rows);
  }
}
