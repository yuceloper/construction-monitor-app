import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = SessionManager.instance;
  await session.restore();

  // Uygulama yeniden acildiginda kullaniciyi login ekranina atma. Kayitli
  // refresh token gecerliyse access token'i sessizce yenile; internet gecici
  // olarak yoksa mevcut oturumu koru. Yalnizca refresh token kesin olarak
  // gecersiz/sona ermis ise oturumu kapat.
  final refreshToken = session.refreshToken;
  if (session.isAuthenticated && refreshToken != null && refreshToken.isNotEmpty) {
    try {
      final refreshed = await AuthService().refresh(refreshToken);
      await session.setAuth(refreshed);
    } on AuthException catch (error) {
      if (error.message == 'Oturum süresi doldu.') {
        await session.clear();
      }
    }
  }

  // Uygulamanin zemini acik renk ve hicbir ekranda AppBar yok; bu durumda
  // Android durum cubugu simgelerini sistemden devraldigi haliyle (beyaz)
  // birakiyordu, saat ve sinyal ikonlari acik zeminde okunmuyordu.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Android
      statusBarBrightness: Brightness.light, // iOS
    ),
  );
  runApp(const ConstructionMonitorApp());
}
