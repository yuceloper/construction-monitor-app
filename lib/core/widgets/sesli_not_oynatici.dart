import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import 'pressable.dart';

/// Kaydedilmis sesli notun dinleme kutusu.
///
/// Is detayinda ve is eklerken ayni gorunsun diye tek yerde duruyor:
/// yuvarlak cal/duraklat dugmesi, durum yazisi ve sagda hoparlor.
/// [onSil] verilirse hoparlor yerine carpi cikar; is eklerken kayit
/// silinip yeniden alinabiliyor.
class SesliNotOynatici extends StatelessWidget {
  const SesliNotOynatici({
    super.key,
    required this.oynuyor,
    required this.yukleniyor,
    required this.onCal,
    this.onSil,
    this.sure,
  });

  final bool oynuyor;
  final bool yukleniyor;
  final VoidCallback onCal;
  final VoidCallback? onSil;

  /// Calma suresi, "0:12" gibi. Oynatilirken yazinin yaninda duruyor.
  final String? sure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onSil = this.onSil;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          // Kutunun tamami degil, dugme ve yazi basiliyor: sagdaki carpi
          // ile cakismasin diye dokunma alanlari ayri.
          Expanded(
            child: Pressable(
              onTap: onCal,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: yukleniyor
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.surface,
                            ),
                          )
                        : Icon(
                            oynuyor ? LucideIcons.pause : LucideIcons.play,
                            color: c.surface,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 13),
                  // Sure, basligin altinda duruyor. Yan yana oldugunda
                  // dar pencerede baslik kirpiliyor ve sure sagdaki
                  // dugmeye yapisik gorunuyordu.
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oynuyor
                              ? 'Sesli Not Oynatılıyor'
                              : 'Sesli Notu Dinle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: c.ink,
                          ),
                        ),
                        if (sure != null && sure!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sure!,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: c.sub,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (onSil == null)
            SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(LucideIcons.volume2, color: c.accent, size: 21),
              ),
            )
          else
            Pressable(
              onTap: onSil,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border2),
                ),
                child: Icon(LucideIcons.x, size: 16, color: c.sub),
              ),
            ),
        ],
      ),
    );
  }
}
