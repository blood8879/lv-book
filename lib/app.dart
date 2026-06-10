import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/project/presentation/project_list_screen.dart';

class LvBookApp extends StatelessWidget {
  const LvBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ProjectListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
