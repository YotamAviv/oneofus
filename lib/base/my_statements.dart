import 'package:flutter/cupertino.dart';
import 'package:oneofus/oneofus/distincter.dart';
import 'package:oneofus/oneofus/util.dart';

import 'my_keys.dart';
import '../oneofus/fetcher.dart';
import '../oneofus/jsonish.dart';
import '../oneofus/trust_statement.dart';

/// Cache all of my statements from all of my keys (equivalents included) and provide non-async methods.
class MyStatements {
  static ValueNotifier notifier =
      ValueNotifier(null); // CODE: singleton with ChangeNotifier instead

  /// all statements by my key and my equivalent keys
  static final Map<String, Iterable<TrustStatement>> _statements =
      <String, Iterable<TrustStatement>>{};

  static Future<void> load() async {
    _statements.clear();
    await _load(MyKeys.oneofusToken);
    notifier.value = clock.now;
  }

  // Equivalent keys only; active, canonical key (Keys.oneofusToke) is specifically omitted.
  // (Bart has gotten into situations where he replaced a replaced and his main key was also equivalent.)
  static Set<String> get equivalentKeys {
    List<TrustStatement> replaceStatements = getByVerbs({TrustVerb.replace});
    Set<String> out = <String>{};
    for (TrustStatement s in replaceStatements) {
      if (s.subjectToken != MyKeys.oneofusToken && !out.contains(s.subjectToken)) {
        out.add(s.subjectToken);
      }
    }
    return out;
  }

  static Iterable<TrustStatement> getByI(String token) => _statements[token] ?? [];

  /// Collect (they're all cached) trust statements made by my key and equivalents
  /// where verb in searchVerbs.
  /// Order (see compare):
  /// 1) by my primary key, newest to oldest
  /// 2) by my equivalent keys, newest to oldest
  static List<TrustStatement> getByVerbs(Set<TrustVerb> searchVerbs) {
    List<TrustStatement> list = <TrustStatement>[];
    _collect(MyKeys.oneofusToken, searchVerbs, list, {});
    list.sort(_compare);
    return list;
  }

  static List<TrustStatement> getByVerbsActive(Set<TrustVerb> searchVerbs) {
    List<TrustStatement> list = <TrustStatement>[];
    _collect(MyKeys.oneofusToken, searchVerbs, list, {});
    list.removeWhere((s) => s.iToken != MyKeys.oneofusToken);
    list.sort(_compare);
    return list;
  }

  static List<TrustStatement> getByVerbsEquiv(Set<TrustVerb> searchVerbs) {
    List<TrustStatement> list = <TrustStatement>[];
    _collect(MyKeys.oneofusToken, searchVerbs, list, {});
    list.removeWhere((s) => s.iToken == MyKeys.oneofusToken);
    list.sort(_compare);
    return list;
  }

  // ordered by statement time
  static Iterable<TrustStatement> getBySubject(String subjectToken) {
    List<TrustStatement> out = <TrustStatement>[];
    for (String equiv in [MyKeys.oneofusToken, ...equivalentKeys]) {
      Iterable<TrustStatement> statements = getByI(equiv);
      Iterable<TrustStatement> matching = statements.where((s) => s.subjectToken == subjectToken);
      if (matching.isNotEmpty) {
        assert(matching.length == 1, matching.length);
        out.add(matching.first);
      }
    }
    out.sort((s1, s2) => s1.time.compareTo(s2.time));
    return out;
  }

  static _collect(
      String token, Set<TrustVerb> searchVerbs, List<TrustStatement> list, Set<String> already) {
    // Prevent a stack overflow (Mel replaced Bart, Bart replaced Mel back)
    if (already.contains(token)) return;
    already.add(token);

    for (TrustStatement s in getByI(token)) {
      TrustVerb verb = s.verb;
      if (searchVerbs.contains(verb)) {
        list.add(s);
      }
      if (verb == TrustVerb.replace) {
        _collect(Jsonish(s.subject).token, searchVerbs, list, already);
      }
    }
  }

  // Fetch and store this token's statements and recurse for equivalent key statements.
  static Future<void> _load(String token, {String? revokeAt}) async {
    if (_statements.containsKey(token)) return;
    Fetcher fetcher = Fetcher(token, kOneofusDomain);
    if (b(revokeAt)) fetcher.setRevokeAt(revokeAt!);
    await fetcher.fetch();
    _statements[token] =
        distinct(fetcher.statements).cast<TrustStatement>().where((s) => s.verb != TrustVerb.clear);
    // DFS
    for (TrustStatement s in _statements[token]!) {
      if (s.verb == TrustVerb.replace) {
        await _load(s.subjectToken, revokeAt: s.revokeAt);
      }
    }
  }

  static int _compare(TrustStatement s1, TrustStatement s2) {
    if (s1.iToken != s2.iToken && s1.iToken == MyKeys.oneofusToken) {
      return -1;
    } else if (s1.iToken != s2.iToken && s2.iToken == MyKeys.oneofusToken) {
      return 1;
    } else {
      return s2.time.compareTo(s1.time);
    }
  }
}
