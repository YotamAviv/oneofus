import 'package:flutter/material.dart';
import 'package:oneofus/base/menus.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/oneofus/jsonish.dart';

import 'base/my_statements.dart';
import 'modify_statement_route.dart';
import 'oneofus/trust_statement.dart';
import 'widgets/statement_widget.dart';

/// Displays statement boxes based on search verbs.
/// Allows user to pick a statement and re-state it
///
// TODO(2): Show the statements with different colors for shadowed and conflicting blocks.

class StatementActionPicker extends StatefulWidget {
  final Set<TrustVerb> verbs;

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
    List stuff = [];
    List<TrustStatement> activeStatements = MyStatements.getByVerbsActive(widget.verbs);
    List<TrustStatement> equivStatements = MyStatements.getByVerbsEquiv(widget.verbs);

    String? desc;
    if (activeStatements.isEmpty && equivStatements.isEmpty) {
      desc = '''You haven't issued any ${formatVerbs(widget.verbs)} statements.''';
      stuff.add(desc);
    }

    String? descActive;
    if (activeStatements.isNotEmpty) {
      descActive =
          '''Below are ${formatVerbs(widget.verbs)} statements signed by your active key. You can click on these to edit (re-state) them with updated fields or to clear (erase) them.''';
      stuff.add(descActive);
      stuff.addAll(activeStatements);
    }

    String? descEquiv;
    if (equivStatements.isNotEmpty) {
      descEquiv =
          '''Below are ${formatVerbs(widget.verbs)} statements signed by your equivalent keys. You can't edit or delete these (because you don't posses those replaced keys) but you can still re-state them and probably override them with your current key.''';
      stuff.add(descEquiv);
      stuff.addAll(equivStatements);
    }

    List<Widget> rows = <Widget>[];
    for (var thing in stuff) {
      if (thing is String) {
        rows.add(Text(thing));
      } else if (thing is TrustStatement) {
        onTap() async {
          Jsonish? jsonish = await ModifyStatementRoute.show(thing, [...widget.verbs], context);
          if (context.mounted) {
            await prepareX(context); // redundant?
            setState(() {});
          }
        }

        rows.add(StatementWidget(thing, onTap));
        // rows.add(Row(children: [Flexible(child: StatementWidget(thing, onTap))]));
      }
    }

    return Column(children: rows);
  }
}
