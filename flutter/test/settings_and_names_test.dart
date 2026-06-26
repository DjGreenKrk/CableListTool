import 'package:cable_list_tool/domain/services/name_sequence.dart';
import 'package:cable_list_tool/domain/services/settings_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses type rules with optional export names and priorities', () {
    final rules = parseTypeRulesWithPriorities('''
Audio=A|10
DMX=DMX|20
ETH
Bad=Value|x
''');

    expect(rules.types, ['Audio', 'DMX', 'ETH', 'Bad']);
    expect(rules.rules['Audio'], 'A');
    expect(rules.rules['ETH'], isNull);
    expect(rules.priorities['Audio'], 10);
    expect(rules.priorities['Bad'], isNull);
  });

  test('generates next name from N placeholders', () {
    final next = nextNameForRule(
      {'Floorbox': 'FB-NN'},
      'Floorbox',
      'P-N',
      ['FB-01', 'FB-02', 'FB-10'],
    );

    expect(next, 'FB-11');
  });

  test('creates sequence preserving number width', () {
    expect(makeSequence('RSC-09', 3), ['RSC-09', 'RSC-10', 'RSC-11']);
    expect(makeSequence('Panel', 2), ['Panel-1', 'Panel-2']);
  });
}
