import 'package:flutter/material.dart';

import '../../app/brand.dart';
import '../../app/theme.dart';

/// The product logo. Draws the configured image when there is one and the
/// wordmark otherwise; a logo that fails to load also falls back to the
/// wordmark, so the header never shows a broken image.
///
/// [height] sets the size: the wordmark's type size follows it, and an image
/// is fitted inside it. [compact] picks the mark-only file where the full
/// lock-up with its strapline would be too small to read - the top bars.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 22, this.compact = false});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BrandConfig>(
      valueListenable: Brand.config,
      builder: (context, brand, _) {
        final wordmark = _Wordmark(name: brand.name, height: height);
        final url = brand.logoUrl;
        final asset = compact
            ? (brand.logoMarkAsset ?? brand.logoAsset)
            : brand.logoAsset;

        Widget image;
        if (url != null && url.isNotEmpty) {
          image = Image.network(
            url,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => wordmark,
          );
        } else if (asset != null && asset.isNotEmpty) {
          image = Image.asset(
            asset,
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stack) => wordmark,
          );
        } else {
          return wordmark;
        }

        return Semantics(label: brand.name, image: true, child: image);
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.name, required this.height});

  final String name;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: kDisplay,
        fontSize: height * .88,
        fontWeight: FontWeight.w700,
        letterSpacing: -height * .027,
        height: 1,
        color: context.colors.ink,
      ),
    );
  }
}
