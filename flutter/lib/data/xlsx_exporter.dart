import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

import '../domain/models/project.dart';
import '../domain/services/label_generator.dart';

const xlsxHeaders = [
  'Oznaczenie',
  'Port',
  'Skąd',
  'Dokąd',
  'Typ',
  'Numer',
  'Status',
  'Uwagi',
];

class XlsxExporter {
  Future<void> export(Project project, String path) async {
    final bytes = build(project);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  List<int> build(Project project) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Lista kablowa');
    excel.setDefaultSheet('Lista kablowa');
    final sheet = excel['Lista kablowa'];
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FFEEF8FF'),
      backgroundColorHex: ExcelColor.fromHexString('FF2B5C79'),
    );

    sheet.appendRow(_textRow(xlsxHeaders));
    for (var index = 0; index < xlsxHeaders.length; index += 1) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    final columnWidths = xlsxHeaders.map((header) => header.length).toList();
    for (final label in generateLabels(project)) {
      final row = [
        label.designation,
        label.portLabel,
        label.source,
        label.destination,
        label.exportSignalType,
        label.number,
        label.status,
        label.notes,
      ];
      sheet.appendRow(_textRow(row));
      for (var index = 0; index < row.length; index += 1) {
        if (row[index].length > columnWidths[index]) {
          columnWidths[index] = row[index].length;
        }
      }
    }

    for (var index = 0; index < columnWidths.length; index += 1) {
      final width = (columnWidths[index] + 2).clamp(10, 60).toDouble();
      sheet.setColumnWidth(index, width);
    }

    final bytes = excel.save(fileName: 'lista_kablowa.xlsx');
    if (bytes == null) {
      throw StateError('Nie udało się zbudować pliku XLSX.');
    }
    return _withWorksheetViewOptions(bytes,
        rowCount: generateLabels(project).length + 1);
  }
}

List<CellValue> _textRow(List<String> values) {
  return [for (final value in values) TextCellValue(value)];
}

List<int> _withWorksheetViewOptions(List<int> bytes, {required int rowCount}) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final sheet = archive.findFile('xl/worksheets/sheet1.xml');
  if (sheet == null) {
    return bytes;
  }

  final original = utf8.decode(sheet.content as List<int>);
  final withFrozenHeader = _ensureFrozenHeader(original);
  final withFilter = _ensureAutoFilter(withFrozenHeader, rowCount: rowCount);
  final updatedContent = utf8.encode(withFilter);
  final updatedSheet =
      ArchiveFile(sheet.name, updatedContent.length, updatedContent)
        ..mode = sheet.mode
        ..ownerId = sheet.ownerId
        ..groupId = sheet.groupId
        ..lastModTime = sheet.lastModTime
        ..comment = sheet.comment
        ..compress = sheet.compress;
  archive.addFile(updatedSheet);

  return ZipEncoder().encode(archive) ?? bytes;
}

String _ensureFrozenHeader(String xml) {
  if (xml.contains('<pane ')) {
    return xml;
  }
  const pane =
      '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>';
  final emptySheetView = RegExp(r'<sheetView([^>]*)/>').firstMatch(xml);
  if (emptySheetView != null) {
    final attributes = emptySheetView.group(1) ?? '';
    return xml.replaceRange(
      emptySheetView.start,
      emptySheetView.end,
      '<sheetView$attributes>$pane</sheetView>',
    );
  }
  final sheetViewStart = RegExp(r'<sheetView[^>]*>').firstMatch(xml);
  if (sheetViewStart != null) {
    return xml.replaceRange(sheetViewStart.end, sheetViewStart.end, pane);
  }
  const sheetViews =
      '<sheetViews><sheetView workbookViewId="0">$pane</sheetView></sheetViews>';
  final insertAfter = RegExp(r'<sheetPr[^>]*/>|<sheetPr[\s\S]*?</sheetPr>');
  final match = insertAfter.firstMatch(xml);
  if (match != null) {
    return xml.replaceRange(match.end, match.end, sheetViews);
  }
  final worksheetStart = RegExp(r'<worksheet[^>]*>').firstMatch(xml);
  if (worksheetStart == null) {
    return xml;
  }
  return xml.replaceRange(worksheetStart.end, worksheetStart.end, sheetViews);
}

String _ensureAutoFilter(String xml, {required int rowCount}) {
  if (xml.contains('<autoFilter ')) {
    return xml;
  }
  final lastRow = rowCount < 1 ? 1 : rowCount;
  final filter = '<autoFilter ref="A1:H$lastRow"/>';
  final sheetDataEnd = xml.indexOf('</sheetData>');
  if (sheetDataEnd == -1) {
    return xml;
  }
  final insertAt = sheetDataEnd + '</sheetData>'.length;
  return xml.replaceRange(insertAt, insertAt, filter);
}
