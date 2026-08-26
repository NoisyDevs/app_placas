import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../domain/property_enums.dart';
import '../../../placas/export/placa_exporter.dart';
import '../../../placas/placa_preview.dart';
import '../../../services/backend_client.dart';
import '../../../services/share_service.dart';
import '../../session/session_controller.dart';

/// Pantalla 10 · "Descargar y compartir". Export real: el `RepaintBoundary`
/// de acá abajo envuelve el `PlacaPreview` (que internamente pinta un
/// `PlacaCanvas`) tal cual se ve en pantalla — VISIBLE, nunca dentro de un
/// `Offstage: true` (ARCHITECTURE.md §9, trampa 2) — y `capturePlacaPng`
/// compensa la escala del `FittedBox` con `pixelRatio` para emitir siempre
/// el PNG a resolución real (1080×1080 / 1080×1920), sin importar el
/// tamaño con el que se esté mostrando este preview. El crédito se pide de
/// verdad al backend (`generatePlaca`, ARCHITECTURE.md §5.3-4) antes de
/// capturar — el render solo corre después de `granted`.
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;

  /// `true` una vez que el backend ya otorgó el crédito de generación para
  /// la placa de ESTA visita (ARCHITECTURE.md §4, "1 placa = 1 acto de
  /// generación"). Descargar y compartir la MISMA placa en la misma visita
  /// van todas por acá — solo la primera llamada exitosa a
  /// `generatePlaca()` consume cupo real; las siguientes (otro botón de
  /// compartir, otro tap) reusan `_granted` y solo vuelven a capturar/
  /// guardar, sin pedirle un segundo crédito al backend.
  bool _granted = false;

  Future<void> _runExport(
    Future<PlacaShareResult> Function(Uint8List bytes, {required String fileName}) action,
  ) async {
    if (_busy) return;

    final session = ref.read(sessionProvider);

    // Historia 1.2, último criterio: avisar si el perfil está incompleto
    // (falta foto o WhatsApp) antes de generar. La matrícula queda afuera
    // de este chequeo a propósito — `isCompleteForPlaca` no la exige,
    // porque no todos los templates la requieren.
    if (!session.agent.isCompleteForPlaca) {
      showAppToast(context, 'Completá tu foto y WhatsApp en tu perfil antes de generar una placa.');
      context.go('/profile');
      return;
    }
    // `session.left == null` es cupo ilimitado (pro/cortesía) — nunca
    // bloquea. Este chequeo es solo un atajo local para no gastar una
    // llamada de red cuando ya sabemos que está en cero; el backend
    // (`generatePlaca` más abajo) es la fuente de verdad real.
    if (!_granted && session.left != null && session.left! <= 0) {
      context.go('/upgrade');
      return;
    }

    setState(() => _busy = true);
    try {
      if (!_granted) {
        final controller = ref.read(sessionProvider.notifier);
        final backendClient = ref.read(backendClientProvider);
        try {
          final outcome = await controller.generatePlaca(backendClient);
          if (outcome == GenerateOutcome.quotaExceeded) {
            if (mounted) context.go('/upgrade');
            return;
          }
        } on QuotaExceededException {
          if (mounted) context.go('/upgrade');
          return;
        } on BackendException catch (e) {
          if (mounted) {
            showAppToast(
              context,
              e.statusCode == 0
                  ? 'No hay conexión con el servidor. Probá de nuevo.'
                  : 'No pudimos generar la placa. Probá de nuevo.',
            );
          }
          return;
        }
        _granted = true;
      }

      final Uint8List bytes;
      try {
        bytes = await capturePlacaPng(boundaryKey: _boundaryKey, format: session.format);
      } on PlacaExportException catch (e) {
        if (mounted) showAppToast(context, e.message);
        return;
      }

      final fileName = _fileNameFor(session.format);
      final result = await action(bytes, fileName: fileName);
      if (!mounted) return;

      showAppToast(context, result.message ?? (result.ok ? 'Listo.' : 'Algo salió mal.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fileNameFor(PlacaFormat format) {
    final tag = format == PlacaFormat.story ? 'story' : 'feed';
    return 'placa-$tag-${DateTime.now().millisecondsSinceEpoch}.png';
  }

  void _handleSave() => _runExport(savePlaca);

  void _handleShare() => _runExport(sharePlaca);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isStory = session.format == PlacaFormat.story;

    return AppWizardScaffold(
      title: 'Descargar y compartir',
      onBack: () => context.go('/new/preview'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isStory ? 180 * 9 / 16 : 180,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 30, offset: Offset(0, 16))],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: isStory ? 9 / 16 : 1,
              // El RepaintBoundary tiene que envolver justo lo que se ve
              // — sin el Container/boxShadow de arriba, que no son parte
              // de la placa — para que `capturePlacaPng` capture
              // exactamente lo que el agente está mirando.
              child: RepaintBoundary(
                key: _boundaryKey,
                child: PlacaPreview(
                  templateId: session.templateId,
                  content: session.content,
                  agent: session.agent,
                  format: session.format,
                  includeContact: session.includeContact,
                ),
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
            label: _busy ? 'Generando…' : '↓ Descargar imagen',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            leading: _busy ? const _MiniSpinner(color: AppColors.primaryContrast) : null,
            onPressed: _busy ? null : _handleSave,
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
                  enabled: !_busy,
                  onTap: _handleShare,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                  bg: AppColors.violet500,
                  enabled: !_busy,
                  onTap: _handleShare,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareTile(
                  // No hay "link" que copiar: la placa no vive en ningún
                  // servidor (ARCHITECTURE.md — one-shot, nunca se sube a
                  // un backend). Las tres tiles abren el mismo panel de
                  // compartir del sistema; ahí el agente elige el destino.
                  label: 'Compartir',
                  icon: Icons.ios_share_rounded,
                  bg: AppColors.surfaceInset,
                  iconColor: AppColors.text,
                  enabled: !_busy,
                  onTap: _handleShare,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Crear otra placa',
            variant: AppButtonVariant.ghost,
            full: true,
            onPressed: _busy ? null : () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _MiniSpinner extends StatelessWidget {
  const _MiniSpinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 15,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.label,
    required this.icon,
    required this.bg,
    required this.onTap,
    this.iconColor,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color? iconColor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(13),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
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
      ),
    );
  }
}
