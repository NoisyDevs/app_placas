/// Perfil del agente. Único dato de usuario que persiste (espeja
/// `public.profiles` en Supabase — ver ARCHITECTURE.md §3 y §4).
class AgentProfile {
  const AgentProfile({
    required this.agentId,
    this.nombre = '',
    this.whatsapp = '',
    this.redSocial,
    this.matricula,
    this.fotoPath,
  });

  final String agentId;
  final String nombre;
  final String whatsapp;
  final String? redSocial;
  final String? matricula;

  /// Ruta en Supabase Storage, no una URL directa.
  final String? fotoPath;

  /// Historia 1.2: "La app me avisa si intento generar una placa con el
  /// perfil incompleto (falta foto o WhatsApp)."
  bool get isCompleteForPlaca =>
      nombre.trim().isNotEmpty && whatsapp.trim().isNotEmpty && fotoPath != null;

  AgentProfile copyWith({
    String? nombre,
    String? whatsapp,
    String? redSocial,
    String? matricula,
    String? fotoPath,
  }) {
    return AgentProfile(
      agentId: agentId,
      nombre: nombre ?? this.nombre,
      whatsapp: whatsapp ?? this.whatsapp,
      redSocial: redSocial ?? this.redSocial,
      matricula: matricula ?? this.matricula,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }
}
