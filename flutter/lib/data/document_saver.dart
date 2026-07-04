import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

class DocumentSaver {
  static const _channel = MethodChannel('pl.greencrew.tools/document_saver');

  static Future<String?> save({
    required String suggestedName,
    required String mimeType,
    required List<int> bytes,
    List<XTypeGroup> acceptedTypeGroups = const [],
  }) async {
    final data = Uint8List.fromList(bytes);
    if (Platform.isAndroid) {
      return _channel.invokeMethod<String>('saveBytes', {
        'suggestedName': suggestedName,
        'mimeType': mimeType,
        'bytes': data,
      });
    }

    final location = await getSaveLocation(
      acceptedTypeGroups: acceptedTypeGroups,
      suggestedName: suggestedName,
    );
    if (location == null) {
      return null;
    }
    await File(location.path).writeAsBytes(data, flush: true);
    return location.path;
  }
}
