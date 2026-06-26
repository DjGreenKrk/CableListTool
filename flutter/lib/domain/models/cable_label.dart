class CableLabel {
  const CableLabel({
    required this.connectionId,
    required this.cableIndex,
    required this.designation,
    required this.project,
    required this.source,
    required this.destination,
    required this.signalType,
    required this.exportSignalType,
    required this.portLabel,
    required this.number,
    required this.status,
    required this.notes,
  });

  final String connectionId;
  final int cableIndex;
  final String designation;
  final String project;
  final String source;
  final String destination;
  final String signalType;
  final String exportSignalType;
  final String portLabel;
  final String number;
  final String status;
  final String notes;
}
