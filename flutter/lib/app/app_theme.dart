import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFF000000);
  const panel = Color(0xFF07110D);
  const panelHigh = Color(0xFF0B1B13);
  const border = Color(0xFF173323);
  const text = Color(0xFFFFFFFF);
  const mutedText = Color(0xFFC3C8C4);
  const accent = Color(0xFF00C853);
  const accentStrong = Color(0xFF00E676);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
    primary: accent,
    secondary: accentStrong,
    surface: panel,
    surfaceContainerHighest: panelHigh,
    outline: border,
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
      labelSmall: TextStyle(color: mutedText),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: text, fontWeight: FontWeight.w500),
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: panel,
      indicatorColor: const Color(0xFF153D25),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : mutedText,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? accent : mutedText,
          fontWeight:
              states.contains(WidgetState.selected) ? FontWeight.w700 : null,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panelHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF294737)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentStrong, width: 1.5),
      ),
      labelStyle: const TextStyle(color: mutedText),
      hintStyle: const TextStyle(color: Color(0xFF838C86)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: const Color(0xFF001F0C),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: mutedText,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
