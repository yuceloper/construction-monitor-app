import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/site_selection/presentation/site_selection_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/sites',
        builder: (context, state) => const SiteSelectionPage(),
      ),
    ],
  );
}