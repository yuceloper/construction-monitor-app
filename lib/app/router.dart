import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/site_selection/presentation/site_selection_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/process_tracking/presentation/process_tracking_page.dart';
import '../features/process_tracking/presentation/process_detail_page.dart';

import 'main_shell.dart';

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

      ShellRoute(
        builder: (context, state, child) {
          return MainShell(
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/process',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProcessTrackingPage(),
            ),
          ),
          GoRoute(
            path: '/process/:blockName',
            pageBuilder: (context, state) {
                final blockName = state.pathParameters['blockName']!;

                final progress =
                    int.tryParse(state.uri.queryParameters['progress'] ?? '') ?? 0;

                return NoTransitionPage(
                child: ProcessDetailPage(
                    blockName: blockName,
                    progress: progress,
                ),
                );
            },
            ),
        ],
      ),
    ],
  );
}