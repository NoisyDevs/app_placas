import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../domain/property_enums.dart';
import '../../../placas/placa_preview.dart';
import '../../session/session_controller.dart';

/// Pantalla 12 · "Tus placas". Ledger en memoria de la sesión de la app
/// (ver `SessionController.generatePlaca()`), poblado con cada generación
/// ya confirmada por el backend — `placa_events` en Postgres
/// (ARCHITECTURE.md §4) es la fuente de verdad real, pero no hay endpoint
/// para leer el historial completo desde ahí todavía; la UI no cambia
/// cuando eso se agregue.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return AppWizardScaffold(
      title: 'Tus placas',
      onBack: () => context.go('/home'),
      trailing: Text(
        '${session.history.length} placas',
        style: const TextStyle(fontFamily: 'Space Mono', fontSize: 11, color: AppColors.textSubtle),
      ),
      body: session.history.isEmpty
          ? const _EmptyHistory()
          : Column(
              children: [
                for (final entry in session.history) ...[
                  _HistoryRow(
                    titulo: entry.titulo,
                    fecha: entry.fecha,
                    child: PlacaPreview(
                      templateId: entry.templateId,
                      content: entry.content,
                      agent: session.agent,
                      format: PlacaFormat.feed,
                    ),
                  ),
                  if (entry != session.history.last) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.titulo, required this.fecha, required this.child});

  final String titulo;
  final String fecha;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: child,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.text)),
                const SizedBox(height: 3),
                Text(fecha, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.grid_view_rounded, size: 40, color: AppColors.textSubtle),
          const SizedBox(height: 12),
          const Text('Todavía no generaste ninguna placa', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
