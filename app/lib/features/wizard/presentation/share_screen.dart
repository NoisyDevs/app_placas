import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../domain/property_enums.dart';
import '../../../placas/placa_preview.dart';
import '../../session/session_controller.dart';

/// Pantalla 10 · "Descargar y compartir". Ojo: ni acá ni en el mockup
/// original hay export de imagen real todavía — los botones son el mismo
/// mock-con-toast que `PlacasApp.dc.html` (`descargar`/`shareWa`/etc. solo
/// llaman `toast(...)`). El exportador real (`placas/export/**`,
/// `share_plus`/`gal`, forzar CanvasKit en web — ARCHITECTURE.md §9 trampa
/// 1) queda para cuando el resto del flujo esté validado.
class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);

    void descargar() {
      // Historia 1.2, último criterio: avisar si el perfil está incompleto
      // (falta foto o WhatsApp) antes de generar. La matrícula queda afuera
      // de este chequeo a propósito — `isCompleteForPlaca` no la exige,
      // porque no todos los templates la requieren.
      if (!session.agent.isCompleteForPlaca) {
        showAppToast(context, 'Completá tu foto y WhatsApp en tu perfil antes de generar una placa.');
        context.go('/profile');
        return;
      }
      if (session.left <= 0) {
        context.go('/upgrade');
        return;
      }
      controller.consume();
      showAppToast(context, 'Placa descargada · lista para publicar');
    }

    return AppWizardScaffold(
      title: 'Descargar y compartir',
      onBack: () => context.go('/new/preview'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 30, offset: Offset(0, 16))],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 1,
              child: PlacaPreview(
                templateId: session.templateId,
                content: session.content,
                agent: session.agent,
                format: PlacaFormat.feed,
                includeContact: session.includeContact,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '✓ LISTA · SIN MARCA DE AGUA',
            style: TextStyle(fontFamily: 'Space Mono', fontSize: 11, letterSpacing: 1.2, color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: '↓ Descargar imagen',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            onPressed: descargar,
          ),
          const SizedBox(height: 18),
          const Text(
            'COMPARTIR DIRECTO',
            style: TextStyle(fontFamily: 'Space Mono', fontSize: 10.5, letterSpacing: 1.4, color: AppColors.textSubtle),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShareTile(
                  label: 'WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  bg: const Color(0xFF25D366),
                  onTap: () => showAppToast(context, 'Abriendo WhatsApp…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  bg: AppColors.violet500,
                  onTap: () => showAppToast(context, 'Compartiendo en Instagram…'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  label: 'Copiar link',
                  icon: Icons.link_rounded,
                  bg: AppColors.surfaceInset,
                  iconColor: AppColors.text,
                  onTap: () => showAppToast(context, 'Link copiado'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Crear otra placa',
            variant: AppButtonVariant.ghost,
            full: true,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.label, required this.icon, required this.bg, required this.onTap, this.iconColor});

  final String label;
  final IconData icon;
  final Color bg;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 20, color: iconColor ?? AppColors.white),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
