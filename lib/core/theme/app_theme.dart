import 'package:flutter/material.dart';

/// Semantic surface/text colors that adapt to light/dark mode.
///
/// Screens must use `AppColors.of(context)` (or `context.appColors`) instead
/// of the static light-only constants on [AppTheme], so dark mode renders
/// correctly.
class AppColors extends ThemeExtension<AppColors> {
  /// Scaffold/base background (light: white canvas).
  final Color paper;

  /// Card/panel surfaces sitting on [paper].
  final Color panel;

  /// Primary text.
  final Color ink;

  /// Hairline borders and dividers.
  final Color line;

  /// Secondary/supporting text.
  final Color subtext;

  /// Table-inner divider / alternating row background.
  final Color zebra;

  /// Hint/placeholder text.
  final Color placeholder;

  /// Grey card / skeleton surface (Material `surfaceContainerHighest`).
  final Color surfaceContainerHighest;

  /// Dialog body text.
  final Color body;

  /// Banner / preview soft background.
  final Color soft;

  /// Soft grey card surface.
  final Color cardSoft;

  /// Dark surface (start-elevation bar, Pro panel, sum chips, snackbar).
  final Color darkSurface;

  /// Inner element on a dark surface.
  final Color darkSurface2;

  /// GH / 적합 / 사용가능.
  final Color green;
  final Color greenSoft;

  /// IH / BM.
  final Color blue;
  final Color blueSoft;

  /// TP / 주의 / Pro / 백업.
  final Color orange;
  final Color orangeSoft;

  /// Secondary attention accent.
  final Color amber;

  /// 차단오류 / 사용중지.
  final Color err;
  final Color errSoft;

  const AppColors({
    required this.paper,
    required this.panel,
    required this.ink,
    required this.line,
    required this.subtext,
    required this.zebra,
    required this.placeholder,
    required this.surfaceContainerHighest,
    required this.body,
    required this.soft,
    required this.cardSoft,
    required this.darkSurface,
    required this.darkSurface2,
    required this.green,
    required this.greenSoft,
    required this.blue,
    required this.blueSoft,
    required this.orange,
    required this.orangeSoft,
    required this.amber,
    required this.err,
    required this.errSoft,
  });

  static const light = AppColors(
    paper: Color(0xFFFFFFFF),
    panel: Color(0xFFFFFFFF),
    ink: Color(0xFF111111),
    line: Color(0xFFE5E7EB),
    subtext: Color(0xFF6B7280),
    zebra: Color(0xFFF3F4F6),
    placeholder: Color(0xFF898989),
    surfaceContainerHighest: Color(0xFFF5F5F5),
    body: Color(0xFF374151),
    soft: Color(0xFFF8F9FA),
    cardSoft: Color(0xFFF5F5F5),
    darkSurface: Color(0xFF101010),
    darkSurface2: Color(0xFF1A1A1A),
    green: Color(0xFF10B981),
    greenSoft: Color(0xFFECFDF5),
    blue: Color(0xFF3B82F6),
    blueSoft: Color(0xFFEFF6FF),
    orange: Color(0xFFFB923C),
    orangeSoft: Color(0xFFFFF7ED),
    amber: Color(0xFFF59E0B),
    err: Color(0xFFEF4444),
    errSoft: Color(0xFFFEF2F2),
  );

  static const dark = AppColors(
    paper: Color(0xFF111816),
    panel: Color(0xFF1B241F),
    ink: Color(0xFFF4F2EC),
    line: Color(0xFF2A332E),
    subtext: Color(0xFF9AA49B),
    zebra: Color(0xFF1C231F),
    placeholder: Color(0xFF71776F),
    surfaceContainerHighest: Color(0xFF1B241F),
    body: Color(0xFFD4D0C6),
    soft: Color(0xFF171F1B),
    cardSoft: Color(0xFF1B241F),
    darkSurface: Color(0xFF1E2823),
    darkSurface2: Color(0xFF28332D),
    green: Color(0xFF83B795),
    greenSoft: Color(0xFF12241B),
    blue: Color(0xFF76B8D6),
    blueSoft: Color(0xFF0F2530),
    orange: Color(0xFFFFA56D),
    orangeSoft: Color(0xFF2B1C10),
    amber: Color(0xFFF59E0B),
    err: Color(0xFFF2857F),
    errSoft: Color(0xFF2C1615),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? light;
  }

  @override
  AppColors copyWith({
    Color? paper,
    Color? panel,
    Color? ink,
    Color? line,
    Color? subtext,
    Color? zebra,
    Color? placeholder,
    Color? surfaceContainerHighest,
    Color? body,
    Color? soft,
    Color? cardSoft,
    Color? darkSurface,
    Color? darkSurface2,
    Color? green,
    Color? greenSoft,
    Color? blue,
    Color? blueSoft,
    Color? orange,
    Color? orangeSoft,
    Color? amber,
    Color? err,
    Color? errSoft,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      panel: panel ?? this.panel,
      ink: ink ?? this.ink,
      line: line ?? this.line,
      subtext: subtext ?? this.subtext,
      zebra: zebra ?? this.zebra,
      placeholder: placeholder ?? this.placeholder,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      body: body ?? this.body,
      soft: soft ?? this.soft,
      cardSoft: cardSoft ?? this.cardSoft,
      darkSurface: darkSurface ?? this.darkSurface,
      darkSurface2: darkSurface2 ?? this.darkSurface2,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      blue: blue ?? this.blue,
      blueSoft: blueSoft ?? this.blueSoft,
      orange: orange ?? this.orange,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      amber: amber ?? this.amber,
      err: err ?? this.err,
      errSoft: errSoft ?? this.errSoft,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      line: Color.lerp(line, other.line, t)!,
      subtext: Color.lerp(subtext, other.subtext, t)!,
      zebra: Color.lerp(zebra, other.zebra, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      surfaceContainerHighest: Color.lerp(
        surfaceContainerHighest,
        other.surfaceContainerHighest,
        t,
      )!,
      body: Color.lerp(body, other.body, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      cardSoft: Color.lerp(cardSoft, other.cardSoft, t)!,
      darkSurface: Color.lerp(darkSurface, other.darkSurface, t)!,
      darkSurface2: Color.lerp(darkSurface2, other.darkSurface2, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      err: Color.lerp(err, other.err, t)!,
      errSoft: Color.lerp(errSoft, other.errSoft, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => AppColors.of(this);
}

/// Typography helpers shared across screens.
class AppTypography {
  /// Tabular figures for numeric measurement text (표고/IH/GH/합계/오차).
  static const List<FontFeature> tabularFeatures = [
    FontFeature.tabularFigures(),
  ];
}

class AppTheme {
  // Brand accents — identical in both modes.
  static const fieldGreen = Color(0xFF10B981);
  static const surveyOrange = Color(0xFFFB923C);
  static const datumBlue = Color(0xFF3B82F6);

  // Light-only surface constants. Prefer AppColors.of(context) in widgets;
  // these remain for theme construction below.
  static const ink = Color(0xFF111111);
  static const paper = Color(0xFFFFFFFF);
  static const panel = Color(0xFFFFFFFF);
  static const line = Color(0xFFE5E7EB);
  static const darkInk = Color(0xFFF4F2EC);
  static const darkSurface = Color(0xFF111816);

  static ThemeData get lightTheme {
    const surface = Color(0xFFFFFFFF);
    final scheme = ColorScheme.fromSeed(
      seedColor: fieldGreen,
      brightness: Brightness.light,
      primary: ink,
      onPrimary: Colors.white,
      secondary: surveyOrange,
      tertiary: datumBlue,
      error: const Color(0xFFEF4444),
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      outline: line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Pretendard',
      extensions: const [AppColors.light],
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: line, width: 1)),
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: Color(0xFF6B7280),
        indicatorColor: ink,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
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
          borderSide: const BorderSide(color: ink, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: ink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: ink,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        elevation: 2,
        sizeConstraints: const BoxConstraints.tightFor(width: 54, height: 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: panel,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: line),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF101010),
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: Colors.white,
        ),
        actionTextColor: surveyOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ).apply(bodyColor: ink, displayColor: ink),
      listTileTheme: const ListTileThemeData(
        iconColor: ink,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          color: Color(0xFF6B7280),
          fontSize: 13,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const paperDark = Color(0xFF111816);
    const panelDark = Color(0xFF1B241F);
    const lineDark = Color(0xFF2A332E);
    const inkDark = Color(0xFFF4F2EC);
    const subtextDark = Color(0xFF9AA49B);
    const orangeDark = Color(0xFFFFA56D);
    const blueDark = Color(0xFF76B8D6);

    final scheme = ColorScheme.fromSeed(
      seedColor: fieldGreen,
      brightness: Brightness.dark,
      primary: inkDark,
      onPrimary: paperDark,
      secondary: orangeDark,
      tertiary: blueDark,
      error: const Color(0xFFF2857F),
      surface: paperDark,
      onSurface: inkDark,
      surfaceContainerHighest: panelDark,
      outline: lineDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Pretendard',
      extensions: const [AppColors.dark],
      scaffoldBackgroundColor: paperDark,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: paperDark,
        foregroundColor: inkDark,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: lineDark, width: 1)),
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: inkDark,
        ),
        iconTheme: IconThemeData(color: inkDark),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: inkDark,
        unselectedLabelColor: subtextDark,
        indicatorColor: inkDark,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: const DividerThemeData(color: lineDark, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: blueDark, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: inkDark,
          foregroundColor: paperDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: inkDark,
          side: const BorderSide(color: lineDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkDark,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: orangeDark,
        foregroundColor: paperDark,
        elevation: 2,
        sizeConstraints: const BoxConstraints.tightFor(width: 54, height: 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: panelDark,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lineDark),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E2823),
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: inkDark,
        ),
        actionTextColor: orangeDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, color: inkDark),
        bodyMedium: TextStyle(fontSize: 14, color: inkDark),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ).apply(bodyColor: inkDark, displayColor: inkDark),
      listTileTheme: const ListTileThemeData(
        iconColor: inkDark,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          color: inkDark,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          color: subtextDark,
          fontSize: 13,
        ),
      ),
    );
  }
}
