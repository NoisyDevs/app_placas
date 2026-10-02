import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_selectors.dart';
import '../../../app/widgets/app_switch.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../domain/property_enums.dart';
import '../../../services/photo_normalizer.dart';
import '../../session/session_controller.dart';

const _tiposRapidos = [TipoPropiedad.casa, TipoPropiedad.departamento, TipoPropiedad.ph, TipoPropiedad.lote];

/// Pantalla 06 · "Cargar propiedad" (Historia 2.1). Un solo paso en el
/// mockup (no hay wizard multi-step real todavía, "1 / 3" es decorativo
/// como en `PlacasApp.dc.html`) que arma `SessionState.propertyDraft`.
class LoadPropertyScreen extends ConsumerWidget {
  const LoadPropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sessionProvider).propertyDraft;
    final controller = ref.read(sessionProvider.notifier);
    void update(PropertyDraft Function(PropertyDraft) fn) => controller.updateProperty(fn);

    return AppWizardScaffold(
      title: 'Cargar propiedad',
      onBack: () => context.go('/new'),
      trailing: const Text('1 / 3', style: TextStyle(fontFamily: 'Space Mono', fontSize: 11, color: AppColors.textSubtle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Operación'),
          AppSegmented<Operacion>(
            options: const [(Operacion.venta, 'Venta'), (Operacion.alquiler, 'Alquiler')],
            value: draft.operacion,
            onChanged: (v) => update((d) => d.copyWith(operacion: v)),
          ),
          const SizedBox(height: AppSpacing.s4),
          const _SectionLabel('Tipo de propiedad'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tipo in _tiposRapidos)
                AppChoiceChip(label: tipo.label, active: draft.tipo == tipo, onTap: () => update((d) => d.copyWith(tipo: tipo))),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Precio',
                  keyboardType: TextInputType.number,
                  initialValue: draft.precio.toString(),
                  onChanged: (v) => update((d) => d.copyWith(precio: num.tryParse(v) ?? d.precio)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Moneda'),
                    AppSegmented<Moneda>(
                      options: const [(Moneda.usd, 'USD'), (Moneda.ars, r'$')],
                      value: draft.moneda,
                      onChanged: (v) => update((d) => d.copyWith(moneda: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ocultar precio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
                      Text('Muestra "Consultar" en la placa', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                AppSwitch(value: draft.ocultarPrecio, onChanged: (v) => update((d) => d.copyWith(ocultarPrecio: v))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppTextField(label: 'Zona / barrio', initialValue: draft.zona, onChanged: (v) => update((d) => d.copyWith(zona: v))),
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
                  label: 'Dormit.',
                  keyboardType: TextInputType.number,
                  initialValue: draft.dormitorios?.toString() ?? '',
                  onChanged: (v) => update((d) => d.copyWith(dormitorios: int.tryParse(v))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Baños',
                  keyboardType: TextInputType.number,
                  initialValue: draft.banos?.toString() ?? '',
                  onChanged: (v) => update((d) => d.copyWith(banos: int.tryParse(v))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Superficie m²',
                  keyboardType: TextInputType.number,
                  initialValue: draft.superficieM2?.toString() ?? '',
                  onChanged: (v) => update((d) => d.copyWith(superficieM2: num.tryParse(v))),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => update((d) => d.copyWith(cochera: !d.cochera)),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: draft.cochera ? AppColors.primarySoft : Colors.transparent,
                    border: Border.all(color: draft.cochera ? AppColors.primary : AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 18, color: draft.cochera ? AppColors.primary : AppColors.textMuted),
                      const SizedBox(width: 7),
                      Text(
                        'Cochera',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: draft.cochera ? AppColors.primary : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          const _SectionLabel('Fotos'),
          _PhotoGrid(fotos: draft.fotos, onChanged: (fotos) => update((d) => d.copyWith(fotos: fotos))),
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

/// Selector de fotos: siempre `XFile.readAsBytes()` (nunca una ruta/URL) —
/// mismo pipeline bytes-only en mobile y web, ver ARCHITECTURE.md §7.
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.fotos, required this.onChanged});

  final List<Uint8List> fotos;
  final ValueChanged<List<Uint8List>> onChanged;

  static const _maxFotos = 4;

  Future<void> _pick(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final bytes = await normalizePhotoOrientation(await file.readAsBytes());
    final next = [...fotos, bytes];
    onChanged(next.length > _maxFotos ? next.sublist(next.length - _maxFotos) : next);
  }

  void _remove(int index) {
    final next = [...fotos]..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        for (var i = 0; i < fotos.length; i++)
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(fotos[i], fit: BoxFit.cover),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: () => _remove(i),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (fotos.length < _maxFotos)
          InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.borderStrong, width: 2),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
