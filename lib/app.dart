import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/project/presentation/project_list_screen.dart';
import 'features/purchase/purchase_providers.dart';
import 'features/quickmemo/presentation/quick_memo_fab.dart';
import 'l10n/l10n.dart';

class LvBookApp extends ConsumerStatefulWidget {
  const LvBookApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  ConsumerState<LvBookApp> createState() => _LvBookAppState();
}

class _LvBookAppState extends ConsumerState<LvBookApp> {
  final _quickMemoFabController = QuickMemoFabController();

  @override
  void dispose() {
    _quickMemoFabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Start listening to the store's purchase stream app-wide (not only while
    // Settings is open) so late purchase/restore events update ads state.
    ref.read(purchaseControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final navigatorKey = LvBookApp.navigatorKey;
    return MaterialApp(
      // Task-switcher title follows the app language.
      onGenerateTitle: (context) => context.l10n.coreAppName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Korean device -> ko, anything else -> en.
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ProjectListScreen(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [_quickMemoFabController],
      // Overlay a single app-wide quick-memo FAB above every route.
      builder: (context, child) {
        final content = QuickMemoFabScope(
          controller: _quickMemoFabController,
          child: Stack(
            children: [
              Positioned.fill(child: child ?? const SizedBox.shrink()),
              QuickMemoFab(
                navigatorKey: navigatorKey,
                controller: _quickMemoFabController,
              ),
            ],
          ),
        );
        // iOS keeps its existing status bar handling.
        if (defaultTargetPlatform != TargetPlatform.android) return content;
        // Edge-to-edge fallback for every screen: transparent status bar
        // where there is no AppBar (AppBars set their own style on top) and
        // nav bar icons that match the theme.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: edgeToEdgeOverlayStyle(Theme.of(context).brightness),
          child: content,
        );
      },
    );
  }
}

/// System bar style for edge-to-edge Android: transparent status bar and icon
/// brightness matching [brightness]. The navigation bar colour is left to
/// MainActivity (transparent with the system contrast scrim on API 29+, a
/// translucent scrim below that, where light nav icons may be unavailable).
SystemUiOverlayStyle edgeToEdgeOverlayStyle(Brightness brightness) {
  final icons = brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: icons,
    statusBarBrightness: brightness,
    systemNavigationBarIconBrightness: icons,
  );
}
