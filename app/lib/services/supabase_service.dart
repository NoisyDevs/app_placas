import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/agent_profile.dart';

/// Wrapper delgado sobre `Supabase.instance.client`: auth + CRUD de
/// `public.profiles` + subida/lectura de la foto de perfil en Storage
/// (ARCHITECTURE.md Fase 4). Ningún widget debería importar
/// `package:supabase_flutter` directamente fuera de acá — así el resto de
/// la app solo conoce `AgentProfile` (Dart puro), nunca un `PostgrestMap`.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static const _avatarsBucket = 'avatars';
  static const _profilesTable = 'profiles';

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------- auth --

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  /// Emite cada vez que cambia el estado de auth (login, logout, token
  /// refresheado, sesión recuperada del storage local al abrir la app) —
  /// es lo que alimenta `GoRouterRefreshStream` en `app/router.dart` para
  /// que la sesión persista entre usos (Historia 1.1).
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({required String email, required String password}) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Extrae un mensaje mostrable de cualquier error de auth/red, sin que el
  /// caller necesite importar `AuthException` de `supabase_flutter`.
  static String describeError(Object error) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    return 'No pudimos conectar con el servidor. Probá de nuevo.';
  }

  // ------------------------------------------------------------ profile --

  /// Lee la fila de `public.profiles` del agente autenticado. El trigger
  /// `on_auth_user_created` (`supabase/schema.sql`) garantiza que la fila
  /// ya existe desde el registro, así que esto nunca debería devolver
  /// "no encontrado" en la práctica — el fallback de perfil vacío de abajo
  /// es solo defensivo.
  Future<AgentProfile> fetchProfile() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No hay sesión activa: no se puede leer el perfil.');
    }
    final rows = await _client.from(_profilesTable).select().eq('agent_id', user.id).limit(1);
    if (rows.isEmpty) {
      return AgentProfile(agentId: user.id);
    }
    return _fromRow(rows.first);
  }

  /// Guarda nombre/whatsapp/red social/matrícula. RLS (`profiles_update_own`
  /// / `profiles_insert_own`) garantiza que un agente solo puede escribir su
  /// propia fila — acá se usa `upsert` en vez de `update` para que igual
  /// funcione en el caso borde de que la fila todavía no exista.
  Future<AgentProfile> upsertProfile(AgentProfile profile) async {
    final row = await _client
        .from(_profilesTable)
        .upsert({
          'agent_id': profile.agentId,
          'nombre': profile.nombre,
          'whatsapp': profile.whatsapp,
          'red_social': profile.redSocial,
          'matricula': profile.matricula,
        })
        .select()
        .single();
    return _fromRow(row);
  }

  /// Sube la foto de perfil a `avatars/{agentId}/foto.<ext>` (bucket privado,
  /// políticas por carpeta — ver `supabase/migrations/*_avatars_bucket.sql`)
  /// y actualiza `foto_path` en `profiles` con la RUTA, nunca una URL
  /// completa (así lo documenta `supabase/schema.sql`).
  Future<String> uploadAvatar({
    required String agentId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '$agentId/foto.$extension';
    await _client.storage
        .from(_avatarsBucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: _mimeFor(extension), upsert: true));
    await _client.from(_profilesTable).update({'foto_path': path}).eq('agent_id', agentId);
    return path;
  }

  /// Descarga los bytes de la foto de perfil ya subida, para mostrarla en
  /// la UI (bucket privado: no hay URL pública que pegar en un `Image.network`).
  Future<Uint8List> downloadAvatar(String path) {
    return _client.storage.from(_avatarsBucket).download(path);
  }

  AgentProfile _fromRow(Map<String, dynamic> row) => AgentProfile(
        agentId: row['agent_id'] as String,
        nombre: row['nombre'] as String? ?? '',
        whatsapp: row['whatsapp'] as String? ?? '',
        redSocial: row['red_social'] as String?,
        matricula: row['matricula'] as String?,
        fotoPath: row['foto_path'] as String?,
      );

  static String _mimeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
