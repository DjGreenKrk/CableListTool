import 'package:cable_list_tool/data/project_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads legacy aliases and expands quantity connections', () {
    var id = 0;
    final codec = ProjectCodec(newId: () => 'new-${++id}');
    final project = codec.decode('''
{
  "schema_version": 1,
  "project": {"name": "Sala", "code": "SALA"},
  "cabinets": [
    {"id": "cab-1", "name": "RSC-1", "type": "Rack"}
  ],
  "endpoints": [
    {"id": "end-1", "name": "FB-01", "type": "Floorbox"}
  ],
  "connections": [
    {
      "id": "con-1",
      "source_id": "cab-1",
      "destination_id": "end-1",
      "signal_type": "ETH",
      "quantity": 2,
      "status": "Do sprawdzenia",
      "cable_statuses": {"2": "Potwierdzone"}
    }
  ],
  "settings": {
    "signal_type_descriptions": {"Audio": "A"}
  }
}
''');

    expect(project.name, 'Sala');
    expect(project.cabinets.single.cabinetType, 'Rack');
    expect(project.endpoints.single.endpointType, 'Floorbox');
    expect(project.connections, hasLength(2));
    expect(project.connections[0].id, 'con-1');
    expect(project.connections[1].id, 'new-1');
    expect(project.connections[1].status, 'Potwierdzone');
    expect(project.settings.signalTypeExportNames['Audio'], 'A');
  });
}
