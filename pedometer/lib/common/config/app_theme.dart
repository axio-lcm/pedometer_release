import 'package:flutter/material.dart';
import 'package:pedometer/common/config/app_colors.dart';

/// 全局深色主题
class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
