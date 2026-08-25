import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_callout.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../app/widgets/app_toast.dart';
import '../../../placas/kit/contact_strip.dart';
import '../../../services/supabase_service.dart';
import '../../session/session_controller.dart';

/// Pantalla 03 del mockup ("Perfil"). Los campos de texto se siguen
/// guardando en `sessionProvider` en cada `onChanged` (borrador local, sin
/// pegarle a Supabase por tecla) — "Guardar y continuar" es el único punto
/// que persiste, con loading/error explícitos, como corresponde ahora que
/// hay un backend real detrás (ARCHITECTURE.md Fase 4). La foto se sube
/// aparte, al tocarla, porque su "guardado" es la subida en sí.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _saving = false;
  bool _uploadingPhoto = false;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadAvatarIfNeeded();
  }

  Future<void> _loadAvatarIfNeeded() async {
    final path = ref.read(sessionProvider).agent.fotoPath;
    if (path == null) return;
    try {
      final bytes = await SupabaseService.instance.downloadAvatar(path);
      if (mounted) setState(() => _avatarBytes = bytes);
    } catch (_) {
      // Silencioso: si falla la descarga se siguen mostrando las iniciales,
      // no es un error bloqueante para editar el resto del perfil.
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;
    final agentId = ref.read(sessionProvider).agent.agentId;
    if (agentId.isEmpty) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (_) {
      if (mounted) showAppToast(context, 'No pudimos abrir la galería.');
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      // Siempre bytes, nunca una ruta de disco (ARCHITECTURE.md §7: el
      // pipeline de fotos es bytes-only e idéntico en mobile/web).
      final bytes = await picked.readAsBytes();
      final extension = _extensionOf(picked.name);
      final path = await SupabaseService.instance.uploadAvatar(
        agentId: agentId,
        bytes: bytes,
        extension: extension,
      );
      if (!mounted) return;
      ref.read(sessionProvider.notifier).updateAgent((a) => a.copyWith(fotoPath: path));
      setState(() => _avatarBytes = bytes);
    } catch (e) {
      if (mounted) showAppToast(context, SupabaseService.describeError(e));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (dot == -1 || dot == fileName.length - 1) return 'jpg';
    final ext = fileName.substring(dot + 1).toLowerCase();
    return allowed.contains(ext) ? ext : 'jpg';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final current = ref.read(sessionProvider).agent;
      final saved = await SupabaseService.instance.upsertProfile(current);
      if (!mounted) return;
      ref.read(sessionProvider.notifier).updateAgent((_) => saved);
      context.go('/home');
    } catch (e) {
      if (mounted) showAppToast(context, SupabaseService.describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final notifier = ref.read(sessionProvider.notifier);
    final agent = session.agent;

    return AppWizardScaffold(
      title: 'Mi perfil',
      onBack: () => context.go('/home'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: _avatarBytes != null
                      ? Image.memory(_avatarBytes!, width: 88, height: 88, fit: BoxFit.cover)
                      : Text(
                          ContactStrip.initialsOf(agent.nombre),
                          style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                ),
                if (_uploadingPhoto)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.edit_outlined, size: 15, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('TOCÁ PARA CAMBIAR LA FOTO', style: appMonoKicker.copyWith(fontSize: 11)),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Nombre y apellido',
            initialValue: agent.nombre,
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(nombre: v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'WhatsApp',
            initialValue: agent.whatsapp,
            keyboardType: TextInputType.phone,
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(whatsapp: v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Red social (opcional)',
            initialValue: agent.redSocial ?? '',
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(redSocial: v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Matrícula (opcional)',
            initialValue: agent.matricula ?? '',
            onChanged: (v) => notifier.updateAgent((a) => a.copyWith(matricula: v)),
          ),
          const SizedBox(height: 16),
          const AppCallout(
            variant: AppCalloutVariant.violet,
            title: 'Se estampan solos',
            message: 'Estos datos aparecen automáticamente en todas tus placas. Los cargás una sola vez.',
          ),
          const SizedBox(height: 18),
          AppButton(
            label: _saving ? 'Guardando…' : 'Guardar y continuar',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.lg,
            full: true,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
