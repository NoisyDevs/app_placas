import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_switch.dart';
import '../../../domain/property_enums.dart';
import '../../../placas/placa_preview.dart';
import '../../../placas/registry.dart';
import '../../session/session_controller.dart';

/// Pantalla 09 · "Tu placa": el preview ES el output (ARCHITECTURE.md §2,
/// regla 3) — el mismo `PlacaPreview` que se exportaría, solo escalado más
/// chico acá.
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);
    final swatches = templateRegistry.catalog.where((d) => d.kind == session.mode).toList();
    final isStory = session.format == PlacaFormat.story;

    return AppWizardScaffold(
      title: 'Tu placa',
      onBack: () => context.go('/new/templates'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surfaceInset, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormatTab(label: 'Feed 1:1', active: !isStory, onTap: () => controller.setFormat(PlacaFormat.feed)),
                _FormatTab(label: 'Story 9:16', active: isStory, onTap: () => controller.setFormat(PlacaFormat.story)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            width: isStory ? 236 : 300,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 30, offset: Offset(0, 16))],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: isStory ? 9 / 16 : 1,
              child: PlacaPreview(
                templateId: session.templateId,
                content: session.content,
                agent: session.agent,
                format: session.format,
                includeContact: session.includeContact,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Incluir mis datos de contacto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                      SizedBox(height: 2),
                      Text(
                        'Apagado: sale sin foto, nombre ni WhatsApp (para compartir con colegas). Mantiene la matrícula.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                AppSwitch(value: session.includeContact, onChanged: controller.setIncludeContact),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CAMBIAR DISEÑO',
              style: const TextStyle(fontFamily: 'Space Mono', fontSize: 10.5, letterSpacing: 1.4, color: AppColors.textSubtle),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: swatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final descriptor = swatches[index];
                final selected = descriptor.id == session.templateId;
                return InkWell(
                  onTap: () => controller.pickTemplate(descriptor.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 58,
                    height: 58,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2.5),
                    ),
                    child: PlacaPreview(
                      templateId: descriptor.id,
                      content: session.content,
                      agent: session.agent,
                      format: PlacaFormat.feed,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Descargar / compartir →',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            onPressed: () => context.go('/new/share'),
          ),
        ],
      ),
    );
  }
}

class _FormatTab extends StatelessWidget {
  const _FormatTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: active ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: active ? AppColors.text : AppColors.textMuted),
        ),
      ),
    );
  }
}
