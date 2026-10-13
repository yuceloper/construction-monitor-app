import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/widgets/brand_splash.dart';
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
      // Durum cubugu bicimi burada da duruyor: tam ekran belge gibi koyu
      // zeminli bir ekran kendi bicimini uygulayip kapandiginda, sistem
      // eski haline donmuyor ve simgeler acik zeminde beyaz kaliyordu.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: BrandSplash(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}