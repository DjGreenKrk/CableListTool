import 'package:cable_list_tool/data/xlsx_exporter.dart';
import 'package:cable_list_tool/domain/models/cabinet.dart';
import 'package:cable_list_tool/domain/models/connection.dart';
import 'package:cable_list_tool/domain/models/endpoint.dart';
import 'package:cable_list_tool/domain/models/project.dart';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds cable list workbook with expected sheet and rows', () {
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
          signalType: 'ETH',
          status: 'Potwierdzone',
        ),
      ],
    );

    final bytes = XlsxExporter().build(project);
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables['Lista kablowa'];

    expect(sheet, isNotNull);
    expect(_rowValues(sheet!.rows[0]), xlsxHeaders);
    expect(_rowValues(sheet.rows[1]).take(7), [
      'SALA-RSC1-FB01-ETH-01',
      'ETH-01',
      'RSC-1',
      'FB-01',
      'ETH',
      '01',
      'Potwierdzone',
    ]);

    final archive = ZipDecoder().decodeBytes(bytes);
    final worksheet = archive.findFile('xl/worksheets/sheet1.xml');
    expect(worksheet, isNotNull);
    final worksheetXml = String.fromCharCodes(worksheet!.content as List<int>);
    expect(worksheetXml, contains('state="frozen"'));
    expect(worksheetXml, contains('<autoFilter ref="A1:H2"/>'));
  });
}

List<String> _rowValues(List<Data?> row) {
  return [
    for (final cell in row)
      switch (cell?.value) {
        TextCellValue(:final value) => value.text ?? '',
        IntCellValue(:final value) => '$value',
        null => '',
        _ => cell!.value.toString(),
      },
  ];
}
