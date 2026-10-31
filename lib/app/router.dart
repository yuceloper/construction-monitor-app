import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/password_change_page.dart';
import '../features/auth/services/session_manager.dart';
import '../features/site_selection/presentation/site_selection_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/daily_tasks/presentation/daily_task_create_page.dart';
import '../features/daily_tasks/presentation/daily_task_detail_page.dart';
import '../features/daily_tasks/presentation/daily_tasks_page.dart';
import '../features/stakeholders/presentation/stakeholders_page.dart';
import '../features/safety/presentation/safety_page.dart';
import '../features/safety/presentation/safety_pdf_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/process_tracking/presentation/process_tracking_page.dart';
import '../features/reports/presentation/report_page.dart';
import '../features/process_tracking/presentation/process_detail_page.dart';
import '../features/process_tracking/presentation/process_update_page.dart';
import '../features/process_tracking/presentation/stage_update_page.dart';
import '../features/process_tracking/presentation/work_detail_page.dart';
import '../features/process_tracking/services/project_service.dart';
import 'main_shell.dart';

class AppRouter {
  static String get _initialLocation {
    final session = SessionManager.instance;
    if (!session.isAuthenticated) return '/login';
    if (session.selectedSiteId == null) return '/sites';
    if (session.auth?.mustChangePassword == true) return '/change-password';
    return '/dashboard';
  }

  static final GoRouter router = GoRouter(
    initialLocation: _initialLocation,
    redirect: (context, state) {
      final session = SessionManager.instance;
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isSiteSelection = location == '/sites';
      final isPasswordChange = location == '/change-password';

      if (!session.isAuthenticated && !isLogin) return '/login';
      if (!session.isAuthenticated) return null;

      if (session.selectedSiteId == null) {
        return isSiteSelection ? null : '/sites';
      }

      if (session.auth?.mustChangePassword == true) {
        return isPasswordChange ? null : '/change-password';
      }

      final auth = session.auth;
      if (location == '/daily-tasks/create' &&
          !(auth?.canUpdateDailyTasks ?? false)) {
        return '/daily-tasks';
      }
      if (location.startsWith('/process/') &&
          location.contains('/update') &&
          !(auth?.canUpdateProcess ?? false)) {
        return '/process';
      }

      if (isLogin || isSiteSelection || isPasswordChange) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/sites',
        builder: (context, state) => const SiteSelectionPage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const PasswordChangePage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/daily-tasks',
            pageBuilder: (context, state) => const NoTransitionPage(child: DailyTasksPage()),
          ),
          GoRoute(
            path: '/daily-tasks/create',
            pageBuilder: (context, state) => const NoTransitionPage(child: _DailyTaskCreateGate()),
          ),
          GoRoute(
            path: '/daily-tasks/:taskId',
            pageBuilder: (context, state) {
              final taskId = int.tryParse(state.pathParameters['taskId'] ?? '') ?? 0;
              return NoTransitionPage(child: DailyTaskDetailPage(taskId: taskId));
            },
          ),
          GoRoute(
            path: '/stakeholders',
            pageBuilder: (context, state) => const NoTransitionPage(child: StakeholdersPage()),
          ),
          GoRoute(
            path: '/safety',
            pageBuilder: (context, state) => const NoTransitionPage(child: SafetyPage()),
          ),
          GoRoute(
            path: '/safety/pdf/:documentId',
            pageBuilder: (context, state) {
              final documentId = int.tryParse(state.pathParameters['documentId'] ?? '') ?? 0;
              final title = state.uri.queryParameters['title'] ?? 'İSG Dokümanı';
              return NoTransitionPage(
                child: SafetyPdfPage(documentId: documentId, title: title),
              );
            },
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) => const NoTransitionPage(child: ReportPage()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsPage()),
          ),
          GoRoute(
            path: '/process',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProcessTrackingPage()),
          ),
          GoRoute(
            path: '/process/:blockName',
            pageBuilder: (context, state) {
              final blockName = state.pathParameters['blockName']!;
              final progress = int.tryParse(state.uri.queryParameters['progress'] ?? '') ?? 0;
              final projectId = int.tryParse(state.uri.queryParameters['projectId'] ?? '') ?? 0;
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
              final projectId = int.tryParse(state.uri.queryParameters['projectId'] ?? '') ?? 0;
              return NoTransitionPage(
                child: ProcessUpdatePage(blockName: blockName, projectId: projectId),
              );
            },
          ),
          GoRoute(
            path: '/process/:blockName/update/:stageId',
            pageBuilder: (context, state) {
              final blockName = state.pathParameters['blockName']!;
              final stageId = int.tryParse(state.pathParameters['stageId'] ?? '') ?? 0;
              final stageTitle = state.uri.queryParameters['title'] ?? 'Süreç Güncelle';
              final projectId = int.tryParse(state.uri.queryParameters['projectId'] ?? '') ?? 0;
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
              final workTitle = state.uri.queryParameters['title'] ?? 'İş Detayı';
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

class _DailyTaskCreateGate extends StatefulWidget {
  const _DailyTaskCreateGate();

  @override
  State<_DailyTaskCreateGate> createState() => _DailyTaskCreateGateState();
}

class _DailyTaskCreateGateState extends State<_DailyTaskCreateGate> {
  final _projectService = ProjectService();
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _checkBlocks();
  }

  Future<void> _checkBlocks() async {
    try {
      final projects = await _projectService.getProjects();
      if (!mounted) return;
      if (projects.isNotEmpty) {
        setState(() => _allowed = true);
        return;
      }
      await _showAndClose('Blok tanımı yapılmadan iş ekleyemezsiniz.');
    } on ProjectException catch (error) {
      if (!mounted) return;
      await _showAndClose(error.message);
    }
  }

  Future<void> _showAndClose(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Günlük İş Ekle'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    if (mounted) context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) return const DailyTaskCreatePage();
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
