import 'dart:io';

import 'package:cable_list_tool/data/project_repository.dart';
import 'package:cable_list_tool/data/xlsx_exporter.dart';
import 'package:cable_list_tool/domain/models/cabinet.dart';
import 'package:cable_list_tool/domain/models/connection.dart';
import 'package:cable_list_tool/domain/models/endpoint.dart';
import 'package:cable_list_tool/domain/models/project.dart';
import 'package:cable_list_tool/domain/models/settings.dart';
import 'package:cable_list_tool/domain/services/label_generator.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves and exports a realistic Flutter field project', () async {
    final project = Project(
      name: 'Sala konferencyjna 4.2',
      code: 'S4.2',
      cabinets: const [
        Cabinet(
            id: 'cab-rsc-1',
            name: 'RSC-1',
            cabinetType: 'Szafa sterująca',
            priority: 1),
      ],
      endpoints: const [
        Endpoint(id: 'end-fb-01', name: 'FB-01', endpointType: 'Floorbox'),
        Endpoint(id: 'end-proj-1', name: 'PROJ-1', endpointType: 'Projektor'),
      ],
      connections: const [
        Connection(
          id: 'conn-eth-1',
          sourceId: 'cab-rsc-1',
          destinationId: 'end-fb-01',
          signalType: 'ETH',
          status: 'Potwierdzone',
        ),
        Connection(
          id: 'conn-audio-1',
          sourceId: 'cab-rsc-1',
          destinationId: 'end-proj-1',
          signalType: 'Audio',
          status: 'Do sprawdzenia',
          notes: 'sprawdzić wejście projektora',
        ),
      ],
      settings: const Settings(
        signalTypes: ['Audio', 'ETH'],
        signalTypeExportNames: {'Audio': 'A'},
        signalTypePriorities: {'Audio': 10, 'ETH': 20},
      ),
    );

    final temp =
        await Directory.systemTemp.createTemp('cable_list_tool_flutter_');
    addTearDown(() => temp.delete(recursive: true));
    final jsonPath = '${temp.path}${Platform.pathSeparator}sala_4_2.json';
    final xlsxPath = '${temp.path}${Platform.pathSeparator}sala_4_2.xlsx';

    final repository = ProjectRepository();
    await repository.save(project, jsonPath);
    final loaded = await repository.load(jsonPath);

    expect(loaded.name, project.name);
    expect(loaded.connections, hasLength(2));
    expect(generateLabels(loaded).map((label) => label.designation), [
      'S4.2-RSC1-PROJ1-A-01',
      'S4.2-RSC1-FB01-ETH-01',
    ]);

    await XlsxExporter().export(loaded, xlsxPath);
    final workbook = Excel.decodeBytes(await File(xlsxPath).readAsBytes());
    final sheet = workbook.tables['Lista kablowa'];

    expect(sheet, isNotNull);
    expect(sheet!.rows, hasLength(3));
    expect(
        sheet.rows[1][0]!.value.toString(), contains('S4.2-RSC1-PROJ1-A-01'));
    expect(
        sheet.rows[2][0]!.value.toString(), contains('S4.2-RSC1-FB01-ETH-01'));
  });
}
