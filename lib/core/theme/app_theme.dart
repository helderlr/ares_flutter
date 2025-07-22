import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        primaryColor: AppColors.lightBlue,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBlue,
          foregroundColor: AppColors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.lightBlue,
        ),
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => ThemeData(
        primaryColor: AppColors.darkBlue,
        scaffoldBackgroundColor: AppColors.darkBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.darkBlue,
        ),
        brightness: Brightness.dark,
      );
}
