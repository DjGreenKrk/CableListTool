import '../models/cabinet.dart';
import '../models/cable_label.dart';
import '../models/connection.dart';
import '../models/endpoint.dart';
import '../models/project.dart';
import 'natural_sort.dart';

const unknownDestinationName = 'Nieznane';
const unknownDestinationToken = 'NIEZNANE';

final _tokenNoise = RegExp(r'[-\s]+');

String sanitizeToken(String value) {
  return value.trim().replaceAll(_tokenNoise, '');
}

List<CableLabel> generateLabels(Project project) {
  final workingProject = ensureCabinetCableNumbers(project);
  final labels = <CableLabel>[];
  final connectionsByType = <String, List<Connection>>{};

  for (final connection in workingProject.connections) {
    connectionsByType
        .putIfAbsent(connection.signalType, () => [])
        .add(connection);
  }

  final signalTypes = connectionsByType.keys.toList()
    ..sort((a, b) => _compareSignalTypes(workingProject, a, b));
  for (final signalType in signalTypes) {
    final connections = connectionsByType[signalType]!
      ..sort((a, b) => _compareConnections(workingProject, a, b));
    final maxFixed = connections.fold<int>(0, (current, item) {
      final number = item.cableNumber ?? 0;
      return number > current ? number : current;
    });
    final total = connections.fold<int>(0,
        (current, item) => current + (item.quantity < 1 ? 1 : item.quantity));
    final width = _max(2, _max(total, maxFixed).toString().length);
    var counter = 1;

    for (final connection in connections) {
      final quantity = connection.quantity < 1 ? 1 : connection.quantity;
      for (var cableIndex = 1; cableIndex <= quantity; cableIndex += 1) {
        int numericNumber;
        if (connection.cableNumber != null) {
          numericNumber = connection.cableNumber!;
        } else {
          while (_numberIsUsed(connections, counter)) {
            counter += 1;
          }
          numericNumber = counter;
        }

        final number = numericNumber.toString().padLeft(width, '0');
        final source = _objectName(workingProject, connection.sourceId);
        final destination = _objectName(
            workingProject, connection.destinationId, unknownDestinationName);
        final destinationToken = connection.destinationId.isEmpty
            ? unknownDestinationToken
            : sanitizeToken(destination);
        final exportSignalType =
            _signalTypeExportName(workingProject, connection.signalType);
        final portLabel = '${sanitizeToken(exportSignalType)}-$number';
        final designation = [
          sanitizeToken(workingProject.code),
          sanitizeToken(source),
          destinationToken,
          portLabel,
        ].join('-');

        labels.add(
          CableLabel(
            connectionId: connection.id,
            cableIndex: cableIndex,
            designation: designation,
            project: workingProject.name,
            source: source,
            destination: destination,
            signalType: connection.signalType,
            exportSignalType: exportSignalType,
            portLabel: portLabel,
            number: number,
            status:
                connection.cableStatuses['$cableIndex'] ?? connection.status,
            notes: connection.notes,
          ),
        );
        counter = _max(counter, numericNumber + 1);
      }
    }
  }

  return labels;
}

Project ensureCabinetCableNumbers(Project project) {
  final usedByType = <String, Set<int>>{};
  final nextConnections = List<Connection>.of(project.connections);
  for (final connection in nextConnections) {
    if (_cabinetsForConnection(project, connection).isNotEmpty &&
        connection.cableNumber != null) {
      usedByType
          .putIfAbsent(connection.signalType, () => <int>{})
          .add(connection.cableNumber!);
    }
  }

  final types = nextConnections.map((item) => item.signalType).toSet();
  for (final type in types) {
    final indexes = <int>[];
    for (var index = 0; index < nextConnections.length; index += 1) {
      final connection = nextConnections[index];
      if (connection.signalType == type &&
          _cabinetsForConnection(project, connection).isNotEmpty) {
        indexes.add(index);
      }
    }
    indexes.sort((a, b) =>
        _compareConnections(project, nextConnections[a], nextConnections[b]));
    final used = usedByType.putIfAbsent(type, () => <int>{});
    var nextNumber = 1;
    for (final index in indexes) {
      final connection = nextConnections[index];
      if (connection.cableNumber != null) {
        continue;
      }
      while (used.contains(nextNumber)) {
        nextNumber += 1;
      }
      nextConnections[index] = connection.copyWith(cableNumber: nextNumber);
      used.add(nextNumber);
    }
  }

  return project.copyWith(connections: nextConnections);
}

bool _numberIsUsed(List<Connection> connections, int number) {
  return connections.any((connection) => connection.cableNumber == number);
}

int _compareSignalTypes(Project project, String left, String right) {
  final leftPriority = project.settings.signalTypePriorities[left] ?? 999999;
  final rightPriority = project.settings.signalTypePriorities[right] ?? 999999;
  final priorityComparison = leftPriority.compareTo(rightPriority);
  if (priorityComparison != 0) {
    return priorityComparison;
  }
  return compareNatural(left, right);
}

int _compareConnections(Project project, Connection left, Connection right) {
  final leftKey = _connectionSortKey(project, left);
  final rightKey = _connectionSortKey(project, right);
  final maxLength =
      leftKey.length > rightKey.length ? leftKey.length : rightKey.length;
  for (var index = 0; index < maxLength; index += 1) {
    if (index >= leftKey.length) {
      return -1;
    }
    if (index >= rightKey.length) {
      return 1;
    }
    final comparison = _compareSortPart(leftKey[index], rightKey[index]);
    if (comparison != 0) {
      return comparison;
    }
  }
  return 0;
}

List<Object> _connectionSortKey(Project project, Connection connection) {
  final cabinets = _cabinetsForConnection(project, connection);
  if (cabinets.isNotEmpty) {
    cabinets.sort((a, b) {
      final priorityComparison =
          (a.priority == 0 ? naturalNumber(a.name) : a.priority)
              .compareTo(b.priority == 0 ? naturalNumber(b.name) : b.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      return compareNatural(a.name, b.name);
    });
    final best = cabinets.first;
    return [
      0,
      best.priority == 0 ? naturalNumber(best.name) : best.priority,
      ...naturalKey(best.name),
      connection.cableNumber ?? 999999,
      _endpointPriorityKey(project, connection),
      ..._endpointKey(project, connection),
      connection.id,
    ];
  }
  return [
    1,
    999999,
    _endpointPriorityKey(project, connection),
    ..._endpointKey(project, connection),
    connection.id,
  ];
}

int _compareSortPart(Object left, Object right) {
  if (left is int && right is int) {
    return left.compareTo(right);
  }
  return left.toString().compareTo(right.toString());
}

List<Cabinet> _cabinetsForConnection(Project project, Connection connection) {
  return [
    project.findCabinet(connection.sourceId),
    project.findCabinet(connection.destinationId),
  ].whereType<Cabinet>().toList();
}

List<Endpoint> _endpointsForConnection(Project project, Connection connection) {
  return [
    project.findEndpoint(connection.sourceId),
    project.findEndpoint(connection.destinationId),
  ].whereType<Endpoint>().toList();
}

List<Object> _endpointKey(Project project, Connection connection) {
  final endpoints = _endpointsForConnection(project, connection);
  if (endpoints.isNotEmpty) {
    endpoints.sort((a, b) => compareNatural(a.name, b.name));
    return naturalKey(endpoints.first.name);
  }
  final names = [
    _objectName(project, connection.sourceId),
    _objectName(project, connection.destinationId),
  ].where((name) => name.isNotEmpty).toList()
    ..sort(compareNatural);
  return names.isEmpty ? const [] : naturalKey(names.first);
}

int _endpointPriorityKey(Project project, Connection connection) {
  final endpoints = _endpointsForConnection(project, connection);
  if (endpoints.isEmpty) {
    return 999999;
  }
  return endpoints
      .map((endpoint) =>
          project.settings.endpointTypePriorities[endpoint.endpointType] ??
          999999)
      .reduce((left, right) => left < right ? left : right);
}

String _signalTypeExportName(Project project, String signalType) {
  return project.settings.signalTypeExportNames[signalType] ?? signalType;
}

String _objectName(Project project, String id, [String missing = '']) {
  if (id.isEmpty) {
    return missing;
  }
  return project.findCabinet(id)?.name ??
      project.findEndpoint(id)?.name ??
      missing;
}

int _max(int left, int right) => left > right ? left : right;
