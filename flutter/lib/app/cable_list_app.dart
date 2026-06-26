import 'package:flutter/material.dart';

import '../features/shell/cable_shell.dart';
import 'app_theme.dart';

class CableListApp extends StatelessWidget {
  const CableListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CableListTool',
      theme: buildAppTheme(),
      home: const CableShell(),
    );
  }
}
