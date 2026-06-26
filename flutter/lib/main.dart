import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/cable_list_app.dart';

void main() {
  runApp(const ProviderScope(child: CableListApp()));
}
