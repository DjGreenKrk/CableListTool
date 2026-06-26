import 'package:cable_list_tool/app/project_controller.dart';
import 'package:cable_list_tool/domain/models/cabinet.dart';
import 'package:cable_list_tool/domain/models/connection.dart';
import 'package:cable_list_tool/domain/models/endpoint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto assigns cabinet priorities using natural numbers', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(projectControllerProvider.notifier);

    controller.addCabinet(const Cabinet(id: 'rsc-10', name: 'RSC-10'));
    controller.addCabinet(const Cabinet(id: 'rsc-2', name: 'RSC-2'));
    controller.addCabinet(const Cabinet(id: 'rsc-1', name: 'RSC-1'));

    controller.autoAssignCabinetPriorities();

    final cabinets = container.read(projectControllerProvider).project.cabinets;
    expect(cabinets.firstWhere((item) => item.id == 'rsc-1').priority, 1);
    expect(cabinets.firstWhere((item) => item.id == 'rsc-2').priority, 2);
    expect(cabinets.firstWhere((item) => item.id == 'rsc-10').priority, 3);
  });

  test('merges two unknown connections into one discovered cable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(projectControllerProvider.notifier);

    controller
        .addCabinet(const Cabinet(id: 'cab-1', name: 'RSC-1', priority: 1));
    controller.addEndpoint(const Endpoint(id: 'end-1', name: 'PROJ-1'));
    controller.addConnection(const Connection(
      id: 'con-a',
      sourceId: 'cab-1',
      signalType: 'ETH',
      status: 'Niezidentyfikowany',
      notes: 'strona szafy',
    ));
    controller.addConnection(const Connection(
      id: 'con-b',
      sourceId: 'end-1',
      signalType: 'ETH',
      status: 'Potwierdzone',
      notes: 'strona projektora',
    ));

    controller.mergeUnknownConnections({'con-a', 'con-b'});

    final connections =
        container.read(projectControllerProvider).project.connections;
    expect(connections, hasLength(1));
    expect(connections.single.sourceId, 'cab-1');
    expect(connections.single.destinationId, 'end-1');
    expect(connections.single.status, 'Potwierdzone');
    expect(connections.single.notes, 'strona szafy | strona projektora');
    expect(connections.single.cableNumber, 1);
  });

  test('adds multiple connections from one form submission', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(projectControllerProvider.notifier);

    controller
        .addCabinet(const Cabinet(id: 'cab-1', name: 'RSC-1', priority: 1));
    controller.addConnections(
      const Connection(
        id: 'template',
        sourceId: 'cab-1',
        signalType: 'ETH',
        status: 'Niezidentyfikowany',
      ),
      3,
    );

    final state = container.read(projectControllerProvider);
    expect(state.project.connections, hasLength(3));
    expect(state.labels.map((label) => label.portLabel),
        ['ETH-01', 'ETH-02', 'ETH-03']);
  });

  test('rejects project save path without json extension', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(projectControllerProvider.notifier);

    await controller.saveProject('project.txt');

    expect(
      container.read(projectControllerProvider).message,
      'Plik projektu powinien mieć rozszerzenie .json.',
    );
  });

  test('rejects xlsx export path without xlsx extension', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(projectControllerProvider.notifier);

    await controller.exportXlsx('lista.txt');

    expect(
      container.read(projectControllerProvider).message,
      'Eksport powinien mieć rozszerzenie .xlsx.',
    );
  });
}
