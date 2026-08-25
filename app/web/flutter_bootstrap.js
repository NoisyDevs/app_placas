{{flutter_js}}
{{flutter_build_config}}

// Fuerza el renderer CanvasKit (ARCHITECTURE.md §9, trampa 1):
// `RepaintBoundary.toImage`/`toByteData` — lo que usa el exportador de
// placas (`placas/export/placa_exporter.dart`) — no es confiable en el
// renderer HTML. `flutter build web` (sin `--wasm`) ya solo genera un
// build CanvasKit desde que el renderer HTML se sacó del engine, pero
// `config.renderer` lo deja explícito y a prueba de que algún día se
// agregue `--wasm` al pipeline de build (que sumaría un candidato skwasm)
// sin que nadie note que el export dejó de ser confiable.
_flutter.loader.load({
  config: {
    renderer: "canvaskit"
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});
