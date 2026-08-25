import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_callout.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../placas/kit/contact_strip.dart';
import '../../session/session_controller.dart';

/// Pantalla 03 del mockup ("Perfil"). Los campos se guardan directo en
/// `sessionProvider` en cada `onChanged` — no hay borrador/confirmación
/// separados porque no hay backend todavía (Fase 4 de ARCHITECTURE.md
/// agrega Supabase y ahí sí tiene sentido un guardado explícito con
/// loading/error).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final notifier = ref.read(sessionProvider.notifier);
    final agent = session.agent;

    return AppWizardScaffold(
      title: 'Mi perfil',
      onBack: () => context.go('/home'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  ContactStrip.initialsOf(agent.nombre),
                  style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.edit_outlined, size: 15, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('TOCÁ PARA CAMBIAR LA FOTO', style: appMonoKicker.copyWith(fontSize: 11)),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Nombre y apellido',
            initialValue: agent.nombre,
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(nombre: v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'WhatsApp',
            initialValue: agent.whatsapp,
            keyboardType: TextInputType.phone,
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(whatsapp: v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Red social (opcional)',
            initialValue: agent.redSocial ?? '',
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(redSocial: v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Matrícula (opcional)',
            initialValue: agent.matricula ?? '',
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(matricula: v)),
          ),
          const SizedBox(height: 16),
          const AppCallout(
            variant: AppCalloutVariant.violet,
            title: 'Se estampan solos',
            message: 'Estos datos aparecen automáticamente en todas tus placas. Los cargás una sola vez.',
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Guardar y continuar',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
