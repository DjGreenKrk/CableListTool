import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/models/project.dart';
import 'project_codec.dart';

class StoredProjectInfo {
  const StoredProjectInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final DateTime updatedAt;
}

class AppProjectStore {
  AppProjectStore({ProjectCodec? codec}) : _codec = codec ?? ProjectCodec();

  final ProjectCodec _codec;

  Future<List<StoredProjectInfo>> listProjects() async {
    final directory = await _projectsDirectory();
    if (!await directory.exists()) {
      return const [];
    }
    final items = <StoredProjectInfo>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }
      try {
        final source = await entity.readAsString();
        final data = jsonDecode(source);
        if (data is! Map) {
          continue;
        }
        final projectData =
            data['project'] is Map ? data['project'] as Map : data;
        final stat = await entity.stat();
        items.add(
          StoredProjectInfo(
            id: _fileStem(entity.path),
            name: projectData['name']?.toString() ?? 'Bez nazwy',
            code: projectData['code']?.toString() ?? '',
            updatedAt: stat.modified,
          ),
        );
      } on Object {
        continue;
      }
    }
    items.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return items;
  }

  Future<Project> loadProject(String id) async {
    final file = await _projectFile(id);
    return _codec.decode(await file.readAsString());
  }

  Future<String> saveProject(Project project, [String? id]) async {
    final cleanId = id?.trim().isNotEmpty == true
        ? _safeId(id!)
        : _safeId('${project.code}_${DateTime.now().microsecondsSinceEpoch}');
    final file = await _projectFile(cleanId);
    await file.writeAsString(_codec.encode(project));
    return cleanId;
  }

  Future<Directory> _projectsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory =
        Directory('${documents.path}${Platform.pathSeparator}projects');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _projectFile(String id) async {
    final directory = await _projectsDirectory();
    return File(
        '${directory.path}${Platform.pathSeparator}${_safeId(id)}.json');
  }
}

String _safeId(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  return cleaned.isEmpty
      ? DateTime.now().microsecondsSinceEpoch.toString()
      : cleaned;
}

String _fileStem(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  return dot == -1 ? name : name.substring(0, dot);
}
