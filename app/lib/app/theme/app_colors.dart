import 'package:flutter/widgets.dart';

/// Design system neutro de la app (NO sabe qué es RE/MAX — ver CLAUDE.md
/// "Brand separation"). Portado 1:1 de los tokens del mockup
/// (`_ds/.../tokens/colors.css`, paleta "NoisyDev"). Solo el modo claro
/// ("retro paper") está implementado: es el que usa el mockup en las
/// pantallas de teléfono (`data-theme="light"`).
abstract final class AppColors {
  // ---------- raw palette ----------
  static const violet400 = Color(0xFF9B7CF0);
  static const violet500 = Color(0xFF7C5BE0);
  static const violet600 = Color(0xFF6E54B5);
  static const violet700 = Color(0xFF4E3A86);
  static const violet800 = Color(0xFF33285A);

  static const green400 = Color(0xFF9FE870);
  static const green500 = Color(0xFF7BC94A);
  static const green600 = Color(0xFF5FA83C);

  static const hazard400 = Color(0xFFF5D020);

  static const mustard400 = Color(0xFFE0A52E);
  static const mustard500 = Color(0xFFC2871B);
  static const coral400 = Color(0xFFE5604A);
  static const coral500 = Color(0xFFCE4A35);
  static const teal400 = Color(0xFF2BA597);
  static const teal500 = Color(0xFF1F8377);

  static const paper50 = Color(0xFFFBF8F1);
  static const paper100 = Color(0xFFF3EFE6);
  static const paper200 = Color(0xFFE9E3D6);
  static const paper300 = Color(0xFFD9D2C2);
  static const paperInk = Color(0xFF1E1A26);

  static const ink50 = Color(0xFFF1EFF6);
  static const ink100 = Color(0xFFE4E0EE);
  static const ink300 = Color(0xFFA59CC0);
  static const ink950 = Color(0xFF16131D);

  static const white = Color(0xFFFFFFFF);

  // ---------- semantic — light ("retro paper") ----------
  static const bg = paper100;
  static const surface = white;
  static const surfaceInset = paper200;

  static const border = Color(0x241E1A26); // rgba(30,26,38,.14)
  static const borderStrong = Color(0x421E1A26); // rgba(30,26,38,.26)

  static const text = paperInk;
  static const textMuted = Color(0xFF5A536E);
  static const textSubtle = Color(0xFF837C95);
  static const textInverse = paper50;

  static const primary = violet600;
  static const primaryHover = violet500;
  static const primaryActive = violet700;
  static const primaryContrast = white;
  static const primarySoft = Color(0x1F6E54B5); // rgba(110,84,181,.12)

  static const accent = green600;
  static const accentSoft = Color(0x245FA83C); // rgba(95,168,60,.14)

  static const warning = mustard500;
  static const danger = coral500;
  static const success = green600;
  static const info = teal500;
}
