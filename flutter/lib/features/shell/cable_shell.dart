import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/project_controller.dart';
import '../../domain/models/cabinet.dart';
import '../../domain/models/connection.dart';
import '../../domain/models/endpoint.dart';
import '../../domain/models/settings.dart';
import '../../domain/services/label_generator.dart';
import '../../domain/services/natural_sort.dart';
import '../../domain/services/settings_text_codec.dart';

class CableShell extends ConsumerStatefulWidget {
  const CableShell({super.key});

  @override
  ConsumerState<CableShell> createState() => _CableShellState();
}

class _CableShellState extends ConsumerState<CableShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectControllerProvider);
    final pages = [
      const ProjectPage(),
      const CabinetsPage(),
      const EndpointsPage(),
      const ConnectionsPage(),
      const ExportPage(),
    ];

    final compact = MediaQuery.sizeOf(context).width < 700;
    if (compact) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(state: state),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: 'Projekt',
            ),
            NavigationDestination(
              icon: Icon(Icons.dns_outlined),
              label: 'Szafy',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_input_component_outlined),
              label: 'Punkty',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              label: 'Kable',
            ),
            NavigationDestination(
              icon: Icon(Icons.file_download_outlined),
              label: 'Eksport',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 20),
                child: Icon(Icons.cable),
              ),
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.description_outlined),
                    label: Text('Projekt')),
                NavigationRailDestination(
                    icon: Icon(Icons.dns_outlined), label: Text('Szafy')),
                NavigationRailDestination(
                    icon: Icon(Icons.settings_input_component_outlined),
                    label: Text('Punkty')),
                NavigationRailDestination(
                    icon: Icon(Icons.route_outlined),
                    label: Text('Połączenia')),
                NavigationRailDestination(
                    icon: Icon(Icons.file_download_outlined),
                    label: Text('Eksport')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(state: state),
                  Expanded(child: pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final ProjectState state;

  @override
  Widget build(BuildContext context) {
    final project = state.project;
    final title = project.name.trim().isEmpty ? 'Bez nazwy' : project.name;
    final code = project.code.trim().isEmpty ? 'bez kodu' : project.code;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          return Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      code,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (state.message.isNotEmpty && !compact) ...[
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    state.message,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'O aplikacji',
                onPressed: () => _showAboutApp(context),
                icon: const Icon(Icons.info_outline),
              ),
              const SizedBox(width: 8),
              compact
                  ? _DirtyIcon(isDirty: state.isDirty)
                  : _DirtyBadge(isDirty: state.isDirty),
            ],
          );
        },
      ),
    );
  }
}

void _showAboutApp(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'CableListTool',
    applicationVersion: '0.1.0',
    applicationLegalese: '© Julian Szymański / GreenCrew\nMIT',
    children: const [
      SizedBox(height: 12),
      Text(
          'Narzędzie do inwentaryzacji, oznaczania i dokumentowania okablowania.'),
      SizedBox(height: 8),
      Text('Część ekosystemu GreenCrew Tools.'),
      SizedBox(height: 8),
      Text('greencrew.pl'),
    ],
  );
}

class _DirtyBadge extends StatelessWidget {
  const _DirtyBadge({required this.isDirty});

  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDirty ? const Color(0xFF5B4524) : const Color(0xFF173821),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(isDirty ? 'Niezapisane' : 'Zapisane'),
      ),
    );
  }
}

class _DirtyIcon extends StatelessWidget {
  const _DirtyIcon({required this.isDirty});

  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDirty ? 'Niezapisane' : 'Zapisane',
      child: Icon(
        isDirty ? Icons.edit_note : Icons.check_circle_outline,
        color: isDirty
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class ProjectPage extends ConsumerStatefulWidget {
  const ProjectPage({super.key});

  @override
  ConsumerState<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends ConsumerState<ProjectPage> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _path = TextEditingController();
  final _cabinetRules = TextEditingController();
  final _endpointRules = TextEditingController();
  final _signalTypes = TextEditingController();
  final _statuses = TextEditingController();
  var _loadedProjectSignature = '';

  static const _jsonTypeGroup = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
  );

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _path.dispose();
    _cabinetRules.dispose();
    _endpointRules.dispose();
    _signalTypes.dispose();
    _statuses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectControllerProvider);
    final project = state.project;
    final signature =
        '${project.name}|${project.code}|${state.currentPath ?? ''}|${project.settings.toJson()}';
    if (signature != _loadedProjectSignature) {
      _loadedProjectSignature = signature;
      _name.text = project.name;
      _code.text = project.code;
      _path.text = state.currentPath ?? _path.text;
      _cabinetRules.text = formatTypeRules(
        project.settings.cabinetTypes,
        project.settings.cabinetNameRules,
      );
      _endpointRules.text = formatTypeRules(
        project.settings.endpointTypes,
        project.settings.endpointNameRules,
        project.settings.endpointTypePriorities,
      );
      _signalTypes.text = formatTypeRules(
        project.settings.signalTypes,
        project.settings.signalTypeExportNames,
        project.settings.signalTypePriorities,
      );
      _statuses.text = project.settings.statuses.join('\n');
    }

    return _PageFrame(
      title: 'Projekt',
      actions: [
        IconButton(
          tooltip: 'Nowy projekt',
          onPressed: () =>
              ref.read(projectControllerProvider.notifier).newProject(),
          icon: const Icon(Icons.note_add_outlined),
        ),
        IconButton(
          tooltip: 'Zapisz',
          onPressed: () => _saveJsonWithConfirmation(context),
          icon: const Icon(Icons.save_outlined),
        ),
        IconButton(
          tooltip: 'Zapisz jako',
          onPressed: () => _saveJsonAs(context),
          icon: const Icon(Icons.save_as_outlined),
        ),
        IconButton(
          tooltip: 'Otwórz',
          onPressed: () => _openJsonWithPicker(),
          icon: const Icon(Icons.folder_open_outlined),
        ),
      ],
      child: ListView(
        children: [
          _Panel(
            child: Column(
              children: [
                _TextField(label: 'Nazwa projektu', controller: _name),
                const SizedBox(height: 12),
                _TextField(label: 'Kod projektu', controller: _code),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => ref
                        .read(projectControllerProvider.notifier)
                        .updateProjectInfo(_name.text, _code.text),
                    icon: const Icon(Icons.check),
                    label: const Text('Zastosuj'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Słowniki i reguły nazw'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;
                    final editors = [
                      _TextField(
                        label: 'Typy i nazwy szaf',
                        controller: _cabinetRules,
                        hint: 'Szafa sterująca=RSC-N',
                        maxLines: 7,
                      ),
                      _TextField(
                        label: 'Typy i nazwy punktów',
                        controller: _endpointRules,
                        hint: 'Floorbox=FB-NN|30',
                        maxLines: 7,
                      ),
                      _TextField(
                        label: 'Typy sygnałów',
                        controller: _signalTypes,
                        hint: 'Audio=A|10',
                        maxLines: 7,
                      ),
                      _TextField(
                        label: 'Statusy',
                        controller: _statuses,
                        hint: 'Do sprawdzenia',
                        maxLines: 7,
                      ),
                    ];
                    if (compact) {
                      return _MobileSettingsEditorList(
                        cabinetRules: _cabinetRules,
                        endpointRules: _endpointRules,
                        signalTypes: _signalTypes,
                        statuses: _statuses,
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final editor in editors) ...[
                          Expanded(child: editor),
                          if (editor != editors.last) const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      final settings = settingsFromText(
                        cabinetRules: _cabinetRules.text,
                        endpointRules: _endpointRules.text,
                        signalTypes: _signalTypes.text,
                        statuses: _statuses.text,
                      );
                      ref
                          .read(projectControllerProvider.notifier)
                          .updateSettings(settings);
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Zastosuj słowniki'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plik JSON'),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Ścieżka',
                  controller: _path,
                  hint: r'C:\projekty\sala.json',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openJsonWithPicker(),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Otwórz JSON'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _saveJsonWithConfirmation(context),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Zapisz JSON'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _saveJsonAs(context),
                      icon: const Icon(Icons.save_as_outlined),
                      label: const Text('Zapisz jako'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SummaryStrip(
            items: [
              ('Szafy', '${project.cabinets.length}'),
              ('Punkty', '${project.endpoints.length}'),
              ('Przewody', '${project.connections.length}'),
              ('Oznaczenia', '${state.labels.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveJsonWithConfirmation(BuildContext context) async {
    final path = _path.text.trim();
    if (path.isNotEmpty &&
        path != ref.read(projectControllerProvider).currentPath &&
        await File(path).exists() &&
        context.mounted) {
      final overwrite = await _confirmOverwrite(context, path);
      if (!overwrite) {
        return;
      }
    }
    await ref.read(projectControllerProvider.notifier).saveProject(path);
  }

  Future<void> _openJsonWithPicker() async {
    final file = await openFile(acceptedTypeGroups: const [_jsonTypeGroup]);
    if (file == null) {
      return;
    }
    _path.text = file.path;
    await ref.read(projectControllerProvider.notifier).openProject(file.path);
  }

  Future<void> _saveJsonAs(BuildContext context) async {
    final state = ref.read(projectControllerProvider);
    final suggestedName = _ensureExtension(
      state.currentPath == null
          ? '${_safeFileStem(state.project.code.isEmpty ? 'projekt' : state.project.code)}.json'
          : _fileName(state.currentPath!),
      'json',
    );
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_jsonTypeGroup],
      suggestedName: suggestedName,
    );
    if (location == null) {
      return;
    }
    _path.text = _ensureExtension(location.path, 'json');
    if (context.mounted) {
      await _saveJsonWithConfirmation(context);
    }
  }
}

class CabinetsPage extends ConsumerStatefulWidget {
  const CabinetsPage({super.key});

  @override
  ConsumerState<CabinetsPage> createState() => _CabinetsPageState();
}

class _CabinetsPageState extends ConsumerState<CabinetsPage> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _priority = TextEditingController(text: '0');
  final _count = TextEditingController(text: '1');
  String? _selectedId;
  String _type = defaultCabinetTypes.first;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _priority.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectControllerProvider);
    final project = state.project;
    final controller = ref.read(projectControllerProvider.notifier);
    final cabinets = [...project.cabinets]
      ..sort((left, right) => compareNatural(left.name, right.name));

    return _PageFrame(
      title: 'Szafy',
      actions: [
        IconButton(
          tooltip: 'Przelicz priorytety',
          onPressed: project.cabinets.isEmpty
              ? null
              : () => controller.autoAssignCabinetPriorities(),
          icon: const Icon(Icons.format_list_numbered),
        ),
        IconButton(
          tooltip: 'Wyczyść formularz',
          onPressed: _clear,
          icon: const Icon(Icons.add),
        ),
      ],
      child: _TableAndForm(
        table: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Nazwa')),
            DataColumn(label: Text('Typ')),
            DataColumn(label: Text('Lokalizacja')),
            DataColumn(label: Text('Priorytet')),
          ],
          rows: [
            for (final cabinet in cabinets)
              DataRow(
                selected: cabinet.id == _selectedId,
                onSelectChanged: (_) => _load(cabinet),
                cells: [
                  DataCell(Text(cabinet.name)),
                  DataCell(Text(cabinet.cabinetType)),
                  DataCell(Text(cabinet.location)),
                  DataCell(Text('${cabinet.priority}')),
                ],
              ),
          ],
        ),
        mobileList: _RecordList(
          emptyText: 'Brak szaf',
          children: [
            for (final cabinet in cabinets)
              _RecordCard(
                selected: cabinet.id == _selectedId,
                title: cabinet.name,
                subtitle: cabinet.cabinetType,
                details: [
                  ('Lokalizacja', cabinet.location),
                  ('Priorytet', '${cabinet.priority}'),
                ],
                onTap: () => _load(cabinet),
              ),
          ],
        ),
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormTitle(
                text: _selectedId == null ? 'Nowa szafa' : 'Edycja szafy'),
            _TextField(label: 'Nazwa', controller: _name),
            const SizedBox(height: 12),
            _Dropdown(
              label: 'Typ',
              value: _type,
              values: project.settings.cabinetTypes,
              onChanged: (value) => setState(() {
                _type = value;
                if (_selectedId == null && _name.text.trim().isEmpty) {
                  _name.text = controller.suggestCabinetName(value);
                }
              }),
            ),
            const SizedBox(height: 12),
            _TextField(label: 'Lokalizacja', controller: _location),
            const SizedBox(height: 12),
            _TextField(label: 'Opis', controller: _description, maxLines: 3),
            const SizedBox(height: 12),
            _TextField(
                label: 'Priorytet',
                controller: _priority,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _TextField(
              label: 'Ilość nowych',
              controller: _count,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (_selectedId == null) {
                  controller.addCabinets(
                    baseName: _name.text,
                    cabinetType: _type,
                    location: _location.text,
                    description: _description.text,
                    priority: int.tryParse(_priority.text) ?? 0,
                    count: int.tryParse(_count.text) ?? 1,
                  );
                  _prepareNextCabinet(controller);
                } else {
                  final item = Cabinet(
                    id: _selectedId!,
                    name: _name.text.trim(),
                    cabinetType: _type,
                    location: _location.text.trim(),
                    description: _description.text.trim(),
                    priority: int.tryParse(_priority.text) ?? 0,
                  );
                  controller.updateCabinet(item);
                  _clear();
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectedId == null
                  ? null
                  : () {
                      controller.deleteCabinet(_selectedId!);
                      _clear();
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Usuń'),
            ),
          ],
        ),
      ),
    );
  }

  void _load(Cabinet cabinet) {
    if (_selectedId == cabinet.id) {
      _clear();
      return;
    }
    setState(() {
      _selectedId = cabinet.id;
      _name.text = cabinet.name;
      _type = cabinet.cabinetType;
      _location.text = cabinet.location;
      _description.text = cabinet.description;
      _priority.text = '${cabinet.priority}';
      _count.text = '1';
    });
  }

  void _clear() {
    setState(() {
      _selectedId = null;
      _name.clear();
      _location.clear();
      _description.clear();
      _priority.text = '0';
      _count.text = '1';
      _type = defaultCabinetTypes.first;
    });
  }

  void _prepareNextCabinet(ProjectController controller) {
    setState(() {
      _selectedId = null;
      _name.text = controller.suggestCabinetName(_type);
      _description.clear();
      _priority.text = '0';
      _count.text = '1';
    });
  }
}

class EndpointsPage extends ConsumerStatefulWidget {
  const EndpointsPage({super.key});

  @override
  ConsumerState<EndpointsPage> createState() => _EndpointsPageState();
}

class _EndpointsPageState extends ConsumerState<EndpointsPage> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _count = TextEditingController(text: '1');
  String? _selectedId;
  String _type = defaultEndpointTypes.first;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectControllerProvider);
    final project = state.project;
    final controller = ref.read(projectControllerProvider.notifier);
    final endpoints = [...project.endpoints]
      ..sort((left, right) => compareNatural(left.name, right.name));

    return _PageFrame(
      title: 'Punkty',
      actions: [
        IconButton(
            tooltip: 'Wyczyść formularz',
            onPressed: _clear,
            icon: const Icon(Icons.add)),
      ],
      child: _TableAndForm(
        table: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Nazwa')),
            DataColumn(label: Text('Typ')),
            DataColumn(label: Text('Lokalizacja')),
          ],
          rows: [
            for (final endpoint in endpoints)
              DataRow(
                selected: endpoint.id == _selectedId,
                onSelectChanged: (_) => _load(endpoint),
                cells: [
                  DataCell(Text(endpoint.name)),
                  DataCell(Text(endpoint.endpointType)),
                  DataCell(Text(endpoint.location)),
                ],
              ),
          ],
        ),
        mobileList: _RecordList(
          emptyText: 'Brak punktow',
          children: [
            for (final endpoint in endpoints)
              _RecordCard(
                selected: endpoint.id == _selectedId,
                title: endpoint.name,
                subtitle: endpoint.endpointType,
                details: [('Lokalizacja', endpoint.location)],
                onTap: () => _load(endpoint),
              ),
          ],
        ),
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormTitle(
                text: _selectedId == null ? 'Nowy punkt' : 'Edycja punktu'),
            _TextField(label: 'Nazwa', controller: _name),
            const SizedBox(height: 12),
            _Dropdown(
              label: 'Typ',
              value: _type,
              values: project.settings.endpointTypes,
              onChanged: (value) => setState(() {
                _type = value;
                if (_selectedId == null && _name.text.trim().isEmpty) {
                  _name.text = controller.suggestEndpointName(value);
                }
              }),
            ),
            const SizedBox(height: 12),
            _TextField(label: 'Lokalizacja', controller: _location),
            const SizedBox(height: 12),
            _TextField(label: 'Opis', controller: _description, maxLines: 3),
            const SizedBox(height: 12),
            _TextField(
              label: 'Ilość nowych',
              controller: _count,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (_selectedId == null) {
                  controller.addEndpoints(
                    baseName: _name.text,
                    endpointType: _type,
                    location: _location.text,
                    description: _description.text,
                    count: int.tryParse(_count.text) ?? 1,
                  );
                  _prepareNextEndpoint(controller);
                } else {
                  final item = Endpoint(
                    id: _selectedId!,
                    name: _name.text.trim(),
                    endpointType: _type,
                    location: _location.text.trim(),
                    description: _description.text.trim(),
                  );
                  controller.updateEndpoint(item);
                  _clear();
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectedId == null
                  ? null
                  : () {
                      controller.deleteEndpoint(_selectedId!);
                      _clear();
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Usuń'),
            ),
          ],
        ),
      ),
    );
  }

  void _load(Endpoint endpoint) {
    if (_selectedId == endpoint.id) {
      _clear();
      return;
    }
    setState(() {
      _selectedId = endpoint.id;
      _name.text = endpoint.name;
      _type = endpoint.endpointType;
      _location.text = endpoint.location;
      _description.text = endpoint.description;
      _count.text = '1';
    });
  }

  void _clear() {
    setState(() {
      _selectedId = null;
      _name.clear();
      _location.clear();
      _description.clear();
      _count.text = '1';
      _type = defaultEndpointTypes.first;
    });
  }

  void _prepareNextEndpoint(ProjectController controller) {
    setState(() {
      _selectedId = null;
      _name.text = controller.suggestEndpointName(_type);
      _description.clear();
      _count.text = '1';
    });
  }
}

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  final _notes = TextEditingController();
  final _count = TextEditingController(text: '1');
  String? _selectedId;
  final Set<String> _mergeSelection = {};
  String _sourceId = '';
  String _destinationId = '';
  String _signalType = defaultSignalTypes.first;
  String _status = defaultStatuses.first;

  @override
  void dispose() {
    _notes.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectControllerProvider);
    final project = state.project;
    final labelsByConnection = {
      for (final label in state.labels) label.connectionId: label,
    };
    final selectedConnection =
        project.connections.where((item) => item.id == _selectedId).firstOrNull;
    final controller = ref.read(projectControllerProvider.notifier);
    final objectOptions = [
      for (final cabinet in project.cabinets)
        _ObjectOption(cabinet.id, cabinet.name, 'Szafa'),
      for (final endpoint in project.endpoints)
        _ObjectOption(endpoint.id, endpoint.name, 'Punkt'),
    ]..sort((left, right) {
        final kindComparison = left.kind.compareTo(right.kind);
        if (kindComparison != 0) {
          return kindComparison;
        }
        return compareNatural(left.name, right.name);
      });
    final connections = [...project.connections]..sort((left, right) {
        final leftLabel = labelsByConnection[left.id]?.designation ?? '';
        final rightLabel = labelsByConnection[right.id]?.designation ?? '';
        return compareNatural(leftLabel, rightLabel);
      });

    return _PageFrame(
      title: 'Połączenia',
      actions: [
        IconButton(
          tooltip: 'Połącz zaznaczone przewody',
          onPressed: controller.canMergeUnknownConnections(_mergeSelection)
              ? () {
                  controller.mergeUnknownConnections(_mergeSelection);
                  _clear();
                }
              : null,
          icon: const Icon(Icons.call_merge),
        ),
        IconButton(
            tooltip: 'Wyczyść formularz',
            onPressed: _clear,
            icon: const Icon(Icons.add)),
      ],
      child: _TableAndForm(
        table: DataTable(
          showCheckboxColumn: true,
          columns: const [
            DataColumn(label: Text('Oznaczenie')),
            DataColumn(label: Text('Port')),
            DataColumn(label: Text('Skąd')),
            DataColumn(label: Text('Dokąd')),
            DataColumn(label: Text('Typ')),
            DataColumn(label: Text('Status')),
          ],
          rows: [
            for (final connection in connections)
              DataRow(
                selected: _mergeSelection.contains(connection.id),
                onSelectChanged: (_) => _toggleMergeSelection(connection.id),
                cells: [
                  DataCell(
                    Text(labelsByConnection[connection.id]?.designation ?? ''),
                    onTap: () => _load(connection),
                  ),
                  DataCell(
                    Text(labelsByConnection[connection.id]?.portLabel ?? ''),
                    onTap: () => _load(connection),
                  ),
                  DataCell(
                    Text(_objectName(project, connection.sourceId)),
                    onTap: () => _load(connection),
                  ),
                  DataCell(
                      Text(_objectName(project, connection.destinationId,
                          unknownDestinationName)),
                      onTap: () => _load(connection)),
                  DataCell(Text(connection.signalType),
                      onTap: () => _load(connection)),
                  DataCell(Text(connection.status),
                      onTap: () => _load(connection)),
                ],
              ),
          ],
        ),
        mobileList: _RecordList(
          emptyText: 'Brak przewodow',
          children: [
            for (final connection in connections)
              _RecordCard(
                selected: _mergeSelection.contains(connection.id) ||
                    connection.id == _selectedId,
                title: labelsByConnection[connection.id]?.designation ??
                    'Bez oznaczenia',
                subtitle:
                    '${_objectName(project, connection.sourceId)} -> ${_objectName(project, connection.destinationId, unknownDestinationName)}',
                details: [
                  (
                    'Port',
                    labelsByConnection[connection.id]?.portLabel ?? '',
                  ),
                  ('Typ', connection.signalType),
                  ('Status', connection.status),
                ],
                onTap: () => _load(connection),
                onLongPress: () => _toggleMergeSelection(connection.id),
              ),
          ],
        ),
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormTitle(
                text: _selectedId == null ? 'Nowy przewód' : 'Edycja przewodu'),
            _ObjectDropdown(
              label: 'Skąd',
              value: _sourceId,
              values: objectOptions,
              allowUnknown: false,
              onChanged: (value) => setState(() {
                _sourceId = value;
                if (_destinationId == value) {
                  _destinationId = '';
                }
              }),
            ),
            const SizedBox(height: 12),
            _ObjectDropdown(
              label: 'Dokąd',
              value: _destinationId,
              values:
                  objectOptions.where((item) => item.id != _sourceId).toList(),
              allowUnknown: true,
              onChanged: (value) => setState(() => _destinationId = value),
            ),
            const SizedBox(height: 12),
            _Dropdown(
              label: 'Typ sygnału',
              value: _signalType,
              values: project.settings.signalTypes,
              onChanged: (value) => setState(() => _signalType = value),
            ),
            const SizedBox(height: 12),
            _Dropdown(
              label: 'Status',
              value: _status,
              values: project.settings.statuses,
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 12),
            _TextField(label: 'Uwagi', controller: _notes, maxLines: 3),
            const SizedBox(height: 12),
            _TextField(
              label: 'Ilość nowych',
              controller: _count,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sourceId.isEmpty
                  ? null
                  : () {
                      final item = Connection(
                        id: _selectedId ?? controller.newId(),
                        sourceId: _sourceId,
                        destinationId: _destinationId,
                        signalType: _signalType,
                        status: _destinationId.isEmpty
                            ? 'Niezidentyfikowany'
                            : _status,
                        notes: _notes.text.trim(),
                      );
                      if (_selectedId == null) {
                        controller.addConnections(
                          item,
                          int.tryParse(_count.text) ?? 1,
                        );
                        _prepareNextConnection();
                      } else {
                        controller.updateConnection(item);
                        _clear();
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: selectedConnection == null ||
                      selectedConnection.destinationId.isEmpty
                  ? null
                  : () {
                      controller.reverseConnection(selectedConnection.id);
                      _clear();
                    },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Odwróć kierunek'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectedId == null
                  ? null
                  : () {
                      controller.deleteConnection(_selectedId!);
                      _clear();
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Usuń'),
            ),
          ],
        ),
      ),
    );
  }

  void _load(Connection connection) {
    if (_selectedId == connection.id) {
      _clear();
      return;
    }
    setState(() {
      _selectedId = connection.id;
      _sourceId = connection.sourceId;
      _destinationId = connection.destinationId;
      _signalType = connection.signalType;
      _status = connection.status;
      _notes.text = connection.notes;
      _count.text = '1';
    });
  }

  void _toggleMergeSelection(String id) {
    setState(() {
      if (_mergeSelection.contains(id)) {
        _mergeSelection.remove(id);
      } else {
        if (_mergeSelection.length == 2) {
          _mergeSelection.remove(_mergeSelection.first);
        }
        _mergeSelection.add(id);
      }
    });
  }

  void _clear() {
    setState(() {
      _selectedId = null;
      _mergeSelection.clear();
      _sourceId = '';
      _destinationId = '';
      _signalType = defaultSignalTypes.first;
      _status = defaultStatuses.first;
      _notes.clear();
      _count.text = '1';
    });
  }

  void _prepareNextConnection() {
    setState(() {
      _selectedId = null;
      _mergeSelection.clear();
      _destinationId = '';
      _notes.clear();
      _count.text = '1';
    });
  }
}

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  final _path = TextEditingController();

  static const _xlsxTypeGroup = XTypeGroup(
    label: 'Excel XLSX',
    extensions: ['xlsx'],
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ],
  );

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectControllerProvider);
    final labels = state.labels;
    if (_path.text.isEmpty && state.project.code.trim().isNotEmpty) {
      _path.text = '${state.project.code}_lista_kablowa.xlsx';
    }

    return _PageFrame(
      title: 'Eksport',
      actions: const [],
      child: ListView(
        children: [
          _SummaryStrip(
            items: [
              ('Wiersze XLSX', '${labels.length}'),
              ('Typy sygnałów', '${state.project.settings.signalTypes.length}'),
              ('Statusy', '${state.project.settings.statuses.length}'),
            ],
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plik XLSX'),
                const SizedBox(height: 12),
                _TextField(
                  label: 'Ścieżka',
                  controller: _path,
                  hint: r'C:\projekty\sala_lista_kablowa.xlsx',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: labels.isEmpty
                        ? null
                        : () => _exportXlsxWithPicker(context),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Eksportuj XLSX'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Oznaczenie')),
                  DataColumn(label: Text('Port')),
                  DataColumn(label: Text('Skąd')),
                  DataColumn(label: Text('Dokąd')),
                  DataColumn(label: Text('Typ')),
                  DataColumn(label: Text('Numer')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Uwagi')),
                ],
                rows: [
                  for (final label in labels)
                    DataRow(
                      cells: [
                        DataCell(Text(label.designation)),
                        DataCell(Text(label.portLabel)),
                        DataCell(Text(label.source)),
                        DataCell(Text(label.destination)),
                        DataCell(Text(label.exportSignalType)),
                        DataCell(Text(label.number)),
                        DataCell(Text(label.status)),
                        DataCell(Text(label.notes)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportXlsxWithConfirmation(BuildContext context) async {
    final path = _path.text.trim();
    if (path.isNotEmpty && await File(path).exists() && context.mounted) {
      final overwrite = await _confirmOverwrite(context, path);
      if (!overwrite) {
        return;
      }
    }
    await ref.read(projectControllerProvider.notifier).exportXlsx(path);
  }

  Future<void> _exportXlsxWithPicker(BuildContext context) async {
    final state = ref.read(projectControllerProvider);
    final suggestedName = _ensureExtension(
      _path.text.trim().isEmpty
          ? '${_safeFileStem(state.project.code.isEmpty ? 'lista_kablowa' : state.project.code)}_lista_kablowa.xlsx'
          : _fileName(_path.text.trim()),
      'xlsx',
    );
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_xlsxTypeGroup],
      suggestedName: suggestedName,
    );
    if (location == null) {
      return;
    }
    _path.text = _ensureExtension(location.path, 'xlsx');
    if (context.mounted) {
      await _exportXlsxWithConfirmation(context);
    }
  }
}

Future<bool> _confirmOverwrite(BuildContext context, String path) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Nadpisać plik?'),
        content: Text(path),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Nadpisz'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

String _ensureExtension(String path, String extension) {
  final cleanExtension = extension.startsWith('.') ? extension : '.$extension';
  return path.toLowerCase().endsWith(cleanExtension.toLowerCase())
      ? path
      : '$path$cleanExtension';
}

String _safeFileStem(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
  return cleaned.isEmpty ? 'projekt' : cleaned;
}

String _fileName(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.actions,
    required this.child,
  });

  final String title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              ...actions,
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TableAndForm extends StatelessWidget {
  const _TableAndForm({
    required this.table,
    required this.form,
    this.mobileList,
  });

  final Widget table;
  final Widget form;
  final Widget? mobileList;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final tableWidget = _Panel(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(child: table),
          ),
        );
        final formWidget = _Panel(child: form);

        if (compact) {
          return ListView(
            children: [
              formWidget,
              const SizedBox(height: 16),
              mobileList ?? tableWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tableWidget),
            const SizedBox(width: 16),
            SizedBox(width: 340, child: formWidget),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.emptyText,
    required this.children,
  });

  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return _Panel(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              emptyText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        const minTileWidth = 132.0;
        const maxTileWidth = 220.0;
        final columns =
            (constraints.maxWidth / (minTileWidth + gap)).floor().clamp(1, 6);
        final tileWidth =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .clamp(minTileWidth, maxTileWidth);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final List<(String, String)> details;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.secondary
        : theme.colorScheme.outline.withValues(alpha: 0.8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Bez nazwy' : title,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
              if (details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in details)
                      if (item.$2.trim().isNotEmpty)
                        _MetaChip(label: item.$1, value: item.$2),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$label: $value',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _MobileSettingsEditorList extends StatelessWidget {
  const _MobileSettingsEditorList({
    required this.cabinetRules,
    required this.endpointRules,
    required this.signalTypes,
    required this.statuses,
  });

  final TextEditingController cabinetRules;
  final TextEditingController endpointRules;
  final TextEditingController signalTypes;
  final TextEditingController statuses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RuleSection(
          title: 'Szafy',
          controller: cabinetRules,
          withPriority: false,
          initiallyExpanded: true,
        ),
        _RuleSection(
          title: 'Punkty',
          controller: endpointRules,
          withPriority: true,
        ),
        _RuleSection(
          title: 'Sygnaly',
          controller: signalTypes,
          withPriority: true,
        ),
        _StatusSection(controller: statuses),
      ],
    );
  }
}

class _RuleSection extends StatefulWidget {
  const _RuleSection({
    required this.title,
    required this.controller,
    required this.withPriority,
    this.initiallyExpanded = false,
  });

  final String title;
  final TextEditingController controller;
  final bool withPriority;
  final bool initiallyExpanded;

  @override
  State<_RuleSection> createState() => _RuleSectionState();
}

class _RuleSectionState extends State<_RuleSection> {
  @override
  Widget build(BuildContext context) {
    final rules = widget.withPriority
        ? parseTypeRulesWithPriorities(widget.controller.text)
        : parseTypeRules(widget.controller.text);

    return ExpansionTile(
      initiallyExpanded: widget.initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(widget.title),
      trailing: IconButton(
        tooltip: 'Dodaj regule',
        icon: const Icon(Icons.add),
        onPressed: () => _editRule(context),
      ),
      children: [
        if (rules.types.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Brak reguł',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final itemType in rules.types)
          _RuleTile(
            name: itemType,
            pattern: rules.rules[itemType] ?? '',
            priority: rules.priorities[itemType],
            onTap: () => _editRule(
              context,
              name: itemType,
              pattern: rules.rules[itemType] ?? '',
              priority: rules.priorities[itemType],
            ),
          ),
      ],
    );
  }

  Future<void> _editRule(
    BuildContext context, {
    String name = '',
    String pattern = '',
    int? priority,
  }) async {
    final result = await showModalBottomSheet<_RuleEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _RuleEditSheet(
          name: name,
          pattern: pattern,
          priority: priority,
          withPriority: widget.withPriority,
        );
      },
    );
    if (result == null || result.name.trim().isEmpty) {
      return;
    }

    final parsed = widget.withPriority
        ? parseTypeRulesWithPriorities(widget.controller.text)
        : parseTypeRules(widget.controller.text);
    final types = [...parsed.types];
    final rules = {...parsed.rules};
    final priorities = {...parsed.priorities};

    if (name.isNotEmpty && name != result.name) {
      types.remove(name);
      rules.remove(name);
      priorities.remove(name);
    }
    if (!types.contains(result.name)) {
      types.add(result.name);
    }
    if (result.pattern.trim().isEmpty) {
      rules.remove(result.name);
    } else {
      rules[result.name] = result.pattern.trim();
    }
    if (widget.withPriority &&
        result.priority != null &&
        result.priority! > 0) {
      priorities[result.name] = result.priority!;
    } else {
      priorities.remove(result.name);
    }

    setState(() {
      widget.controller.text = formatTypeRules(types, rules, priorities);
    });
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.name,
    required this.pattern,
    required this.onTap,
    this.priority,
  });

  final String name;
  final String pattern;
  final int? priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final example = _patternExample(pattern);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        pattern.isEmpty ? 'Bez wzoru' : '$pattern -> $example',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (priority != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Priorytet: $priority',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleEditSheet extends StatefulWidget {
  const _RuleEditSheet({
    required this.name,
    required this.pattern,
    required this.withPriority,
    this.priority,
  });

  final String name;
  final String pattern;
  final int? priority;
  final bool withPriority;

  @override
  State<_RuleEditSheet> createState() => _RuleEditSheetState();
}

class _RuleEditSheetState extends State<_RuleEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _pattern;
  late final TextEditingController _priority;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _pattern = TextEditingController(text: widget.pattern);
    _priority = TextEditingController(text: widget.priority?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _pattern.dispose();
    _priority.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final example = _patternExample(_pattern.text);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Regula nazwy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nazwa w aplikacji'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pattern,
            decoration: const InputDecoration(labelText: 'Wzor oznaczenia'),
            onChanged: (_) => setState(() {}),
          ),
          if (widget.withPriority) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _priority,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Priorytet'),
            ),
          ],
          const SizedBox(height: 14),
          Text('Podglad: $example'),
          const SizedBox(height: 8),
          Text(
            'N - numer, NN - minimum dwie cyfry, NNN - minimum trzy cyfry',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(
              _RuleEditResult(
                name: _name.text.trim(),
                pattern: _pattern.text.trim(),
                priority: int.tryParse(_priority.text.trim()),
              ),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}

class _RuleEditResult {
  const _RuleEditResult({
    required this.name,
    required this.pattern,
    required this.priority,
  });

  final String name;
  final String pattern;
  final int? priority;
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final statuses = linesToList(controller.text);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Statusy'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in statuses) Chip(label: Text(status)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Statusy'),
        ),
      ],
    );
  }
}

String _patternExample(String pattern) {
  if (pattern.trim().isEmpty) {
    return '-';
  }
  return pattern.replaceAllMapped(RegExp(r'N+'), (match) {
    final width = match.group(0)!.length;
    return '1'.padLeft(width, '0');
  });
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item in items)
          _Panel(
            child: SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text(item.$2,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cleanValues = values.isEmpty ? [value] : values;
    final cleanValue = cleanValues.contains(value) ? value : cleanValues.first;

    return DropdownButtonFormField<String>(
      initialValue: cleanValue,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final item in cleanValues)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _ObjectDropdown extends StatelessWidget {
  const _ObjectDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.allowUnknown,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<_ObjectOption> values;
  final bool allowUnknown;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      if (allowUnknown) const _ObjectOption('', 'Nieznane', ''),
      ...values,
    ];
    final cleanValue = options.any((item) => item.id == value)
        ? value
        : (allowUnknown ? '' : null);

    return DropdownButtonFormField<String>(
      initialValue: cleanValue,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final item in options)
          DropdownMenuItem(
            value: item.id,
            child: Text(
                item.kind.isEmpty ? item.name : '${item.name} (${item.kind})'),
          ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _ObjectOption {
  const _ObjectOption(this.id, this.name, this.kind);

  final String id;
  final String name;
  final String kind;
}

class _FormTitle extends StatelessWidget {
  const _FormTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

String _objectName(dynamic project, String id, [String missing = '']) {
  if (id.isEmpty) {
    return missing;
  }
  return project.findCabinet(id)?.name ??
      project.findEndpoint(id)?.name ??
      missing;
}
