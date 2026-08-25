import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme/app_theme.dart';

/// Credenciales de Supabase LOCAL de desarrollo (ARCHITECTURE.md Fase 4).
/// Son las del `supabase start` de esta máquina — anon key "demo" fija que
/// trae el propio CLI de Supabase para cualquier proyecto local, no un
/// secreto real. Para apuntar a un proyecto de verdad (staging/producción)
/// se pisan con `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// al buildear — NUNCA se hardcodean acá credenciales de un proyecto real.
const kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:55321',
);
const kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // `publishableKey` (no `anonKey`, deprecated en supabase_flutter 2.17):
  // mismo valor, nombre nuevo del parámetro.
  await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);
  runApp(const ProviderScope(child: PlacasApp()));
}

class PlacasApp extends ConsumerWidget {
  const PlacasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Placas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
