import 'package:flutter/material.dart';
import 'package:oneofus/oneofus/fetcher.dart';
import 'package:oneofus/oneofus/trust_statement.dart';

import 'oneofus/util.dart';
import 'widgets/statement_widget.dart';

// CONSIDER: Allow scanning (or pasting) in case there's a ton of statements, and the Nerdster recommended..

class PickRevokeAtStatementRoute extends StatefulWidget {
  final String keyToken;

  const PickRevokeAtStatementRoute(this.keyToken, {super.key});

  static Future<String?> pick(String keyToken, BuildContext context) async {
    assert(b(keyToken));
    String? picked = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PickRevokeAtStatementRoute(keyToken),
      ),
    );
    return picked;
  }

  @override
  State<StatefulWidget> createState() => _PickRevokeAtStatementRouteState();
}

class _PickRevokeAtStatementRouteState extends State<PickRevokeAtStatementRoute> {
  Iterable<TrustStatement>? allStatementsNoDistinctNoVerify;

  @override
  void initState() {
    super.initState();
    asyncInit();
  }

  Future<void> asyncInit() async {
    allStatementsNoDistinctNoVerify =
        (await Fetcher(widget.keyToken, kOneofusDomain).fetchAllNoVerify())
            .cast<TrustStatement>();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!b(allStatementsNoDistinctNoVerify)) {
      return Scaffold(
          appBar: AppBar(title: const Text('Pick revokeAt Statement')),
          body: const Text('Loading..'));
    }
    List<Row> rows = <Row>[];
    for (TrustStatement statement in allStatementsNoDistinctNoVerify!) {
      rows.add(Row(children: [
        Flexible(
            child: StatementWidget(
          statement,
          () {
            Navigator.of(context).pop(statement.token);
          },
        ))
      ]));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Pick revokeAt Statement')),
        body: ListView(
          shrinkWrap: true,
          children: [
            ...rows,
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop('since always');
                  },
                  child: const Text('Revoked at "since always"'))
            ]),
          ],
        ));
  }
}
