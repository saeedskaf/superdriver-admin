import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:superdriver_admin/shared/themes/colors_custom.dart';

class AppTheme {
  AppTheme._();

  static final _borderRadius = BorderRadius.circular(12);
  static final _buttonBorderRadius = BorderRadius.circular(14);

  static ThemeData get light {
    final textTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ColorsCustom.background,
      colorScheme: ColorScheme.light(
        primary: ColorsCustom.primary,
        secondary: ColorsCustom.secondary,
        tertiary: ColorsCustom.secondaryLight,
        surface: ColorsCustom.surface,
        error: ColorsCustom.error,
        onPrimary: ColorsCustom.textOnPrimary,
        onSecondary: ColorsCustom.textOnPrimary,
        outline: ColorsCustom.border,
        surfaceContainerHighest: ColorsCustom.surfaceVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorsCustom.surface,
        foregroundColor: ColorsCustom.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: ColorsCustom.textPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsCustom.primary,
          foregroundColor: ColorsCustom.textOnPrimary,
          disabledBackgroundColor: ColorsCustom.border,
          disabledForegroundColor: ColorsCustom.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: _buttonBorderRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorsCustom.primary,
          side: const BorderSide(color: ColorsCustom.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: _buttonBorderRadius),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorsCustom.primary,
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorsCustom.primary;
          }
          return ColorsCustom.surface;
        }),
        side: const BorderSide(color: ColorsCustom.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorsCustom.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: const BorderSide(color: ColorsCustom.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: ColorsCustom.textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: ColorsCustom.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: ColorsCustom.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ColorsCustom.border, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorsCustom.surface,
        selectedItemColor: ColorsCustom.primary,
        unselectedItemColor: ColorsCustom.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorsCustom.primary,
        foregroundColor: ColorsCustom.textOnPrimary,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: ColorsCustom.border,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorsCustom.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      ),
    );
  }
}
