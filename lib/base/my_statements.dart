import 'package:flutter/cupertino.dart';
import 'package:oneofus/oneofus/distincter.dart';
import 'package:oneofus/oneofus/util.dart';

import 'my_keys.dart';
import '../oneofus/fetcher.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/trust_statement.dart';

/// Cache all of my statements from all of my keys (equivalents included) and provide non-async methods.
class MyStatements {
  static ValueNotifier notifier = ValueNotifier(null);

  /// all statements by my key and my equivalent keys
  static Map<String, Iterable<TrustStatement>> statements = <String, Iterable<TrustStatement>>{};

  static Future<void> load() async {
    statements.clear();
    await _load(MyKeys.oneofusToken);
    notifier.value = clock.now;
  }

  static Iterable<TrustStatement>? getStatements(String token) => statements[token];

  /// Collect (they're all cached) trust statements made by my key
  /// and equivalents where verb in searchVerbs.
  /// Order (see compareTo):
  /// 1) by my primary key, newest to oldest
  /// 2) by my equivalent keys, newest to oldest
  static List<TrustStatement> collect(Set<TrustVerb> searchVerbs) {
    List<TrustStatement> list = <TrustStatement>[];
    _collect(MyKeys.oneofusToken, searchVerbs, list, {});
    list.sort(_compareTo);
    return list;
  }

  // Equivalent keys only, specifically omit Keys.oneofusToken
  // (Bart has gotten into situations where he replaced a replaced and his main key was also equivalent.)
  static Set<String> getEquivalentKeys() {
    List<TrustStatement> replaceStatements = collect({TrustVerb.replace});
    Set<String> out = <String>{};
    for (TrustStatement s in replaceStatements) {
      if (s.subjectToken != MyKeys.oneofusToken && !out.contains(s.subjectToken)) {
        out.add(s.subjectToken);
      }
    }
    return out;
  }

  // ordered by statement time
  static Iterable<TrustStatement> getStatementsAboutSubject(String subjectToken) {
    List<TrustStatement> out = <TrustStatement>[];
    for (String equiv in [MyKeys.oneofusToken, ...getEquivalentKeys()]) {
      Iterable<TrustStatement>? statements = getStatements(equiv);
      if (b(statements)) {
        Iterable<TrustStatement> matching =
            statements!.where((s) => s.subjectToken == subjectToken);
        if (matching.isNotEmpty) {
          assert(matching.length == 1, matching.length);
          out.add(matching.first);
        }
      }
    }
    out.sort((s1, s2) => s1.time.compareTo(s2.time));
    return out;
  }

  static _collect(
      String token, Set<TrustVerb> searchVerbs, List<TrustStatement> list, Set<String> already) {
    if (already.contains(token)) {
      // This check is to prevent a stack overflow (Mel replaced Bart, Bart
      // replaced Mel back)
      return;
    }
    already.add(token);

    for (TrustStatement s in statements[token] ?? []) {
      TrustVerb verb = s.verb;
      if (searchVerbs.contains(verb)) {
        list.add(s);
      }
      if (verb == TrustVerb.replace) {
        _collect(Jsonish(s.subject).token, searchVerbs, list, already);
      }
    }
  }

  // Fetch and store this token's statements and recurse for equivalent
  // key statements.
  static Future<void> _load(String token, {String? revokeAt}) async {
    if (statements.containsKey(token)) {
      return;
    }
    Fetcher fetcher = Fetcher(token, kOneofusDomain);
    if (b(revokeAt)) {
      fetcher.setRevokeAt(revokeAt!);
    }
    await fetcher.fetch();
    statements[token] = distinct(fetcher.statements).cast<TrustStatement>();
    for (TrustStatement s in statements[token]!) {
      if (s.verb == TrustVerb.replace) {
        await _load(s.subjectToken, revokeAt: s.revokeAt);
      }
    }
  }

  static int _compareTo(TrustStatement s1, TrustStatement s2) {
    if (s1.iToken != s2.iToken && s1.iToken == MyKeys.oneofusToken) {
      return -1;
    } else if (s1.iToken != s2.iToken && s2.iToken == MyKeys.oneofusToken) {
      return 1;
    } else {
      return s2.time.compareTo(s1.time);
    }
  }
}
