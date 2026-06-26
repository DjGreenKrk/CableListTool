import 'dart:io';

import '../domain/models/project.dart';
import 'project_codec.dart';

class ProjectRepository {
  ProjectRepository({ProjectCodec? codec}) : _codec = codec ?? ProjectCodec();

  final ProjectCodec _codec;

  Future<Project> load(String path) async {
    final source = await File(path).readAsString();
    return _codec.decode(source);
  }

  Future<void> save(Project project, String path) async {
    await File(path).writeAsString(_codec.encode(project));
  }
}
