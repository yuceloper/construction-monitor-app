import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/site_selection/presentation/site_selection_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/daily_tasks/presentation/daily_task_create_page.dart';
import '../features/daily_tasks/presentation/daily_tasks_page.dart';
import '../features/process_tracking/presentation/process_tracking_page.dart';
import '../features/process_tracking/presentation/process_detail_page.dart';
import '../features/process_tracking/presentation/process_update_page.dart';
import '../features/process_tracking/presentation/stage_update_page.dart';
import '../features/process_tracking/presentation/work_detail_page.dart';
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
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/daily-tasks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DailyTasksPage(),
            ),
          ),
          GoRoute(
            path: '/daily-tasks/create',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DailyTaskCreatePage(),
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
              final projectId =
                  int.tryParse(state.uri.queryParameters['projectId'] ?? '') ?? 0;

              return NoTransitionPage(
                child: ProcessDetailPage(
                  blockName: blockName,
                  progress: progress,
                  projectId: projectId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/process/:blockName/update',
            pageBuilder: (context, state) {
              final blockName = state.pathParameters['blockName']!;
              final projectId =
                  int.tryParse(state.uri.queryParameters['projectId'] ?? '') ?? 0;
              return NoTransitionPage(
                child: ProcessUpdatePage(
                  blockName: blockName,
                  projectId: projectId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/process/:blockName/update/:stageId',
            pageBuilder: (context, state) {
              final blockName = state.pathParameters['blockName']!;
              final stageId = int.tryParse(state.pathParameters['stageId'] ?? '') ?? 0;
              final stageTitle =
                  state.uri.queryParameters['title'] ?? 'Süreç Güncelle';
              final projectId =
                  int.tryParse(state.uri.queryParameters['projectId'] ?? '') ?? 0;

              return NoTransitionPage(
                child: StageUpdatePage(
                  blockName: blockName,
                  stageId: stageId,
                  stageTitle: stageTitle,
                  projectId: projectId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/process/:blockName/work/:workId',
            pageBuilder: (context, state) {
              final blockName = state.pathParameters['blockName']!;
              final workId = state.pathParameters['workId']!;
              final workTitle =
                  state.uri.queryParameters['title'] ?? 'İş Detayı';

              return NoTransitionPage(
                child: WorkDetailPage(
                  blockName: blockName,
                  workId: workId,
                  workTitle: workTitle,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
