import '../models/settings.dart';

List<String> linesToList(String text) {
  return text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

TypeRules parseTypeRules(String text) {
  final types = <String>[];
  final rules = <String, String>{};
  for (final line in linesToList(text)) {
    final separator = _separatorIndex(line);
    final key =
        separator == -1 ? line.trim() : line.substring(0, separator).trim();
    final value = separator == -1 ? '' : line.substring(separator + 1).trim();
    if (key.isEmpty) {
      continue;
    }
    types.add(key);
    if (value.isNotEmpty) {
      rules[key] = value;
    }
  }
  return TypeRules(types, rules, const {});
}

TypeRules parseTypeRulesWithPriorities(String text) {
  final types = <String>[];
  final rules = <String, String>{};
  final priorities = <String, int>{};
  for (final line in linesToList(text)) {
    final pipe = line.lastIndexOf('|');
    final body = pipe == -1 ? line : line.substring(0, pipe);
    final priority =
        pipe == -1 ? null : int.tryParse(line.substring(pipe + 1).trim());
    final parsed = parseTypeRules(body);
    if (parsed.types.isEmpty) {
      continue;
    }
    final itemType = parsed.types.first;
    types.add(itemType);
    if (parsed.rules.containsKey(itemType)) {
      rules[itemType] = parsed.rules[itemType]!;
    }
    if (priority != null && priority > 0) {
      priorities[itemType] = priority;
    }
  }
  return TypeRules(types, rules, priorities);
}

String formatTypeRules(
  List<String> types,
  Map<String, String> rules, [
  Map<String, int> priorities = const {},
]) {
  final lines = <String>[];
  final seen = <String>{};
  for (final itemType in types) {
    seen.add(itemType);
    lines.add(
        _formatTypeRuleLine(itemType, rules[itemType], priorities[itemType]));
  }
  for (final entry in rules.entries) {
    if (!seen.contains(entry.key)) {
      lines.add(
          _formatTypeRuleLine(entry.key, entry.value, priorities[entry.key]));
    }
  }
  return lines.join('\n');
}

Settings settingsFromText({
  required String cabinetRules,
  required String endpointRules,
  required String signalTypes,
  required String statuses,
}) {
  final cabinets = parseTypeRules(cabinetRules);
  final endpoints = parseTypeRulesWithPriorities(endpointRules);
  final signals = parseTypeRulesWithPriorities(signalTypes);
  final statusList = linesToList(statuses);
  return Settings(
    cabinetTypes: cabinets.types,
    cabinetNameRules: cabinets.rules,
    endpointTypes: endpoints.types,
    endpointNameRules: endpoints.rules,
    endpointTypePriorities: endpoints.priorities,
    signalTypes: signals.types,
    signalTypeExportNames: signals.rules,
    signalTypePriorities: signals.priorities,
    statuses: statusList.isEmpty ? defaultStatuses : statusList,
  );
}

String _formatTypeRuleLine(String itemType, String? rule, int? priority) {
  var line = rule == null || rule.isEmpty ? itemType : '$itemType=$rule';
  if (priority != null && priority > 0) {
    line = '$line|$priority';
  }
  return line;
}

int _separatorIndex(String line) {
  final equals = line.indexOf('=');
  final colon = line.indexOf(':');
  if (equals == -1) {
    return colon;
  }
  if (colon == -1) {
    return equals;
  }
  return equals < colon ? equals : colon;
}

class TypeRules {
  const TypeRules(this.types, this.rules, this.priorities);

  final List<String> types;
  final Map<String, String> rules;
  final Map<String, int> priorities;
}
