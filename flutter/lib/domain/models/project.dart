import 'cabinet.dart';
import 'connection.dart';
import 'endpoint.dart';
import 'settings.dart';

const schemaVersion = 1;

class Project {
  const Project({
    this.name = '',
    this.code = '',
    this.cabinets = const [],
    this.endpoints = const [],
    this.connections = const [],
    this.settings = const Settings(),
  });

  final String name;
  final String code;
  final List<Cabinet> cabinets;
  final List<Endpoint> endpoints;
  final List<Connection> connections;
  final Settings settings;

  factory Project.fromJson(Map<String, Object?> json, String Function() newId) {
    final projectJson = json['project'] is Map
        ? Map<String, Object?>.from(json['project']! as Map)
        : json;
    final project = Project(
      name: projectJson['name']?.toString() ?? '',
      code: projectJson['code']?.toString() ?? '',
      cabinets: _objects(json['cabinets'])
          .map((item) => Cabinet.fromJson(item, newId))
          .toList(),
      endpoints: _objects(json['endpoints'])
          .map((item) => Endpoint.fromJson(item, newId))
          .toList(),
      connections: _objects(json['connections'])
          .map((item) => Connection.fromJson(item, newId))
          .toList(),
      settings: json['settings'] is Map
          ? Settings.fromJson(
              Map<String, Object?>.from(json['settings']! as Map))
          : const Settings(),
    );
    return project.expandConnectionQuantities(newId);
  }

  Project expandConnectionQuantities(String Function() newId) {
    final expanded = <Connection>[];
    for (final connection in connections) {
      final quantity = connection.quantity < 1 ? 1 : connection.quantity;
      if (quantity == 1) {
        expanded.add(connection.copyWith(quantity: 1, cableStatuses: const {}));
        continue;
      }
      for (var index = 1; index <= quantity; index += 1) {
        expanded.add(
          Connection(
            id: index == 1 ? connection.id : newId(),
            sourceId: connection.sourceId,
            destinationId: connection.destinationId,
            signalType: connection.signalType,
            quantity: 1,
            status: connection.cableStatuses['$index'] ?? connection.status,
            notes: connection.notes,
          ),
        );
      }
    }
    return copyWith(connections: expanded);
  }

  Project copyWith({
    String? name,
    String? code,
    List<Cabinet>? cabinets,
    List<Endpoint>? endpoints,
    List<Connection>? connections,
    Settings? settings,
  }) {
    return Project(
      name: name ?? this.name,
      code: code ?? this.code,
      cabinets: cabinets ?? this.cabinets,
      endpoints: endpoints ?? this.endpoints,
      connections: connections ?? this.connections,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schema_version': schemaVersion,
      'project': {
        'name': name,
        'code': code,
      },
      'cabinets': cabinets.map((item) => item.toJson()).toList(),
      'endpoints': endpoints.map((item) => item.toJson()).toList(),
      'connections': connections.map((item) => item.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  Cabinet? findCabinet(String id) {
    for (final cabinet in cabinets) {
      if (cabinet.id == id) {
        return cabinet;
      }
    }
    return null;
  }

  Endpoint? findEndpoint(String id) {
    for (final endpoint in endpoints) {
      if (endpoint.id == id) {
        return endpoint;
      }
    }
    return null;
  }
}

List<Map<String, Object?>> _objects(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList();
}
