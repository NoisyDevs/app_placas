import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Scaffold con header "back + título" repetido en casi todas las pantallas
/// del wizard en el mockup (flecha izquierda, título, opcional trailing).
class AppWizardScaffold extends StatelessWidget {
  const AppWizardScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.trailing,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(22, 20, 22, 30),
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool scrollable;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = scrollable ? SingleChildScrollView(padding: padding, child: body) : Padding(padding: padding, child: body);

    // Scaffold, no un Column pelado: un Column no provee un ancestro
    // Material, así que cualquier InkWell/InkResponse dentro de `body` (o
    // en el propio header, como el botón de "atrás" de acá abajo) tira
    // "No Material widget found" — y el ErrorWidget que reemplaza al
    // widget roto intenta expandirse sin límite dentro del primer hijo
    // (no-Expanded) del Column, lo que se ve como un overflow de decenas
    // de miles de píxeles. Scaffold resuelve las dos cosas: da el
    // ancestro Material y maneja SafeArea/background por sí solo.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (onBack != null)
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.text),
                      ),
                    ),
                  if (onBack != null) const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.text)),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
          Expanded(child: SafeArea(top: false, child: content)),
        ],
      ),
    );
  }
}
