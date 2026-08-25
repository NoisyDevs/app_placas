import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Control segmentado de 2 opciones ("Venta" / "Alquiler") — estilo `seg()`
/// del mockup.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T value, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (v, label) in options) ...[
          if (v != options.first.$1) const SizedBox(width: AppSpacing.s2),
          Expanded(child: _segButton(label, v == value, () => onChanged(v))),
        ],
      ],
    );
  }

  Widget _segButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: active ? AppColors.white : AppColors.textMuted),
        ),
      ),
    );
  }
}

/// Chip seleccionable ("Casa", "Departamento"…) — estilo `chip()` del mockup.
/// `Wrap` afuera para que salte de línea con muchas opciones.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({super.key, required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 15),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: active ? AppColors.primary : AppColors.textMuted),
        ),
      ),
    );
  }
}
