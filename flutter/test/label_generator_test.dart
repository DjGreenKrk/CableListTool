import 'package:cable_list_tool/domain/models/cabinet.dart';
import 'package:cable_list_tool/domain/models/connection.dart';
import 'package:cable_list_tool/domain/models/endpoint.dart';
import 'package:cable_list_tool/domain/models/project.dart';
import 'package:cable_list_tool/domain/models/settings.dart';
import 'package:cable_list_tool/domain/services/label_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates labels and port labels compatible with Python rules', () {
    final project = Project(
      name: 'Sala',
      code: 'SALA',
      cabinets: const [
        Cabinet(id: 'cab-1', name: 'RSC-1', priority: 1),
      ],
      endpoints: const [
        Endpoint(id: 'end-1', name: 'FB-01'),
      ],
      connections: const [
        Connection(
          id: 'con-1',
          sourceId: 'cab-1',
          destinationId: 'end-1',
          signalType: 'Audio',
          status: 'Potwierdzone',
        ),
      ],
      settings: const Settings(
        signalTypes: ['Audio'],
        signalTypeExportNames: {'Audio': 'A'},
        signalTypePriorities: {'Audio': 10},
      ),
    );

    final labels = generateLabels(project);

    expect(labels.single.designation, 'SALA-RSC1-FB01-A-01');
    expect(labels.single.portLabel, 'A-01');
    expect(labels.single.number, '01');
  });

  test('uses unknown destination token', () {
    final project = Project(
      name: 'Sala',
      code: 'SALA',
      cabinets: const [
        Cabinet(id: 'cab-1', name: 'RSC-1', priority: 1),
      ],
      connections: const [
        Connection(
          id: 'con-1',
          sourceId: 'cab-1',
          signalType: 'ETH',
          status: 'Niezidentyfikowany',
        ),
      ],
    );

    final labels = generateLabels(project);

    expect(labels.single.designation, 'SALA-RSC1-NIEZNANE-ETH-01');
    expect(labels.single.destination, 'Nieznane');
  });
}
