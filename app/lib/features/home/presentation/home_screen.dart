import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_bottom_nav.dart';
import '../../../domain/property_enums.dart';
import '../../../placas/placa_preview.dart';
import '../../session/session_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _refreshingQuota = false;

  @override
  void initState() {
    super.initState();
    // ARCHITECTURE.md §5.2: el cupo se lee real (rpc('quota_status')) al
    // entrar — reemplaza el `used`/`limit` de arranque de
    // `SessionState.initial()` apenas la pantalla monta.
    _refreshQuota();
  }

  Future<void> _refreshQuota() async {
    setState(() => _refreshingQuota = true);
    try {
      await ref.read(sessionProvider.notifier).refreshQuota();
    } catch (_) {
      // Lectura de cupo caída: no bloqueamos Home por esto (se sigue
      // mostrando el último cupo conocido) — el gate que de verdad importa
      // es el `POST /v1/placas/consume` del backend al generar, que sí
      // falla cerrado (ARCHITECTURE.md §5.6). Acá solo es una lectura de
      // UX para decidir si mostrar el muro de upgrade antes de tiempo.
    } finally {
      if (mounted) setState(() => _refreshingQuota = false);
    }
  }

  /// Antes de abrir el wizard, vuelve a leer el cupo real (puede haber
  /// cambiado desde que se abrió Home) y manda al muro de upgrade si ya
  /// está en 0 — ARCHITECTURE.md §5.2, "se muestra el muro de upgrade
  /// ANTES de que el agente cargue los datos".
  Future<void> _goCrear() async {
    await _refreshQuota();
    if (!mounted) return;
    final left = ref.read(sessionProvider).left;
    if (left != null && left <= 0) {
      context.go('/upgrade');
    } else {
      context.go('/new');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final firstName = session.agent.nombre.trim().isEmpty ? 'Agente' : session.agent.nombre.trim().split(RegExp(r'\s+')).first;
    final initials = _initials(session.agent.nombre);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hola de nuevo,', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Text(
                          '$firstName 👋',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.4, color: AppColors.text),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(13)),
                      child: Text(initials, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s5),
              _QuotaCard(
                left: session.left,
                limit: session.limit,
                loading: _refreshingQuota && !session.quotaLoaded,
                onTap: () => context.go('/upgrade'),
              ),
              const SizedBox(height: AppSpacing.s4),
              _CreateCta(onTap: _goCrear),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Text('Placas recientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text)),
                  const Spacer(),
                  InkWell(
                    onTap: () => context.go('/history'),
                    child: const Text(
                      'ver todas',
                      style: TextStyle(fontFamily: 'Space Mono', fontSize: 11, letterSpacing: 1.2, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              Row(
                children: [
                  for (final entry in session.history.take(3)) ...[
                    if (entry != session.history.take(3).first) const SizedBox(width: 10),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: DecoratedBox(
                            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), color: AppColors.white),
                            child: PlacaPreview(
                              templateId: entry.templateId,
                              content: entry.content,
                              agent: session.agent,
                              format: PlacaFormat.feed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIsHome: true,
        onHome: () {},
        onCreate: _goCrear,
        onHistory: () => context.go('/history'),
      ),
    );
  }

  static String _initials(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    return parts.take(2).map((s) => s[0]).join().toUpperCase();
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.left, required this.limit, required this.onTap, this.loading = false});

  /// `null` == cupo ilimitado (plan pro/cortesía) — ver `SessionState.left`.
  final int? left;
  final int? limit;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnlimited = limit == null;
    final safeLeft = left ?? 0;
    final color = isUnlimited ? AppColors.accent : (safeLeft <= 2 ? AppColors.danger : (safeLeft <= 5 ? AppColors.warning : AppColors.accent));
    final ratio = isUnlimited || limit == 0 ? 1.0 : safeLeft / limit!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isUnlimited ? 'PLACAS ESTE MES' : 'PLACAS GRATIS ESTE MES',
                  style: const TextStyle(fontFamily: 'Space Mono', fontSize: 11, letterSpacing: 1.2, color: AppColors.textSubtle),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textSubtle),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    isUnlimited ? 'PLAN PRO' : 'PLAN FREE',
                    style: const TextStyle(
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
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: isUnlimited
                  ? [
                      Text('Ilimitado', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: color)),
                    ]
                  : [
                      Text('$safeLeft', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: color)),
                      const SizedBox(width: 8),
                      Text('de $limit restantes',
                          style: const TextStyle(fontSize: 15, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.surfaceInset,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 10),
            if (!isUnlimited)
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  children: [
                    TextSpan(text: 'Se renueva el 1 de agosto · '),
                    TextSpan(text: 'Pasar a ilimitado →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateCta extends StatelessWidget {
  const _CreateCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Crear placa nueva',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.3, color: AppColors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Publicación o búsqueda · en 3 pasos',
                    style: TextStyle(fontSize: 13.5, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
