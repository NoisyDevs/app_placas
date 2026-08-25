import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/app_button.dart';

class _Step {
  const _Step(this.icon, this.title, this.description, {this.accent = false});
  final IconData icon;
  final String title;
  final String description;
  final bool accent;
}

const _steps = [
  _Step(Icons.add_rounded, '1 · Cargá los datos', 'Precio, zona, ambientes y fotos de la propiedad.'),
  _Step(Icons.grid_view_rounded, '2 · Elegí un template', 'Diseños profesionales listos. Vos solo elegís.'),
  _Step(Icons.download_rounded, '3 · Descargá y publicá', 'Feed 1:1 o story 9:16. Sin marca de agua.', accent: true),
];

/// Pantalla 02 del mockup ("Onboarding").
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('// BIENVENIDO', style: appMonoKicker.copyWith(color: AppColors.primary, fontSize: 11)),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 30, height: 1.1, color: AppColors.text),
                  children: const [
                    TextSpan(text: 'Así funciona '),
                    TextSpan(text: 'Placas', style: TextStyle(color: AppColors.primary, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tres pasos y tu propiedad está lista para publicar.',
                style: TextStyle(fontSize: 14.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: ListView.separated(
                  itemCount: _steps.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _stepCard(_steps[i]),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Configurar mi perfil →',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.lg,
                full: true,
                onPressed: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(_Step step) {
    final fg = step.accent ? AppColors.accent : AppColors.primary;
    final bg = step.accent ? AppColors.accentSoft : AppColors.primarySoft;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Icon(step.icon, size: 18, color: fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(step.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
