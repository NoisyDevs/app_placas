import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/billing/presentation/upgrade_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/wizard/presentation/load_property_screen.dart';
import '../features/wizard/presentation/load_search_screen.dart';
import '../features/wizard/presentation/preview_screen.dart';
import '../features/wizard/presentation/share_screen.dart';
import '../features/wizard/presentation/templates_screen.dart';
import '../features/wizard/presentation/type_screen.dart';

/// Un router por pantalla del mockup (`PlacasApp.dc.html`, 12 pantallas).
/// `go_router` porque el target web necesita URLs reales (ARCHITECTURE.md
/// §0).
final appRouter = GoRouter(
  initialLocation: '/login',
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
