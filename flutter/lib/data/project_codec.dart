import 'dart:convert';

import '../domain/models/project.dart';

class ProjectCodec {
  ProjectCodec({String Function()? newId}) : _newId = newId ?? _defaultId;

  final String Function() _newId;

  Project decode(String source) {
    final data = jsonDecode(source);
    if (data is! Map) {
      throw const FormatException('Project JSON root must be an object.');
    }
    return Project.fromJson(Map<String, Object?>.from(data), _newId);
  }

  String encode(Project project) {
    const encoder = JsonEncoder.withIndent('  ');
    return '${encoder.convert(project.toJson())}\n';
  }
}

String _defaultId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}
