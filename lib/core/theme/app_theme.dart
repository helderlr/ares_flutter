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

  static const double listItemTitleFontSize = 13.0;

  static TextStyle listItemTitleStyleOf(BuildContext context) {
    return TextStyle(
      fontSize: listItemTitleFontSize,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      letterSpacing: 0.1,
    );
  }

  static TextStyle listItemSubtitleStyleOf(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle consultaLabelStyleOf(BuildContext context) {
    return TextStyle(
      fontSize: appBarTitleFontSize,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle consultaValueStyleOf(
    BuildContext context, {
    bool isEditable = true,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: appBarTitleFontSize,
      color: isEditable ? scheme.onSurface : scheme.onSurfaceVariant,
      fontWeight: isEditable ? FontWeight.normal : FontWeight.w500,
    );
  }

  static ThemeData get lightTheme {
    const Color primary = AppColors.lightBlue;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: Colors.white,
      onSurface: const Color(0xFF1E293B),
      onSurfaceVariant: const Color(0xFF64748B),
    );
    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldColor: Colors.white,
      appBarColor: primary,
      appBarForeground: Colors.white,
      drawerColor: Colors.white,
      cardColor: Colors.white,
    );
  }

  static ThemeData get darkTheme {
    const Color primary = AppColors.lightBlue;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      surface: const Color(0xFF1E293B),
      onSurface: const Color(0xFFE2E8F0),
      onSurfaceVariant: const Color(0xFF94A3B8),
    );
    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldColor: const Color(0xFF0F172A),
      appBarColor: AppColors.darkBlue,
      appBarForeground: Colors.white,
      drawerColor: const Color(0xFF1E293B),
      cardColor: const Color(0xFF1E293B),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldColor,
    required Color appBarColor,
    required Color appBarForeground,
    required Color drawerColor,
    required Color cardColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      cardColor: cardColor,
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: appBarForeground,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: appBarTitleStyle(color: appBarForeground),
        iconTheme: IconThemeData(color: appBarForeground),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: drawerColor,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        titleTextStyle: TextStyle(
          fontSize: appBarTitleFontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(color: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        labelStyle: TextStyle(color: colorScheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withOpacity(0.35),
          disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.7),
        ),
      ),
      brightness: colorScheme.brightness,
    );
  }

  @Deprecated('Use listItemTitleStyleOf(context)')
  static const TextStyle listItemTitleStyle = TextStyle(
    fontSize: listItemTitleFontSize,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    letterSpacing: 0.1,
  );

  @Deprecated('Use listItemSubtitleStyleOf(context)')
  static TextStyle listItemSubtitleStyle = TextStyle(
    fontSize: 13,
    color: Colors.grey,
  );

  @Deprecated('Use consultaLabelStyleOf(context)')
  static const TextStyle consultaLabelStyle = TextStyle(
    fontSize: appBarTitleFontSize,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  @Deprecated('Use consultaValueStyleOf(context)')
  static TextStyle consultaValueStyle({
    bool isEditable = true,
    Color? valueColor,
  }) {
    return TextStyle(
      fontSize: appBarTitleFontSize,
      color: valueColor ??
          (isEditable ? Colors.black87 : Colors.grey),
      fontWeight: isEditable ? FontWeight.normal : FontWeight.w500,
    );
  }
}
