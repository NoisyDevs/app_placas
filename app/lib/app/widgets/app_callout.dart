import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppCalloutVariant { violet, green }

/// Recuadro informativo neutro ("Se estampan solos", "No necesitás fotos…").
class AppCallout extends StatelessWidget {
  const AppCallout({
    super.key,
    required this.message,
    this.title,
    this.variant = AppCalloutVariant.violet,
  });

  final String message;
  final String? title;
  final AppCalloutVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color fg = variant == AppCalloutVariant.violet ? AppColors.primary : AppColors.accent;
    final Color bg = variant == AppCalloutVariant.violet ? AppColors.primarySoft : AppColors.accentSoft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: fg)),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            style: TextStyle(fontSize: 13, height: 1.4, color: fg.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}
