import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const double appBarTitleFontSize = 17.0;

  static TextStyle appBarTitleStyle({Color color = AppColors.white}) {
    return TextStyle(
      fontSize: appBarTitleFontSize,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.15,
    );
  }

  static const TextStyle listItemTitleStyle = TextStyle(
    fontSize: appBarTitleFontSize,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static TextStyle listItemSubtitleStyle = TextStyle(
    fontSize: 13,
    color: Colors.grey[600],
  );

  static const TextStyle consultaLabelStyle = TextStyle(
    fontSize: appBarTitleFontSize,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static TextStyle consultaValueStyle({
    bool isEditable = true,
    Color? valueColor,
  }) {
    return TextStyle(
      fontSize: appBarTitleFontSize,
      color: valueColor ??
          (isEditable ? Colors.black87 : Colors.grey.shade600),
      fontWeight: isEditable ? FontWeight.normal : FontWeight.w500,
    );
  }

  static ThemeData get lightTheme => ThemeData(
        primaryColor: AppColors.lightBlue,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightBlue,
          foregroundColor: AppColors.white,
          centerTitle: true,
          titleTextStyle: appBarTitleStyle(),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        dialogTheme: DialogTheme(
          titleTextStyle: TextStyle(
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.lightBlue,
        ),
        brightness: Brightness.light,
      );

  static ThemeData get darkTheme => ThemeData(
        primaryColor: AppColors.darkBlue,
        scaffoldBackgroundColor: AppColors.darkBlue,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.white,
          centerTitle: true,
          titleTextStyle: appBarTitleStyle(),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        dialogTheme: const DialogTheme(
          titleTextStyle: TextStyle(
            fontSize: appBarTitleFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.darkBlue,
        ),
        brightness: Brightness.dark,
      );
}
