import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/notice_strings.dart';

void main() {
  test('the server-side notice texts are generated from the ARB files', () {
    expect(
      File(outputPath).readAsStringSync(),
      generateNoticeStrings(readArbs()),
      reason: 'Run `dart run tool/notice_strings.dart` and commit backend/core/notice_strings.ts.',
    );
  });

  test('every language has every notice, with the same placeholders', () {
    final arbs = readArbs();
    final keys = {
      for (final k in arbs['en']!.keys)
        if (k.startsWith('push') && arbs['en']![k] is String) k,
    };
    expect(keys, isNotEmpty);
    for (final MapEntry(key: lang, value: arb) in arbs.entries) {
      expect(arb.keys.where((k) => k.startsWith('push') && arb[k] is String).toSet(), keys, reason: lang);
    }
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final k in keys) {
      final names = {
        for (final lang in arbs.keys) lang: placeholder.allMatches(arbs[lang]![k] as String).map((m) => m[1]).toSet(),
      };
      expect(names['it'], names['en'], reason: k);
    }
  });
}
