import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_theme_data.dart';
import 'theme_extensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary500,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      textTheme: AppThemeData.textTheme,
      colorScheme: AppThemeData.colorSchemeLight,
      extensions: const [AppShadows.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
