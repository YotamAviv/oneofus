import 'package:collection/collection.dart';

// A past, failed attempt at this was more ambitions and considered nesting cost of 
// 'fire' or 'tokenize' inside the Comps.
// The static stuff could be changed to support to MeasureGroup instances with Comps in one and
// 'fire', 'tokenize' in the other.
class Measure {
  static final Map<String, Measure> _instances = {};

  factory Measure(String name) => _instances.putIfAbsent(name, () => Measure._internal(name));

  static void dump() {
    print('Measures:');
    for (Measure m in _instances.values.sorted((a, b) => a.elapsed < b.elapsed ? 1 : -1)) {
      print('- ${m.elapsed}: ${m._name}');
    }
  }

  static void reset() {
    for (Measure m in _instances.values) {
      m._reset();
    }
  }

  Measure._internal(this._name);

  final Stopwatch _stopwatch = Stopwatch();
  final String _name;

  void _reset() {
    _stopwatch.reset();
    // token2time.clear();
  }

  void start() {
    _stopwatch.start();
  }

  void stop() {
    _stopwatch.stop();
  }

  Duration get elapsed => _stopwatch.elapsed;

  bool get isRunning => _stopwatch.isRunning;

  Future mAsync(func, {String? note}) async {
    try {
      assert(!_stopwatch.isRunning);
      _stopwatch.start();
      final out = await func();
      return out;
    } finally {
      _stopwatch.stop();
    }
  }

  // dynamic mSync(func) {
  //   try {
  //     assert(!_stopwatch.isRunning);
  //     _stopwatch.start();
  //     final out = func();
  //     return out;
  //   } finally {
  //     _stopwatch.stop();
  //   }
  // }
}
