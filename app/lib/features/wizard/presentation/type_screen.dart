import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../domain/property_enums.dart';
import '../../session/session_controller.dart';

/// Pantalla 05 · "¿Qué querés comunicar?" — el fork del flujo entre
/// publicación (propiedad concreta) y búsqueda (sin fotos, en nombre de un
/// cliente). Fija `SessionState.mode` antes de entrar al formulario
/// correspondiente.
class TypeScreen extends ConsumerWidget {
  const TypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(sessionProvider.notifier);

    return AppWizardScaffold(
      title: 'Nueva placa',
      onBack: () => context.go('/home'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Qué querés comunicar?', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.s5),
          _TypeCard(
            icon: Icons.home_work_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySoft,
            title: 'Publicación',
            description: 'Tengo una propiedad concreta para publicar y quiero mostrarla.',
            onTap: () {
              controller.setMode(PlacaKind.publicacion);
              context.go('/new/property');
            },
          ),
          const SizedBox(height: AppSpacing.s3),
          _TypeCard(
            icon: Icons.search_rounded,
            iconColor: AppColors.accent,
            iconBg: AppColors.accentSoft,
            title: 'Búsqueda',
            description: 'Busco una propiedad para un cliente y quiero difundir qué necesito.',
            onTap: () {
              controller.setMode(PlacaKind.busqueda);
              context.go('/new/search');
            },
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
