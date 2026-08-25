import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Familias tipográficas del mockup: "Space Grotesk" (cuerpo), "Space Mono"
/// (kickers/metadata), "DM Serif Display" (headlines grandes). Ninguna está
/// empaquetada como asset todavía (no hay archivos .ttf en el repo), así que
/// caen a la fuente del sistema hasta que se agreguen — ver ARCHITECTURE.md
/// §9 trampa 3 (misma regla que para el contenido de las placas: nada de
/// fetch de fuentes en runtime). Cuando se agreguen los .ttf, alcanza con
/// declarar `fontFamily` acá; el resto de la app ya usa `Theme.of(context)`.
const _fontSans = 'Space Grotesk';
const _fontMono = 'Space Mono';
const _fontDisplay = 'DM Serif Display';

/// Design system neutro (ver CLAUDE.md "Brand separation" — la identidad
/// de marca vive solo dentro de un pack de templates de placa, nunca acá).
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryContrast,
      secondary: AppColors.accent,
      onSecondary: AppColors.primaryContrast,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: _fontSans);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: base.textTheme
          .apply(fontFamily: _fontSans, bodyColor: AppColors.text, displayColor: AppColors.text)
          .copyWith(
            displayLarge: base.textTheme.displayLarge?.copyWith(
              fontFamily: _fontDisplay,
              fontWeight: FontWeight.w400,
              height: 1.08,
              letterSpacing: -0.3,
            ),
            displayMedium: base.textTheme.displayMedium?.copyWith(
              fontFamily: _fontDisplay,
              fontWeight: FontWeight.w400,
              height: 1.1,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            labelSmall: base.textTheme.labelSmall?.copyWith(
              fontFamily: _fontMono,
              letterSpacing: 1.6,
              color: AppColors.textSubtle,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontSans,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: AppColors.text,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1.5, space: 1.5),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

/// Estilo mono usado en kickers/labels ("VENTA", "PLACAS GRATIS ESTE MES").
const TextStyle appMonoKicker = TextStyle(
  fontFamily: _fontMono,
  fontSize: 11,
  letterSpacing: 1.6,
  fontWeight: FontWeight.w700,
  color: AppColors.textSubtle,
);
