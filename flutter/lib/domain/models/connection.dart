class Connection {
  const Connection({
    required this.id,
    this.sourceId = '',
    this.destinationId = '',
    this.signalType = defaultSignalType,
    this.quantity = 1,
    this.status = defaultStatus,
    this.cableNumber,
    this.cableStatuses = const {},
    this.notes = '',
  });

  static const defaultSignalType = 'ETH';
  static const defaultStatus = 'Do sprawdzenia';

  final String id;
  final String sourceId;
  final String destinationId;
  final String signalType;
  final int quantity;
  final String status;
  final int? cableNumber;
  final Map<String, String> cableStatuses;
  final String notes;

  factory Connection.fromJson(
      Map<String, Object?> json, String Function() newId) {
    final quantity = _positiveIntOr(json['quantity'], 1);
    return Connection(
      id: _stringOrGenerated(json['id'], newId),
      sourceId: _stringOr(json['source_id'], ''),
      destinationId: _stringOr(json['destination_id'], ''),
      signalType: _stringOr(json['signal_type'], defaultSignalType),
      quantity: quantity,
      status: _stringOr(json['status'], defaultStatus),
      cableNumber: _positiveInt(json['cable_number']),
      cableStatuses: _stringMap(json['cable_statuses']),
      notes: _stringOr(json['notes'], ''),
    );
  }

  Connection copyWith({
    String? id,
    String? sourceId,
    String? destinationId,
    String? signalType,
    int? quantity,
    String? status,
    int? cableNumber,
    Map<String, String>? cableStatuses,
    String? notes,
  }) {
    return Connection(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      destinationId: destinationId ?? this.destinationId,
      signalType: signalType ?? this.signalType,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      cableNumber: cableNumber ?? this.cableNumber,
      cableStatuses: cableStatuses ?? this.cableStatuses,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'destination_id': destinationId,
      'signal_type': signalType,
      'quantity': 1,
      'status': status,
      'cable_number': cableNumber,
      'cable_statuses': <String, String>{},
      'notes': notes,
    };
  }
}

String _stringOrGenerated(Object? value, String Function() fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback() : text;
}

String _stringOr(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _positiveIntOr(Object? value, int fallback) {
  final parsed = _positiveInt(value);
  return parsed ?? fallback;
}

int? _positiveInt(Object? value) {
  if (value == null || value == '') {
    return null;
  }
  final number = value is int ? value : int.tryParse(value.toString());
  if (number == null || number <= 0) {
    return null;
  }
  return number;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key.toString().trim();
    final text = entry.value?.toString().trim() ?? '';
    if (key.isNotEmpty && text.isNotEmpty) {
      result[key] = text;
    }
  }
  return result;
}
