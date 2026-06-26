import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFF050806);
  const panel = Color(0xFF0B1410);
  const border = Color(0xFF1C3328);
  const text = Color(0xFFFFFFFF);
  const mutedText = Color(0xFFB0B0B0);
  const accent = Color(0xFF00C853);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
    surface: panel,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    dividerColor: border,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: text),
      bodySmall: TextStyle(color: mutedText),
      titleLarge: TextStyle(color: text),
      titleMedium: TextStyle(color: text),
      headlineSmall: TextStyle(color: text),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: panel,
      foregroundColor: text,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: panel,
      selectedIconTheme: IconThemeData(color: accent),
      selectedLabelTextStyle: TextStyle(color: accent),
      unselectedIconTheme: IconThemeData(color: mutedText),
      unselectedLabelTextStyle: TextStyle(color: mutedText),
      indicatorColor: Color(0xFF102D1C),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accent),
      ),
    ),
  );
}
