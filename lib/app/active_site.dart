import 'package:flutter/foundation.dart';

/// Aktif santiye degistiginde ekranlarin kendini yenilemesi icin kucuk bir
/// haberci. Oturum bilgisi SessionManager'da duruyor; burasi sadece
/// "degisti" sinyali veriyor.
class ActiveSite {
  ActiveSite._();

  static final ValueNotifier<int> revision = ValueNotifier(0);

  static void changed() => revision.value++;
}
