final _firstNumber = RegExp(r'\d+');
final _parts = RegExp(r'(\d+)');

int naturalNumber(String value) {
  final match = _firstNumber.firstMatch(value);
  if (match == null) {
    return 999999;
  }
  return int.parse(match.group(0)!);
}

int compareNatural(String left, String right) {
  final leftParts = _split(left);
  final rightParts = _split(right);
  final maxLength = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < maxLength; index += 1) {
    if (index >= leftParts.length) {
      return -1;
    }
    if (index >= rightParts.length) {
      return 1;
    }
    final comparison = _comparePart(leftParts[index], rightParts[index]);
    if (comparison != 0) {
      return comparison;
    }
  }
  return 0;
}

List<Object> naturalKey(String value) {
  return _split(value);
}

List<Object> _split(String value) {
  final result = <Object>[];
  for (final part in value.toLowerCase().split(_parts)) {
    if (part.isEmpty) {
      continue;
    }
    result.add(int.tryParse(part) ?? part);
  }
  return result;
}

int compareNaturalKeys(List<Object> left, List<Object> right) {
  final maxLength = left.length > right.length ? left.length : right.length;
  for (var index = 0; index < maxLength; index += 1) {
    if (index >= left.length) {
      return -1;
    }
    if (index >= right.length) {
      return 1;
    }
    final comparison = _comparePart(left[index], right[index]);
    if (comparison != 0) {
      return comparison;
    }
  }
  return 0;
}

int _comparePart(Object left, Object right) {
  if (left is int && right is int) {
    return left.compareTo(right);
  }
  return left.toString().compareTo(right.toString());
}
