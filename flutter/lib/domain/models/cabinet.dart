class Cabinet {
  const Cabinet({
    required this.id,
    this.name = '',
    this.cabinetType = defaultCabinetType,
    this.location = '',
    this.description = '',
    this.priority = 0,
  });

  static const defaultCabinetType = 'Szafa sterująca';

  final String id;
  final String name;
  final String cabinetType;
  final String location;
  final String description;
  final int priority;

  Cabinet copyWith({
    String? id,
    String? name,
    String? cabinetType,
    String? location,
    String? description,
    int? priority,
  }) {
    return Cabinet(
      id: id ?? this.id,
      name: name ?? this.name,
      cabinetType: cabinetType ?? this.cabinetType,
      location: location ?? this.location,
      description: description ?? this.description,
      priority: priority ?? this.priority,
    );
  }

  factory Cabinet.fromJson(Map<String, Object?> json, String Function() newId) {
    return Cabinet(
      id: _stringOrGenerated(json['id'], newId),
      name: _stringOr(json['name'], ''),
      cabinetType:
          _stringOr(json['cabinet_type'] ?? json['type'], defaultCabinetType),
      location: _stringOr(json['location'], ''),
      description: _stringOr(json['description'], ''),
      priority: _intOr(json['priority'], 0),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'cabinet_type': cabinetType,
      'location': location,
      'description': description,
      'priority': priority,
    };
  }
}

String _stringOrGenerated(Object? value, String Function() fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback() : text;
}

String _stringOr(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _intOr(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
