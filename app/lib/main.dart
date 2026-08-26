import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme/app_theme.dart';

// Instancia local de Supabase (`supabase start`, ver README.md). Estos NO
// son secretos: la anon key es pública por diseño (protegida por RLS —
// ARCHITECTURE.md §4) y esta es literalmente la key de demo que imprime
// `supabase status` en cualquier instancia local del CLI. Overrideable con
// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
// para apuntar a un proyecto real.
const _defaultSupabaseUrl = 'http://127.0.0.1:55321';
const _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultSupabaseUrl),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: _defaultSupabaseAnonKey),
  );
  runApp(const ProviderScope(child: PlacasApp()));
}

class PlacasApp extends StatelessWidget {
  const PlacasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Placas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
