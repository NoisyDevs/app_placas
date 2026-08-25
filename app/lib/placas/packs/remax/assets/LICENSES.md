# Assets del pack RE/MAX

Este directorio está vacío a propósito por ahora — `app/pubspec.yaml` lo
declara bajo `flutter: assets:`, así que necesita existir para que
`flutter pub get` / el build no fallen buscando el directorio, aunque
todavía no tenga archivos binarios adentro.

## Estado actual

- **Logo RE/MAX**: no hay un `.svg`/`.png` oficial embebido en este repo.
  `remax_brand.dart` dibuja una versión simplificada (3 barras de color +
  wordmark) directamente en Flutter, fiel al mockup (`Placa.dc.html`), para
  no depender de un archivo de logo cuya procedencia/licencia no esté
  confirmada. Antes de producción hay que reemplazar esto por el asset
  oficial con las guías de marca reales.
- **Ilustraciones de búsqueda** (placa sin fotos, "busco una propiedad"):
  hoy son íconos de Material Icons por `TipoPropiedad`
  (`remax_photo.dart`), no imágenes ilustradas. Ver
  `requerimientos-placas-remax-mvp.md` ("Preguntas abiertas") y
  ARCHITECTURE.md §9 trampa 7: usar "cualquier imagen de Google" acá es un
  riesgo legal real al lado del logo de RE/MAX — esto debe resolverse con
  ilustraciones encargadas o un set explícitamente licenciado antes de
  salir a producción, documentado en este mismo archivo cuando exista.
- **Fuentes** ("Space Grotesk", "Space Mono", "DM Serif Display"): tampoco
  están empaquetadas todavía — ver ARCHITECTURE.md §9 trampa 3 (nada de
  fetch de fuentes en runtime para el contenido de una placa).

Ninguno de estos tres puntos bloquea el flujo funcional (login → wizard →
template → preview → compartir): la placa se genera y se ve completa, solo
con un logo/ilustraciones simplificados en vez de arte final.
