import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/billing/presentation/upgrade_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/session/session_controller.dart';
import '../features/wizard/presentation/load_property_screen.dart';
import '../features/wizard/presentation/load_search_screen.dart';
import '../features/wizard/presentation/preview_screen.dart';
import '../features/wizard/presentation/share_screen.dart';
import '../features/wizard/presentation/templates_screen.dart';
import '../features/wizard/presentation/type_screen.dart';
import '../services/supabase_service.dart';

/// Adapta un `Stream` al `Listenable` que pide `GoRouter.refreshListenable`
/// — así una navegación se re-evalúa sola cuando cambia el estado de auth
/// de Supabase (login, logout, sesión recuperada del storage local al
/// abrir la app), sin que cada pantalla tenga que hacerlo a mano.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Un router por pantalla del mockup (`PlacasApp.dc.html`, 12 pantallas).
/// `go_router` porque el target web necesita URLs reales (ARCHITECTURE.md
/// §0). Es un `Provider` (no un `final` top-level) para que el `redirect`
/// de abajo pueda leer `sessionProvider` — así, cuando ya hay una sesión de
/// Supabase persistida (Historia 1.1: "la sesión persiste entre usos"), el
/// `AgentProfile` real se carga ANTES de dejar pasar a cualquier pantalla
/// protegida, en vez de que cada pantalla tenga que acordarse de pedirlo.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(SupabaseService.instance.onAuthStateChange),
    redirect: (context, state) async {
      final loggedIn = SupabaseService.instance.currentSession != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn) return loggingIn ? null : '/login';

      // Ver el comentario de `ensureAgentLoaded` en session_controller.dart:
      // es un no-op si el perfil del agente ya está cargado.
      await ref.read(sessionProvider.notifier).ensureAgentLoaded();

      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/home', name: 'home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/new', name: 'type', builder: (context, state) => const TypeScreen()),
      GoRoute(path: '/new/property', name: 'loadProperty', builder: (context, state) => const LoadPropertyScreen()),
      GoRoute(path: '/new/search', name: 'loadSearch', builder: (context, state) => const LoadSearchScreen()),
      GoRoute(path: '/new/templates', name: 'templates', builder: (context, state) => const TemplatesScreen()),
      GoRoute(path: '/new/preview', name: 'preview', builder: (context, state) => const PreviewScreen()),
      GoRoute(path: '/new/share', name: 'share', builder: (context, state) => const ShareScreen()),
      GoRoute(path: '/upgrade', name: 'upgrade', builder: (context, state) => const UpgradeScreen()),
      GoRoute(path: '/history', name: 'history', builder: (context, state) => const HistoryScreen()),
    ],
  );
});
