// Smoke test: la app real (no el boilerplate de contador que genera
// `flutter create`) tiene que poder montar sin tirar una excepción. No
// verifica una pantalla puntual — eso vive en tests por feature más
// adelante; esto solo confirma que el árbol de widgets raíz (ProviderScope
// + MaterialApp.router + AppTheme + appRouter) arranca.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:placas/main.dart';

void main() {
  testWidgets('PlacasApp arranca sin excepciones', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PlacasApp()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
