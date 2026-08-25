import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../services/supabase_service.dart';

/// Pantalla 01 del mockup ("Login / registro"). Conectada a Supabase Auth
/// real (ARCHITECTURE.md Fase 4): "Crear mi cuenta" registra por
/// email+contraseña, "Iniciá sesión" usa los mismos campos para loguear a
/// una cuenta existente. El local de desarrollo tiene
/// `auth.email.enable_confirmations = false`, así que el registro deja una
/// sesión activa de una — no hace falta un paso de "confirmá tu email"
/// acá.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'martin@propiedades.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SupabaseService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.go('/onboarding');
    } catch (e) {
      if (mounted) showAppToast(context, SupabaseService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SupabaseService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (mounted) showAppToast(context, SupabaseService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'tu@inmobiliaria.com',
                ),
                const SizedBox(height: 14),
                AppTextField(label: 'Contraseña', controller: _passwordController, obscureText: true),
                const SizedBox(height: 14),
                AppButton(
                  label: _busy ? 'Creando cuenta…' : 'Crear mi cuenta',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.lg,
                  full: true,
                  onPressed: _busy ? null : _signUp,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('¿Ya tenés cuenta? ', style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                      InkWell(
                        onTap: _busy ? null : _signIn,
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
