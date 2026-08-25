// Smoke test: la app real (no el boilerplate de contador que genera
// `flutter create`) tiene que poder montar sin tirar una excepción. No
// verifica una pantalla puntual — eso vive en tests por feature más
// adelante; esto solo confirma que el árbol de widgets raíz (ProviderScope
// + MaterialApp.router + AppTheme + appRouter) arranca.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:placas/main.dart';

void main() {
  // `PlacasApp` arma su router (`routerProvider`) contra `Supabase.instance`
  // (ARCHITECTURE.md Fase 4) — sin inicializarlo antes, `Supabase.instance`
  // tira antes de poder montar el árbol. Mismas credenciales locales de
  // `main.dart`; no hace falta que el stack de Supabase esté corriendo para
  // que `initialize()` en sí no explote (no hay sesión guardada que
  // recuperar en un test limpio).
  //
  // `setMockInitialValues` es necesario aparte: `supabase_flutter` persiste
  // la sesión vía `shared_preferences`, que en `flutter test` no tiene un
  // handler de method channel real — sin este mock, `SharedPreferences
  // .getInstance()` tira `MissingPluginException` y `Supabase.initialize`
  // nunca termina.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);
  });

  testWidgets('PlacasApp arranca sin excepciones', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PlacasApp()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
