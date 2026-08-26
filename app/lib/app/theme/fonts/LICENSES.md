# Fuentes del design system de la app

Estas dos familias son las fuentes reales (no fallback del sistema) del
design system **neutro** de la app (`lib/app/theme/app_theme.dart`,
`appMonoKicker`, y las pantallas bajo `lib/features/**` que las consumen vía
`Theme.of(context)` o el literal `fontFamily`).

También las usan, por nombre, los templates del pack RE/MAX
(`lib/placas/packs/remax/templates/*.dart`, `remax_photo.dart`) — el mockup
original las eligió para ambos contextos. Esto es solo una coincidencia de
diseño, no una dependencia: `flutter: fonts:` en `pubspec.yaml` registra una
familia tipográfica de forma global para todo el proceso de Flutter, así que
cualquier `TextStyle(fontFamily: 'Space Mono')` en cualquier parte del árbol
de widgets la resuelve sin importar en qué carpeta viven los `.ttf` ni si ese
código importa este paquete. Por eso los archivos viven acá (`app/theme/`,
junto al design system que los declara como propios) y no bajo
`placas/packs/remax/assets/`: si el pack de RE/MAX se reemplaza el día de
mañana por el pack de otra inmobiliaria (ver CLAUDE.md "Brand separation"),
el design system de la app no debe perder sus fuentes porque vivían dentro
de un pack de marca que ya no está.

Pesos empaquetados (solo los que el código realmente usa — ver
`grep -rn "fontWeight" lib` alrededor de cada `fontFamily`):

- **Space Mono**: Regular (400) y Bold (700). No se empaqueta Italic ni
  Bold Italic — no hay ningún `fontStyle: FontStyle.italic` combinado con
  `fontFamily: 'Space Mono'` en el código.
- **DM Serif Display**: solo Regular (400). No se empaqueta Italic — todo
  uso en el código es sin `fontWeight`/`fontStyle` explícito (cae en el
  normal/400 por default de `TextStyle`), y el único `FontStyle.italic` del
  repo (`onboarding_screen.dart`) es sobre la fuente sans del tema, no sobre
  esta familia.

## Procedencia y licencia

Ambas son Google Fonts, licencia SIL Open Font License 1.1 (OFL) — libres
para empaquetar/embeber en esta app. Bajadas directo del repo oficial y
versionado de Google Fonts en GitHub (`github.com/google/fonts`, rama
`main`), no de un mirror ni de una URL de terceros:

- `SpaceMono-Regular.ttf`, `SpaceMono-Bold.ttf` —
  https://github.com/google/fonts/tree/main/ofl/spacemono
  (texto de licencia: `SpaceMono-OFL.txt`, copiado de `ofl/spacemono/OFL.txt`)
- `DMSerifDisplay-Regular.ttf` —
  https://github.com/google/fonts/tree/main/ofl/dmserifdisplay
  (texto de licencia: `DMSerifDisplay-OFL.txt`, copiado de
  `ofl/dmserifdisplay/OFL.txt`)

Mismo patrón que `lib/placas/packs/remax/assets/LICENSES.md` para los
assets del pack RE/MAX.

## Pendiente conocido (fuera de alcance acá)

`app_theme.dart` también declara `_fontSans = 'Space Grotesk'` como fuente
por defecto de todo el `ThemeData` (body text de toda la app). Tiene el
mismo problema — no está empaquetada, cae a la fuente del sistema en
silencio — pero no apareció en el grep de `fontFamily: '...'` literal que
originó esta tarea (se asigna vía la constante `_fontSans`, no como string
literal repetido) y no se resuelve acá. Requiere su propia tarea.
