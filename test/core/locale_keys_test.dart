import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `LocaleKeys` has no reflection, so its keys are read from the generated
/// source.
final _keyValue = RegExp(r"static const \w+\s*=\s*'([^']+)';");

/// Plural forms (`{"one": …, "other": …}`) are one key to LocaleKeys.
const _pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

Map<String, Object?> _load(String language) => (jsonDecode(
  File('assets/translations/$language.json').readAsStringSync(),
) as Map).cast();

/// The value at a dotted [key] ("settings.theme_dark"), or null.
Object? _lookup(Map<String, Object?> json, String key) {
  Object? node = json;
  for (final part in key.split('.')) {
    if (node is! Map || !node.containsKey(part)) return null;
    node = node[part];
  }
  return node;
}

/// Every key a translation file defines, plural groups counted once.
Iterable<String> _keys(Map<String, Object?> json, [String prefix = '']) sync* {
  for (final MapEntry(:key, :value) in json.entries) {
    final path = '$prefix$key';
    if (value is Map && !value.keys.every(_pluralForms.contains)) {
      yield* _keys(value.cast(), '$path.');
    } else {
      yield path;
    }
  }
}

void main() {
  final localeKeys = _keyValue
      .allMatches(File('lib/generated/locale_keys.g.dart').readAsStringSync())
      .map((m) => m[1]!)
      .toSet();

  test('LocaleKeys was read', () {
    expect(localeKeys, contains('notifications.adhan_channel'));
  });

  for (final language in ['en', 'ar']) {
    final json = _load(language);

    test('every LocaleKeys key exists in $language.json', () {
      final missing = [
        for (final key in localeKeys)
          if (_lookup(json, key) == null) key,
      ];
      expect(missing, isEmpty, reason: 'Missing from $language.json');
    });

    test('$language.json has no keys LocaleKeys lacks (regenerate it)', () {
      final ungenerated = _keys(json).toSet().difference(localeKeys);
      expect(ungenerated, isEmpty);
    });

    test('$language.json plurals all have an "other" form', () {
      for (final key in localeKeys) {
        final value = _lookup(json, key);
        if (value is Map && value.keys.every(_pluralForms.contains)) {
          expect(value, contains('other'), reason: key);
        }
      }
    });
  }
}
