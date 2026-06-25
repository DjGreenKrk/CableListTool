from __future__ import annotations

import re
import unicodedata


def make_sequence(base_name: str, count: int) -> list[str]:
    name = base_name.strip()
    count = max(1, count)
    if count == 1:
        return [name]

    match = re.search(r"(\d+)(?!.*\d)", name)
    if match is None:
        return [f"{name}-{index}" for index in range(1, count + 1)]

    start = int(match.group(1))
    width = len(match.group(1))
    prefix = name[: match.start(1)]
    suffix = name[match.end(1) :]
    return [f"{prefix}{str(start + offset).zfill(width)}{suffix}" for offset in range(count)]


def next_name_after_sequence(base_name: str, count: int) -> str:
    names = make_sequence(base_name, count + 1)
    return names[-1]


def next_name_for_prefix(prefix: str, existing_names: list[str]) -> str:
    rule = prefix.strip() or "ITEM-N"
    pattern = name_rule_pattern(rule)
    next_number = next_number_for_pattern(pattern, existing_names)
    return f"{pattern.prefix}{str(next_number).zfill(pattern.width)}{pattern.suffix}"


def next_number_for_prefix(prefix: str, existing_names: list[str]) -> int:
    escaped = re.escape(prefix.strip())
    pattern = re.compile(rf"^{escaped}[-_ ]?(\d+)$", re.IGNORECASE)
    highest = 0
    for name in existing_names:
        match = pattern.match(name.strip())
        if match:
            highest = max(highest, int(match.group(1)))
    return highest + 1


class NameRulePattern:
    def __init__(self, prefix: str, suffix: str, width: int) -> None:
        self.prefix = prefix
        self.suffix = suffix
        self.width = width


def name_rule_pattern(rule: str) -> NameRulePattern:
    match = re.search(r"N+", rule, re.IGNORECASE)
    if match:
        return NameRulePattern(rule[: match.start()], rule[match.end() :], match.end() - match.start())
    return NameRulePattern(f"{rule}-", "", 1)


def next_number_for_pattern(pattern: NameRulePattern, existing_names: list[str]) -> int:
    escaped_prefix = re.escape(pattern.prefix)
    escaped_suffix = re.escape(pattern.suffix)
    regex = re.compile(rf"^{escaped_prefix}(\d+){escaped_suffix}$", re.IGNORECASE)
    highest = 0
    for name in existing_names:
        match = regex.match(name.strip())
        if match:
            highest = max(highest, int(match.group(1)))
    return highest + 1


def resolve_name_rule(rules: dict[str, str], item_type: str, fallback: str) -> str:
    if item_type in rules:
        return rules[item_type]
    normalized_type = normalize_key(item_type)
    for key, value in rules.items():
        if normalize_key(key) == normalized_type:
            return value
    return fallback


def normalize_key(value: str) -> str:
    text = unicodedata.normalize("NFKD", value)
    text = "".join(char for char in text if not unicodedata.combining(char))
    return re.sub(r"[^a-z0-9]+", "", text.lower())
