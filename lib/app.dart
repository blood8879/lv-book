import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/project/presentation/project_list_screen.dart';
import 'features/purchase/purchase_providers.dart';
import 'features/quickmemo/presentation/quick_memo_fab.dart';

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
      title: AppConstants.appName,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ProjectListScreen(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [_quickMemoFabController],
      // Overlay a single app-wide quick-memo FAB above every route.
      builder: (context, child) {
        return QuickMemoFabScope(
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
      },
    );
  }
}
