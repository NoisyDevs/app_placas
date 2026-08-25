import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_text_field.dart';

/// Pantalla 01 del mockup ("Login / registro"). Sin backend todavía
/// (ARCHITECTURE.md Fase 4: Supabase Auth) — los dos botones solo navegan.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.dashboard_rounded, color: AppColors.white, size: 24),
                    ),
                    const SizedBox(width: 11),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5, color: AppColors.text),
                        children: [
                          TextSpan(text: 'Placas'),
                          TextSpan(text: '_', style: TextStyle(color: AppColors.accent)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Placas de marketing en segundos.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 30, height: 1.08),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cargá tu propiedad, elegí un diseño y descargá la placa lista para '
                  'Instagram y WhatsApp. Sin saber diseño.',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 26),
                const AppTextField(label: 'Email', initialValue: 'martin@propiedades.com', hint: 'tu@inmobiliaria.com'),
                const SizedBox(height: 14),
                const AppTextField(label: 'Contraseña', initialValue: '123456', obscureText: true),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Crear mi cuenta',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.lg,
                  full: true,
                  onPressed: () => context.go('/onboarding'),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('¿Ya tenés cuenta? ', style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                      InkWell(
                        onTap: () => context.go('/home'),
                        child: const Text(
                          'Iniciá sesión',
                          style: TextStyle(fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text('PLAN GRATIS · 10 PLACAS POR MES', style: appMonoKicker.copyWith(fontSize: 10.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
