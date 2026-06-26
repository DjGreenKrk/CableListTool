class Endpoint {
  const Endpoint({
    required this.id,
    this.name = '',
    this.endpointType = defaultEndpointType,
    this.location = '',
    this.description = '',
  });

  static const defaultEndpointType = 'Floorbox';

  final String id;
  final String name;
  final String endpointType;
  final String location;
  final String description;

  Endpoint copyWith({
    String? id,
    String? name,
    String? endpointType,
    String? location,
    String? description,
  }) {
    return Endpoint(
      id: id ?? this.id,
      name: name ?? this.name,
      endpointType: endpointType ?? this.endpointType,
      location: location ?? this.location,
      description: description ?? this.description,
    );
  }

  factory Endpoint.fromJson(
      Map<String, Object?> json, String Function() newId) {
    return Endpoint(
      id: _stringOrGenerated(json['id'], newId),
      name: _stringOr(json['name'], ''),
      endpointType:
          _stringOr(json['endpoint_type'] ?? json['type'], defaultEndpointType),
      location: _stringOr(json['location'], ''),
      description: _stringOr(json['description'], ''),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'endpoint_type': endpointType,
      'location': location,
      'description': description,
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
