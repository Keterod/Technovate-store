import 'package:flutter/material.dart';

class TechnovateTheme {
  TechnovateTheme._();

  static const _colorSeed = Color(0xFF3949AB);
  static const _tertiary = Color(0xFF00BFA5);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _colorSeed,
      tertiary: _tertiary,
      brightness: Brightness.light,
    );
    return _baseTheme(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _colorSeed,
      tertiary: _tertiary,
      brightness: Brightness.dark,
    );
    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final color = scheme.onSurface;
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: color),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
    );
  }

  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing48 = 48.0;
}

extension DarkModeExt on BuildContext {
  bool get isDarkMode => DarkModeScope.of(this).darkMode;
  VoidCallback get toggleDarkMode => DarkModeScope.of(this).onToggle;
}

class DarkModeScope extends InheritedWidget {
  final bool darkMode;
  final VoidCallback onToggle;

  const DarkModeScope({
    super.key,
    required this.darkMode,
    required this.onToggle,
    required super.child,
  });

  static DarkModeScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DarkModeScope>()!;
  }

  @override
  bool updateShouldNotify(DarkModeScope old) => darkMode != old.darkMode;
}
