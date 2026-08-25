import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, ghost }

enum AppButtonSize { md, lg }

/// Botón neutro del design system. Ver mockup: variant primary/ghost,
/// size md/lg, `full` para ocupar el ancho disponible.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.full = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool full;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final height = size == AppButtonSize.lg ? 50.0 : 44.0;
    final textStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: size == AppButtonSize.lg ? 15.5 : 14.5,
    );

    final Widget child = leading == null
        ? Text(label, style: textStyle)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [leading!, const SizedBox(width: AppSpacing.s2), Text(label, style: textStyle)],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryContrast,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            elevation: 0,
            minimumSize: Size(full ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
      AppButtonVariant.ghost => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            minimumSize: Size(full ? double.infinity : 0, height),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
    };

    return full ? SizedBox(width: double.infinity, child: button) : button;
  }
}
