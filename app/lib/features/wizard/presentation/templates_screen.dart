import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../domain/property_enums.dart';
import '../../../placas/placa_preview.dart';
import '../../../placas/registry.dart';
import '../../session/session_controller.dart';

/// Pantalla 08 · "Elegí un template": 5 diseños, ya con los datos
/// cargados en el paso anterior — cada celda es una `PlacaPreview` en vivo,
/// no una imagen estática (por eso `TemplateDescriptor.thumbAsset` queda
/// sin usar por ahora, ver los templates del pack activo bajo
/// `placas/packs/`).
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final options = templateRegistry.catalog.where((d) => d.kind == session.mode).toList();

    return AppWizardScaffold(
      title: 'Elegí un template',
      onBack: () => context.go(session.mode == PlacaKind.publicacion ? '/new/property' : '/new/search'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5 diseños profesionales con tus datos ya cargados.', style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.s4),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
            children: [
              for (final descriptor in options)
                _TemplateCell(
                  selected: descriptor.id == session.templateId,
                  label: descriptor.nombre,
                  onTap: () => controller.pickTemplate(descriptor.id),
                  child: PlacaPreview(
                    templateId: descriptor.id,
                    content: session.content,
                    agent: session.agent,
                    format: PlacaFormat.feed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Ver mi placa →',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            onPressed: () => context.go('/new/preview'),
          ),
        ],
      ),
    );
  }
}

class _TemplateCell extends StatelessWidget {
  const _TemplateCell({required this.selected, required this.label, required this.onTap, required this.child});

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: DecoratedBox(decoration: const BoxDecoration(color: AppColors.white), child: child),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: selected ? AppColors.primary : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
