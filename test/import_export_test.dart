import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oneofus/base/my_keys.dart';
import 'package:oneofus/misc/import_export.dart';
import 'package:oneofus/oneofus/jsonish.dart';

void main() {
  test('internal2display', () async {
    Json internal = {
      'one-of-us.net' : {'Hi!': 'Hi'},
      'nerdster.org' : {'there': 'there'}
    };

    Json expected = {
      'identity' : {'Hi!': 'Hi'},
      'nerdster.org' : {'there': 'there'}
    };

    Json display = ImportExport.internal2display(internal);
    expect(jsonEncode(display), jsonEncode(expected));
  });

  test('display2internal', () async {
    Json display = {
      'identity' : {'Hi!': 'Hi'},
      'nerdster.org' : {'there': 'there'}
    };

    Json expected = {
      'one-of-us.net' : {'Hi!': 'Hi'},
      'nerdster.org' : {'there': 'there'}
    };

    Json internal = ImportExport.display2internal(display);
    expect(jsonEncode(internal), jsonEncode(expected));
  });

  test('display2internal legacy', () async {
    Json display = {
      'one-of-us.net' : {'Hi!': 'Hi'},
      'nerdster.org' : {'there': 'there'}
    };

    Json expected = {
      'one-of-us.net' : {'Hi!': 'Hi'},
      'nerdster.org' : {'there': 'there'}
    };

    Json internal = ImportExport.display2internal(display);
    expect(jsonEncode(internal), jsonEncode(expected));
  });
}
