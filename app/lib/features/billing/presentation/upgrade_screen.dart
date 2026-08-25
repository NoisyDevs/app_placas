import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_toast.dart';
import '../../session/session_controller.dart';

/// Pantalla 11 · muro de upgrade (ARCHITECTURE.md §5: se muestra ANTES de
/// que el agente cargue datos si ya está en 0). `upgradeNow()` acá es fake
/// local — la suscripción real de Mercado Pago (§6) llega en Fase 6.
class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final controller = ref.read(sessionProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.violet800, AppColors.bg],
            stops: [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: InkWell(
                    onTap: () => context.go('/home'),
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(Icons.close_rounded, color: AppColors.white, size: 24),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.hazard400, borderRadius: BorderRadius.circular(22)),
                        child: const Icon(Icons.bolt_rounded, color: AppColors.text, size: 40),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'LÍMITE ALCANZADO',
                        style: TextStyle(fontFamily: 'Space Mono', fontSize: 11, letterSpacing: 1.6, color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usaste tus ${session.limit} placas gratis del mes',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'DM Serif Display', fontSize: 30, height: 1.1, color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pasá a ilimitado y seguí publicando hoy mismo, sin esperar a que se renueve el mes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink100),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Ilimitado', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                                  child: const Text(
                                    'RECOMENDADO',
                                    style: TextStyle(
                                      fontFamily: 'Space Mono',
                                      fontSize: 9.5,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'USD 10',
                                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.text),
                                  ),
                                  TextSpan(text: ' / mes', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _Bullet('Placas ilimitadas todos los meses'),
                            const SizedBox(height: 11),
                            const _Bullet('Los 5 templates, feed y story'),
                            const SizedBox(height: 11),
                            const _Bullet('Descargas sin marca de agua'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      AppButton(
                        label: 'Pasar a ilimitado',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.lg,
                        full: true,
                        onPressed: () {
                          controller.upgradeNow();
                          showAppToast(context, '¡Listo! Ahora tenés placas ilimitadas');
                          context.go('/home');
                        },
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => context.go('/home'),
                        child: const Text('Quizás después', style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.text))),
      ],
    );
  }
}
