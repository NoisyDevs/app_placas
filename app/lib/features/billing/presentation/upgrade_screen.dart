import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_callout.dart';
import '../../../services/backend_client.dart';
import '../../session/session_controller.dart';

/// Pantalla 11 · muro de upgrade (ARCHITECTURE.md §5: se muestra ANTES de
/// que el agente cargue datos si ya está en 0). El botón dispara
/// `POST /v1/billing/subscribe` de verdad — no hay credenciales reales de
/// Mercado Pago en dev, así que esa llamada le falla a MP (401) y el
/// backend la propaga como 500; acá se maneja esa falla con un mensaje
/// claro en vez de simular que la suscripción funcionó (ARCHITECTURE.md
/// §6, máquina de estados: pasar a `pro` solo lo confirma el webhook).
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  BillingStatusResult? _status;
  String? _statusError;
  bool _loadingStatus = true;

  bool _subscribing = false;
  String? _subscribeError;
  SubscribeResult? _subscribeResult;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });
    try {
      final status = await ref.read(backendClientProvider).getBillingStatus();
      if (mounted) setState(() => _status = status);
    } on BackendException catch (e) {
      if (mounted) setState(() => _statusError = 'No pudimos leer tu estado de suscripción. ${e.message}');
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _subscribe() async {
    final email = Supabase.instance.client.auth.currentSession?.user.email;
    if (email == null || email.isEmpty) {
      setState(() => _subscribeError = 'Necesitás una cuenta con email para suscribirte a Mercado Pago.');
      return;
    }
    setState(() {
      _subscribing = true;
      _subscribeError = null;
      _subscribeResult = null;
    });
    try {
      final result = await ref.read(backendClientProvider).subscribe(payerEmail: email);
      if (!mounted) return;
      setState(() => _subscribeResult = result);
    } on BackendException catch (e) {
      if (!mounted) return;
      // Esperado en dev: las credenciales de Mercado Pago son placeholders,
      // así que esto va a fallar hasta que se configuren credenciales
      // reales. El flujo de la app no debe fingir que funcionó.
      setState(() => _subscribeError = e.statusCode == 0
          ? 'No hay conexión con el servidor. Probá de nuevo en unos minutos.'
          : 'No pudimos iniciar el pago con Mercado Pago. Probá de nuevo más tarde o contactá a soporte.');
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

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
                        session.limit == null
                            ? 'Ya usaste todo tu cupo de placas de este mes'
                            : 'Usaste tus ${session.limit} placas gratis del mes',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'DM Serif Display', fontSize: 30, height: 1.1, color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pasá a ilimitado y seguí publicando hoy mismo, sin esperar a que se renueve el mes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink100),
                      ),
                      if (!_loadingStatus && _status != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Estado actual: ${_status!.tier} · ${_status!.status}',
                          style: const TextStyle(fontSize: 12, color: AppColors.ink100),
                        ),
                      ],
                      if (_statusError != null) ...[
                        const SizedBox(height: 10),
                        Text(_statusError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.ink100)),
                      ],
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
                        label: _subscribing ? 'Conectando con Mercado Pago…' : 'Pasar a ilimitado',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.lg,
                        full: true,
                        onPressed: _subscribing ? null : _subscribe,
                      ),
                      if (_subscribeError != null) ...[
                        const SizedBox(height: 12),
                        AppCallout(
                          title: 'No pudimos iniciar el pago',
                          message: _subscribeError!,
                          variant: AppCalloutVariant.violet,
                        ),
                      ],
                      if (_subscribeResult != null) ...[
                        const SizedBox(height: 12),
                        AppCallout(
                          title: 'Suscripción iniciada',
                          message:
                              'Se creó tu suscripción en Mercado Pago (preapproval ${_subscribeResult!.preapprovalId}). '
                              'Completá el pago en: ${_subscribeResult!.initPoint.isEmpty ? '(sin link — revisá con soporte)' : _subscribeResult!.initPoint}. '
                              'Tu plan pasa a Pro apenas Mercado Pago confirme el pago.',
                          variant: AppCalloutVariant.green,
                        ),
                      ],
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
