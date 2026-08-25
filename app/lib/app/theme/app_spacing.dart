/// Grilla de 4px y radios/duraciones, portados de
/// `tokens/spacing.css` + `tokens/effects.css` del mockup.
abstract final class AppSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 40.0;
  static const s8 = 48.0;
}

abstract final class AppRadius {
  static const xs = 3.0;
  static const sm = 5.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 18.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 360);
}
