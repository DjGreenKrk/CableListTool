import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_repository.dart';
import '../data/xlsx_exporter.dart';
import '../domain/models/cabinet.dart';
import '../domain/models/connection.dart';
import '../domain/models/endpoint.dart';
import '../domain/models/project.dart';
import '../domain/models/settings.dart';
import '../domain/models/cable_label.dart';
import '../domain/services/label_generator.dart';
import '../domain/services/name_sequence.dart';
import '../domain/services/natural_sort.dart';

final projectControllerProvider =
    NotifierProvider<ProjectController, ProjectState>(ProjectController.new);

class ProjectState {
  const ProjectState({
    this.project = const Project(name: 'Nowy projekt', code: 'PROJ'),
    this.currentPath,
    this.isDirty = false,
    this.message = '',
  });

  final Project project;
  final String? currentPath;
  final bool isDirty;
  final String message;

  List<CableLabel> get labels => generateLabels(project);

  ProjectState copyWith({
    Project? project,
    String? currentPath,
    bool clearPath = false,
    bool? isDirty,
    String? message,
  }) {
    return ProjectState(
      project: project ?? this.project,
      currentPath: clearPath ? null : currentPath ?? this.currentPath,
      isDirty: isDirty ?? this.isDirty,
      message: message ?? this.message,
    );
  }
}

class ProjectController extends Notifier<ProjectState> {
  late final ProjectRepository _repository;
  late final XlsxExporter _xlsxExporter;
  var _idCounter = 0;

  @override
  ProjectState build() {
    _repository = ProjectRepository();
    _xlsxExporter = XlsxExporter();
    return const ProjectState();
  }

  void newProject() {
    state = const ProjectState(
      project: Project(name: 'Nowy projekt', code: 'PROJ'),
      isDirty: true,
      message: 'Utworzono nowy projekt.',
    );
  }

  Future<void> openProject(String path) async {
    try {
      final project = await _repository.load(path.trim());
      state = ProjectState(
        project: project,
        currentPath: path.trim(),
        message: 'Otwarto projekt.',
      );
    } on Object catch (error) {
      state = state.copyWith(message: 'Nie udało się otworzyć pliku: $error');
    }
  }

  Future<void> saveProject([String? path]) async {
    final targetPath =
        path?.trim().isNotEmpty == true ? path!.trim() : state.currentPath;
    if (targetPath == null || targetPath.isEmpty) {
      state = state.copyWith(message: 'Podaj ścieżkę pliku JSON.');
      return;
    }
    if (!targetPath.toLowerCase().endsWith('.json')) {
      state = state.copyWith(
          message: 'Plik projektu powinien mieć rozszerzenie .json.');
      return;
    }
    try {
      await _repository.save(state.project, targetPath);
      state = state.copyWith(
        currentPath: targetPath,
        isDirty: false,
        message: 'Zapisano projekt.',
      );
    } on Object catch (error) {
      state = state.copyWith(message: 'Nie udało się zapisać pliku: $error');
    }
  }

  Future<void> exportXlsx(String path) async {
    final targetPath = path.trim();
    if (targetPath.isEmpty) {
      state = state.copyWith(message: 'Podaj ścieżkę pliku XLSX.');
      return;
    }
    if (!targetPath.toLowerCase().endsWith('.xlsx')) {
      state =
          state.copyWith(message: 'Eksport powinien mieć rozszerzenie .xlsx.');
      return;
    }
    try {
      await _xlsxExporter.export(state.project, targetPath);
      state = state.copyWith(message: 'Wyeksportowano XLSX.');
    } on Object catch (error) {
      state =
          state.copyWith(message: 'Nie udało się wyeksportować XLSX: $error');
    }
  }

  void updateProjectInfo(String name, String code) {
    _replaceProject(
        state.project.copyWith(name: name.trim(), code: code.trim()));
  }

  void updateSettings(Settings settings) {
    _replaceProject(state.project.copyWith(settings: settings));
  }

  void addCabinet(Cabinet cabinet) {
    _replaceProject(
      state.project.copyWith(cabinets: [...state.project.cabinets, cabinet]),
    );
  }

  void addCabinets({
    required String baseName,
    required String cabinetType,
    required String location,
    required String description,
    required int priority,
    required int count,
  }) {
    final firstName = baseName.trim().isEmpty
        ? suggestCabinetName(cabinetType)
        : baseName.trim();
    final names = makeSequence(firstName, count);
    _replaceProject(
      state.project.copyWith(
        cabinets: [
          ...state.project.cabinets,
          for (var index = 0; index < names.length; index += 1)
            Cabinet(
              id: newId(),
              name: names[index],
              cabinetType: cabinetType,
              location: location.trim(),
              description: description.trim(),
              priority: priority > 0 ? priority + index : 0,
            ),
        ],
      ),
    );
  }

  void updateCabinet(Cabinet cabinet) {
    _replaceProject(
      state.project.copyWith(
        cabinets: [
          for (final item in state.project.cabinets)
            if (item.id == cabinet.id) cabinet else item,
        ],
      ),
    );
  }

  void deleteCabinet(String id) {
    _replaceProject(
      state.project.copyWith(
        cabinets:
            state.project.cabinets.where((item) => item.id != id).toList(),
        connections: state.project.connections
            .where((item) => item.sourceId != id && item.destinationId != id)
            .toList(),
      ),
    );
  }

  void autoAssignCabinetPriorities() {
    final cabinets = [...state.project.cabinets]..sort((left, right) {
        final numberComparison =
            naturalNumber(left.name).compareTo(naturalNumber(right.name));
        if (numberComparison != 0) {
          return numberComparison;
        }
        return compareNatural(left.name, right.name);
      });
    final priorities = {
      for (var index = 0; index < cabinets.length; index += 1)
        cabinets[index].id: index + 1,
    };
    _replaceProject(
      state.project.copyWith(
        cabinets: [
          for (final cabinet in state.project.cabinets)
            cabinet.copyWith(
                priority: priorities[cabinet.id] ?? cabinet.priority),
        ],
      ),
    );
  }

  void addEndpoint(Endpoint endpoint) {
    _replaceProject(
      state.project.copyWith(endpoints: [...state.project.endpoints, endpoint]),
    );
  }

  void addEndpoints({
    required String baseName,
    required String endpointType,
    required String location,
    required String description,
    required int count,
  }) {
    final firstName = baseName.trim().isEmpty
        ? suggestEndpointName(endpointType)
        : baseName.trim();
    final names = makeSequence(firstName, count);
    _replaceProject(
      state.project.copyWith(
        endpoints: [
          ...state.project.endpoints,
          for (final name in names)
            Endpoint(
              id: newId(),
              name: name,
              endpointType: endpointType,
              location: location.trim(),
              description: description.trim(),
            ),
        ],
      ),
    );
  }

  void updateEndpoint(Endpoint endpoint) {
    _replaceProject(
      state.project.copyWith(
        endpoints: [
          for (final item in state.project.endpoints)
            if (item.id == endpoint.id) endpoint else item,
        ],
      ),
    );
  }

  void deleteEndpoint(String id) {
    _replaceProject(
      state.project.copyWith(
        endpoints:
            state.project.endpoints.where((item) => item.id != id).toList(),
        connections: state.project.connections
            .where((item) => item.sourceId != id && item.destinationId != id)
            .toList(),
      ),
    );
  }

  void addConnection(Connection connection) {
    final nextProject = state.project.copyWith(
      connections: [...state.project.connections, connection],
    );
    _replaceProject(ensureCabinetCableNumbers(nextProject));
  }

  void addConnections(Connection template, int count) {
    final safeCount = count < 1 ? 1 : count;
    final nextProject = state.project.copyWith(
      connections: [
        ...state.project.connections,
        for (var index = 0; index < safeCount; index += 1)
          template.copyWith(id: newId()),
      ],
    );
    _replaceProject(ensureCabinetCableNumbers(nextProject));
  }

  void updateConnection(Connection connection) {
    final nextProject = state.project.copyWith(
      connections: [
        for (final item in state.project.connections)
          if (item.id == connection.id) connection else item,
      ],
    );
    _replaceProject(ensureCabinetCableNumbers(nextProject));
  }

  void deleteConnection(String id) {
    _replaceProject(
      state.project.copyWith(
        connections:
            state.project.connections.where((item) => item.id != id).toList(),
      ),
    );
  }

  void reverseConnection(String id) {
    final connections = [
      for (final item in state.project.connections)
        if (item.id == id)
          item.copyWith(
            sourceId: item.destinationId,
            destinationId: item.sourceId,
          )
        else
          item,
    ];
    _replaceProject(state.project.copyWith(connections: connections));
  }

  bool canMergeUnknownConnections(Set<String> ids) {
    if (ids.length != 2) {
      return false;
    }
    final selected = state.project.connections
        .where((connection) => ids.contains(connection.id))
        .toList();
    if (selected.length != 2) {
      return false;
    }
    return selected.every((connection) => connection.destinationId.isEmpty) &&
        selected[0].signalType == selected[1].signalType &&
        selected[0].sourceId.isNotEmpty &&
        selected[1].sourceId.isNotEmpty &&
        selected[0].sourceId != selected[1].sourceId;
  }

  void mergeUnknownConnections(Set<String> ids) {
    if (!canMergeUnknownConnections(ids)) {
      state = state.copyWith(
        message:
            'Zaznacz dwa przewody z nieznanym końcem, tym samym typem i różnymi źródłami.',
      );
      return;
    }

    final selected = state.project.connections
        .where((connection) => ids.contains(connection.id))
        .toList();
    selected.sort(
        (left, right) => _mergePriority(left).compareTo(_mergePriority(right)));
    final primary = selected[0];
    final secondary = selected[1];
    final merged = primary.copyWith(
      destinationId: secondary.sourceId,
      status: primary.status == 'Niezidentyfikowany'
          ? secondary.status
          : primary.status,
      notes: _mergeNotes(primary.notes, secondary.notes),
      cableNumber: primary.cableNumber ?? secondary.cableNumber,
    );

    final connections = [
      for (final connection in state.project.connections)
        if (connection.id == primary.id)
          merged
        else if (connection.id == secondary.id)
          null
        else
          connection,
    ].whereType<Connection>().toList();
    _replaceProject(state.project.copyWith(connections: connections));
  }

  String suggestCabinetName(String cabinetType) {
    final project = state.project;
    return nextNameForRule(
      project.settings.cabinetNameRules,
      cabinetType,
      'CAB-N',
      project.cabinets.map((item) => item.name).toList(),
    );
  }

  String suggestEndpointName(String endpointType) {
    final project = state.project;
    return nextNameForRule(
      project.settings.endpointNameRules,
      endpointType,
      'P-N',
      project.endpoints.map((item) => item.name).toList(),
    );
  }

  String newId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  int _mergePriority(Connection connection) {
    final cabinet = state.project.findCabinet(connection.sourceId);
    if (cabinet != null) {
      return cabinet.priority == 0
          ? naturalNumber(cabinet.name)
          : cabinet.priority;
    }
    final endpoint = state.project.findEndpoint(connection.sourceId);
    if (endpoint != null) {
      return 1000000 +
          (state.project.settings
                  .endpointTypePriorities[endpoint.endpointType] ??
              999999);
    }
    return 9999999;
  }

  String _mergeNotes(String first, String second) {
    final cleanFirst = first.trim();
    final cleanSecond = second.trim();
    if (cleanFirst.isEmpty) {
      return cleanSecond;
    }
    if (cleanSecond.isEmpty || cleanSecond == cleanFirst) {
      return cleanFirst;
    }
    return '$cleanFirst | $cleanSecond';
  }

  void _replaceProject(Project project) {
    state = state.copyWith(
      project: project,
      isDirty: true,
      message: 'Wprowadzono zmiany.',
    );
  }
}
