import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
