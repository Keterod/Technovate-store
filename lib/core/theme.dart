import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );
    return _base(colorScheme, Brightness.light);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );
    return _base(colorScheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = GoogleFonts.poppinsTextTheme(
      brightness == Brightness.dark
          ? Typography.whiteMountainView
          : Typography.blackMountainView,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      drawerTheme: DrawerThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
