import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Switch neutro (46x26 en el mockup) sobre el `Switch.adaptive` de Material.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.white,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: AppColors.white,
      inactiveTrackColor: AppColors.surfaceInset,
    );
  }
}
