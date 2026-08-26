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
- **Fuentes**: "Space Mono" y "DM Serif Display" (las que usan los
  templates de este pack) ya están empaquetadas como asset real — ver
  `lib/app/theme/fonts/LICENSES.md`. Viven ahí (junto al design system de
  la app) y no acá, porque ambas familias también las usa el design system
  neutro de la app (`app_theme.dart`), no son exclusivas de este pack; la
  declaración en `pubspec.yaml` las registra de forma global, así que este
  pack las usa igual sin necesitar los archivos localmente. "Space Grotesk"
  (fuente sans del tema de la app, no usada por ningún template de este
  pack) sigue sin empaquetar — ver ARCHITECTURE.md §9 trampa 3.

Ninguno de estos tres puntos bloquea el flujo funcional (login → wizard →
template → preview → compartir): la placa se genera y se ve completa, solo
con un logo/ilustraciones simplificados en vez de arte final.
