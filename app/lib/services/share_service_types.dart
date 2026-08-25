/// Resultado uniforme de una operación de guardado/compartir, para que
/// `share_screen.dart` pueda mostrar un solo mensaje sin importar cuál de
/// las dos implementaciones de plataforma corrió (`share_service_io.dart` /
/// `share_service_web.dart` — ver `services/share_service.dart`).
class PlacaShareResult {
  const PlacaShareResult.success([this.message]) : ok = true;

  const PlacaShareResult.failure(this.message) : ok = false;

  /// `true` si la acción se completó (guardada, descargada, o el panel de
  /// compartir nativo se abrió correctamente). Un usuario cancelando el
  /// panel de compartir del sistema operativo también cuenta como éxito:
  /// no es un error de la app, así que no debe mostrarse como uno.
  final bool ok;

  /// Mensaje para mostrar al agente (toast). `null` en éxito silencioso.
  final String? message;
}
