import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_callout.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_selectors.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../domain/property_enums.dart';
import '../../session/session_controller.dart';

const _tiposRapidos = [TipoPropiedad.casa, TipoPropiedad.departamento, TipoPropiedad.ph, TipoPropiedad.lote];

/// Pantalla 07 · "Cargar búsqueda" (Historia 2.5): sin fotos — el resolver
/// usa una ilustración genérica según `tipo` (ver
/// las ilustraciones del pack activo, ver `placas/packs/`).
class LoadSearchScreen extends ConsumerWidget {
  const LoadSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sessionProvider).searchDraft;
    final controller = ref.read(sessionProvider.notifier);
    void update(SearchDraft Function(SearchDraft) fn) => controller.updateSearch(fn);

    return AppWizardScaffold(
      title: 'Cargar búsqueda',
      onBack: () => context.go('/new'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCallout(
            variant: AppCalloutVariant.green,
            message: 'No necesitás fotos: usamos una imagen genérica según el tipo buscado.',
          ),
          const SizedBox(height: AppSpacing.s4),
          const _SectionLabel('Operación buscada'),
          AppSegmented<OperacionBuscada>(
            options: const [(OperacionBuscada.compra, 'Compra'), (OperacionBuscada.alquiler, 'Alquiler')],
            value: draft.operacion,
            onChanged: (v) => update((d) => d.copyWith(operacion: v)),
          ),
          const SizedBox(height: AppSpacing.s4),
          const _SectionLabel('Tipo buscado'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tipo in _tiposRapidos)
                AppChoiceChip(label: tipo.label, active: draft.tipo == tipo, onTap: () => update((d) => d.copyWith(tipo: tipo))),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          AppTextField(label: 'Zona buscada', initialValue: draft.zona, onChanged: (v) => update((d) => d.copyWith(zona: v))),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Presupuesto máx. (opcional)',
            keyboardType: TextInputType.number,
            initialValue: draft.presupuesto?.toString() ?? '',
            onChanged: (v) => update((d) => d.copyWith(presupuesto: v.isEmpty ? null : num.tryParse(v))),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Ambientes',
                  keyboardType: TextInputType.number,
                  initialValue: draft.ambientes?.toString() ?? '',
                  onChanged: (v) => update((d) => d.copyWith(ambientes: int.tryParse(v))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Dormitorios',
                  keyboardType: TextInputType.number,
                  initialValue: draft.dormitorios?.toString() ?? '',
                  onChanged: (v) => update((d) => d.copyWith(dormitorios: int.tryParse(v))),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Elegir template →',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            onPressed: () => context.go('/new/templates'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Space Mono', fontSize: 11, letterSpacing: 1.2, color: AppColors.textSubtle),
      ),
    );
  }
}
