import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF17211B);
  static const fieldGreen = Color(0xFF2F5D45);
  static const surveyOrange = Color(0xFFE66E24);
  static const datumBlue = Color(0xFF1E6B8E);
  static const paper = Color(0xFFFAF8F2);
  static const panel = Color(0xFFFFFFFF);
  static const line = Color(0xFFD8D1C3);
  static const darkInk = Color(0xFFE8E1D4);
  static const darkSurface = Color(0xFF111816);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: fieldGreen,
      primary: fieldGreen,
      secondary: surveyOrange,
      tertiary: datumBlue,
      surface: paper,
      surfaceContainer: panel,
      surfaceContainerHighest: const Color(0xFFF0EADD),
      outline: line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: fieldGreen,
        foregroundColor: Color(0xFFFAF8F2),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFAF8F2),
        ),
        iconTheme: IconThemeData(color: Color(0xFFFAF8F2)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFFFAF8F2),
        unselectedLabelColor: Color(0xCCFAF8F2),
        indicatorColor: surveyOrange,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 0.7),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: datumBlue, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          backgroundColor: ink,
          foregroundColor: paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: surveyOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: panel,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: line),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(fontSize: 16, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink),
        labelLarge: TextStyle(fontWeight: FontWeight.w800),
      ).apply(bodyColor: ink, displayColor: ink),
      listTileTheme: const ListTileThemeData(
        iconColor: fieldGreen,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: TextStyle(color: Color(0xFF6D665B), fontSize: 13),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: fieldGreen,
      primary: const Color(0xFF83B795),
      secondary: const Color(0xFFFFA56D),
      tertiary: const Color(0xFF76B8D6),
      surface: darkSurface,
      surfaceContainer: const Color(0xFF18211E),
      surfaceContainerHighest: const Color(0xFF22302B),
      outline: const Color(0xFF415048),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF17211B),
        foregroundColor: darkInk,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: darkInk,
        ),
      ),
      tabBarTheme: const TabBarThemeData(indicatorColor: surveyOrange),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF18211E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: surveyOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
