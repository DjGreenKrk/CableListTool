final _lastNumber = RegExp(r'(\d+)(?!.*\d)');
final _rulePlaceholder = RegExp('N+', caseSensitive: false);

List<String> makeSequence(String baseName, int count) {
  final name = baseName.trim();
  final safeCount = count < 1 ? 1 : count;
  if (safeCount == 1) {
    return [name];
  }

  final match = _lastNumber.firstMatch(name);
  if (match == null) {
    return [
      for (var index = 1; index <= safeCount; index += 1) '$name-$index',
    ];
  }

  final start = int.parse(match.group(1)!);
  final width = match.group(1)!.length;
  final prefix = name.substring(0, match.start);
  final suffix = name.substring(match.end);
  return [
    for (var offset = 0; offset < safeCount; offset += 1)
      '$prefix${(start + offset).toString().padLeft(width, '0')}$suffix',
  ];
}

String nextNameForRule(
  Map<String, String> rules,
  String itemType,
  String fallback,
  List<String> existingNames,
) {
  final rule = resolveNameRule(rules, itemType, fallback);
  final pattern = nameRulePattern(rule);
  final nextNumber = nextNumberForPattern(pattern, existingNames);
  return '${pattern.prefix}${nextNumber.toString().padLeft(pattern.width, '0')}${pattern.suffix}';
}

NameRulePattern nameRulePattern(String rule) {
  final match = _rulePlaceholder.firstMatch(rule);
  if (match == null) {
    return NameRulePattern('$rule-', '', 1);
  }
  return NameRulePattern(
    rule.substring(0, match.start),
    rule.substring(match.end),
    match.end - match.start,
  );
}

int nextNumberForPattern(NameRulePattern pattern, List<String> existingNames) {
  final regex = RegExp(
    '^${RegExp.escape(pattern.prefix)}(\\d+)${RegExp.escape(pattern.suffix)}\$',
    caseSensitive: false,
  );
  var highest = 0;
  for (final name in existingNames) {
    final match = regex.firstMatch(name.trim());
    if (match != null) {
      final number = int.tryParse(match.group(1)!);
      if (number != null && number > highest) {
        highest = number;
      }
    }
  }
  return highest + 1;
}

String resolveNameRule(
  Map<String, String> rules,
  String itemType,
  String fallback,
) {
  if (rules.containsKey(itemType)) {
    return rules[itemType]!;
  }
  final normalizedType = normalizeKey(itemType);
  for (final entry in rules.entries) {
    if (normalizeKey(entry.key) == normalizedType) {
      return entry.value;
    }
  }
  return fallback;
}

String normalizeKey(String value) {
  final mapped = value.toLowerCase().split('').map(_withoutPolishMark).join();
  return mapped.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _withoutPolishMark(String value) {
  return switch (value) {
    'ą' => 'a',
    'ć' => 'c',
    'ę' => 'e',
    'ł' => 'l',
    'ń' => 'n',
    'ó' => 'o',
    'ś' => 's',
    'ż' => 'z',
    'ź' => 'z',
    _ => value,
  };
}

class NameRulePattern {
  const NameRulePattern(this.prefix, this.suffix, this.width);

  final String prefix;
  final String suffix;
  final int width;
}
