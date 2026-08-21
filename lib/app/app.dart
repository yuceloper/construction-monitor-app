import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class ConstructionMonitorApp extends StatelessWidget {
  const ConstructionMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Construction Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}