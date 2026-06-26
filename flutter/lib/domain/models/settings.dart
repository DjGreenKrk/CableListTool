const defaultCabinetTypes = [
  'Szafa sterująca',
  'Rack',
  'Szafa elektryczna',
  'Inne',
];

const defaultEndpointTypes = [
  'Floorbox',
  'Przyłącze',
  'Urządzenie',
  'Oprawa',
  'Panel',
  'Projektor',
  'Przycisk',
  'Inne',
];

const defaultSignalTypes = [
  'ETH',
  'DMX',
  'DALI',
  '230V',
  'AUDIO',
  'HDMI',
  'USB',
  'CTRL',
  'INNE',
];

const defaultStatuses = [
  'Do sprawdzenia',
  'Potwierdzone',
  'Niezgodność',
  'Brak kabla',
  'Niezidentyfikowany',
];

const defaultCabinetNameRules = {
  'Szafa sterująca': 'RSC-N',
  'Rack': 'RACK-N',
  'Szafa elektryczna': 'EL-N',
};

const defaultEndpointNameRules = {
  'Floorbox': 'FB-NN',
  'Przyłącze': 'WB-N',
  'Urządzenie': 'DEV-N',
  'Oprawa': 'OP-N',
  'Panel': 'TSC-N',
  'Projektor': 'PROJ-N',
  'Przycisk': 'BTN-N',
};

class Settings {
  const Settings({
    this.cabinetTypes = defaultCabinetTypes,
    this.cabinetNameRules = defaultCabinetNameRules,
    this.endpointTypes = defaultEndpointTypes,
    this.endpointNameRules = defaultEndpointNameRules,
    this.endpointTypePriorities = const {},
    this.signalTypes = defaultSignalTypes,
    this.signalTypeExportNames = const {},
    this.signalTypePriorities = const {},
    this.statuses = defaultStatuses,
  });

  final List<String> cabinetTypes;
  final Map<String, String> cabinetNameRules;
  final List<String> endpointTypes;
  final Map<String, String> endpointNameRules;
  final Map<String, int> endpointTypePriorities;
  final List<String> signalTypes;
  final Map<String, String> signalTypeExportNames;
  final Map<String, int> signalTypePriorities;
  final List<String> statuses;

  Settings copyWith({
    List<String>? cabinetTypes,
    Map<String, String>? cabinetNameRules,
    List<String>? endpointTypes,
    Map<String, String>? endpointNameRules,
    Map<String, int>? endpointTypePriorities,
    List<String>? signalTypes,
    Map<String, String>? signalTypeExportNames,
    Map<String, int>? signalTypePriorities,
    List<String>? statuses,
  }) {
    return Settings(
      cabinetTypes: cabinetTypes ?? this.cabinetTypes,
      cabinetNameRules: cabinetNameRules ?? this.cabinetNameRules,
      endpointTypes: endpointTypes ?? this.endpointTypes,
      endpointNameRules: endpointNameRules ?? this.endpointNameRules,
      endpointTypePriorities:
          endpointTypePriorities ?? this.endpointTypePriorities,
      signalTypes: signalTypes ?? this.signalTypes,
      signalTypeExportNames:
          signalTypeExportNames ?? this.signalTypeExportNames,
      signalTypePriorities: signalTypePriorities ?? this.signalTypePriorities,
      statuses: statuses ?? this.statuses,
    );
  }

  factory Settings.fromJson(Map<String, Object?> json) {
    return Settings(
      cabinetTypes: _stringList(json['cabinet_types'], defaultCabinetTypes),
      cabinetNameRules:
          _stringMap(json['cabinet_name_rules'], defaultCabinetNameRules),
      endpointTypes: _stringList(json['endpoint_types'], defaultEndpointTypes),
      endpointNameRules:
          _stringMap(json['endpoint_name_rules'], defaultEndpointNameRules),
      endpointTypePriorities: _intMap(json['endpoint_type_priorities']),
      signalTypes: _stringList(json['signal_types'], defaultSignalTypes),
      signalTypeExportNames: _stringMap(
        json['signal_type_export_names'] ?? json['signal_type_descriptions'],
        const {},
      ),
      signalTypePriorities: _intMap(json['signal_type_priorities']),
      statuses: _stringList(json['statuses'], defaultStatuses),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'cabinet_types': cabinetTypes,
      'cabinet_name_rules': cabinetNameRules,
      'endpoint_types': endpointTypes,
      'endpoint_name_rules': endpointNameRules,
      'endpoint_type_priorities': endpointTypePriorities,
      'signal_types': signalTypes,
      'signal_type_export_names': signalTypeExportNames,
      'signal_type_priorities': signalTypePriorities,
      'statuses': statuses,
    };
  }
}

List<String> _stringList(Object? value, List<String> fallback) {
  if (value is! List) {
    return List.of(fallback);
  }
  final items = value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
  return items.isEmpty ? List.of(fallback) : items;
}

Map<String, String> _stringMap(Object? value, Map<String, String> fallback) {
  if (value is! Map) {
    return Map.of(fallback);
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key.toString().trim();
    final text = entry.value?.toString().trim() ?? '';
    if (key.isNotEmpty && text.isNotEmpty) {
      result[key] = text;
    }
  }
  return result;
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  final result = <String, int>{};
  for (final entry in value.entries) {
    final key = entry.key.toString().trim();
    final number = entry.value is int
        ? entry.value as int
        : int.tryParse(entry.value.toString());
    if (key.isNotEmpty && number != null && number > 0) {
      result[key] = number;
    }
  }
  return result;
}
