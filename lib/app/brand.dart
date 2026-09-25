import 'package:flutter/foundation.dart';

/// Everything that identifies the product on screen, kept in one place.
///
/// The logo is data rather than code: screens draw [BrandLogo] and never spell
/// the name out themselves. The starting values can be set per build:
///
///   flutter run --dart-define=BRAND_NAME=SefaTech \
///               --dart-define=BRAND_LOGO_URL=https://.../logo.png
///
/// and [Brand.update] swaps them at run time, e.g. once the backend sends a
/// company logo. Every logo on screen follows the change immediately.
class BrandConfig {
  const BrandConfig({
    required this.name,
    this.logoUrl,
    this.logoAsset,
  });

  /// Shown as the wordmark, and as the fallback when an image cannot load.
  final String name;

  /// Remote logo image. Takes precedence over [logoAsset].
  final String? logoUrl;

  /// Bundled logo image, e.g. 'assets/images/logo.png'.
  final String? logoAsset;

  bool get hasImage =>
      (logoUrl?.isNotEmpty ?? false) || (logoAsset?.isNotEmpty ?? false);

  BrandConfig copyWith({String? name, String? logoUrl, String? logoAsset}) {
    return BrandConfig(
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      logoAsset: logoAsset ?? this.logoAsset,
    );
  }
}

class Brand {
  Brand._();

  static const _name = String.fromEnvironment('BRAND_NAME', defaultValue: 'SefaTech');
  static const _logoUrl = String.fromEnvironment('BRAND_LOGO_URL');
  static const _logoAsset = String.fromEnvironment('BRAND_LOGO_ASSET');

  static final ValueNotifier<BrandConfig> config = ValueNotifier(
    const BrandConfig(
      name: _name,
      logoUrl: _logoUrl == '' ? null : _logoUrl,
      logoAsset: _logoAsset == '' ? null : _logoAsset,
    ),
  );

  static void update(BrandConfig value) => config.value = value;
}
