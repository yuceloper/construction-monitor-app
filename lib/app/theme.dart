import 'package:flutter/material.dart';

/// Design tokens and the app-wide [ThemeData], in a light and a dark variant.
///
/// Screens never write a literal colour or size. Colours come from the active
/// theme through [BuildContext.colors]; sizes come from [Sizes]:
///
///     final c = context.colors;
///     Container(color: c.surface)
///
/// Because colours are read from the theme rather than from constants, the
/// whole app switches between light and dark without any screen knowing.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.inset,
    required this.border,
    required this.border2,
    required this.line,
    required this.ink,
    required this.sub,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.ok,
    required this.warn,
    required this.bad,
    required this.track,
    required this.anchorTop,
    required this.anchorMid,
    required this.anchorBottom,
  });

  final Color bg; //        page background
  final Color surface; //   card
  final Color surface2; //  input field
  final Color inset; //     sunken area, empty states
  final Color border; //    card edge
  final Color border2; //   strong edge, input outline
  final Color line; //      row divider
  final Color ink; //       primary text and primary button
  final Color sub; //       secondary text
  final Color muted; //     helper text
  final Color faint; //     placeholder
  final Color accent; //    link, selection
  final Color ok; //        completed
  final Color warn; //      in progress, warning
  final Color bad; //       overdue, high priority
  final Color track; //     unfilled part of a progress bar
  final Color anchorTop; // the dark hero card, top to bottom
  final Color anchorMid;
  final Color anchorBottom;

  static const light = AppColors(
    bg: Color(0xFFE9EDF0),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF4F7F9),
    inset: Color(0xFFEFF3F6),
    border: Color(0xFFE0E6EA),
    border2: Color(0xFFD2DAE0),
    line: Color(0xFFEDF1F4),
    ink: Color(0xFF10141A),
    sub: Color(0xFF545D67),
    muted: Color(0xFF8B949D),
    faint: Color(0xFFA8B0B8),
    accent: Color(0xFF2C6B8F),
    ok: Color(0xFF1C874A),
    warn: Color(0xFFBE7300),
    bad: Color(0xFFC0272F),
    track: Color(0xFFDBE2E7),
    anchorTop: Color(0xFF232C38),
    anchorMid: Color(0xFF141A22),
    anchorBottom: Color(0xFF0D1218),
  );

  static const dark = AppColors(
    bg: Color(0xFF0D1117),
    surface: Color(0xFF161B22),
    surface2: Color(0xFF1C222B),
    inset: Color(0xFF1A2029),
    border: Color(0xFF242C36),
    border2: Color(0xFF2E3742),
    line: Color(0xFF1F262F),
    ink: Color(0xFFF0F4F8),
    sub: Color(0xFFA8B2BD),
    muted: Color(0xFF77828F),
    faint: Color(0xFF5C6773),
    accent: Color(0xFF64A7CE),
    ok: Color(0xFF3EC776),
    warn: Color(0xFFE0A030),
    bad: Color(0xFFE5606A),
    track: Color(0xFF262E38),
    anchorTop: Color(0xFF232C38),
    anchorMid: Color(0xFF141A22),
    anchorBottom: Color(0xFF0D1218),
  );

  @override
  AppColors copyWith() => this;

  /// Blended so the switch between light and dark animates instead of
  /// snapping.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: m(bg, other.bg),
      surface: m(surface, other.surface),
      surface2: m(surface2, other.surface2),
      inset: m(inset, other.inset),
      border: m(border, other.border),
      border2: m(border2, other.border2),
      line: m(line, other.line),
      ink: m(ink, other.ink),
      sub: m(sub, other.sub),
      muted: m(muted, other.muted),
      faint: m(faint, other.faint),
      accent: m(accent, other.accent),
      ok: m(ok, other.ok),
      warn: m(warn, other.warn),
      bad: m(bad, other.bad),
      track: m(track, other.track),
      anchorTop: m(anchorTop, other.anchorTop),
      anchorMid: m(anchorMid, other.anchorMid),
      anchorBottom: m(anchorBottom, other.anchorBottom),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// The two typefaces. Both are bundled under assets/fonts, so the app looks
/// right even when it opens without a connection.
const String kDisplay = 'Barlow'; //      headings and figures
const String kBody = 'IBM Plex Sans'; //  body text

/// Spacing and corner radii, on a 4-point grid.
class Sizes {
  const Sizes._();

  static const double page = 20;
  static const double gap = 12;

  static const double rCard = 20;
  static const double rAnchor = 22;
  static const double rTile = 20;
  static const double rRow = 17;
  static const double rChip = 7;
  static const double rBtn = 15;
  static const double rField = 13;

  /// Large enough to hit with a gloved finger on site.
  static const double tapTarget = 56;
}

/// Shadow under the floating cards (login form, anchor card).
const kLiftShadow = <BoxShadow>[
  BoxShadow(color: Color(0x1C0E141C), blurRadius: 34, offset: Offset(0, 14)),
  BoxShadow(color: Color(0x0D0E141C), blurRadius: 8, offset: Offset(0, 3)),
];

/// Light or dark, chosen by the user from the top bar.
///
/// Kept in memory for the session. It is not persisted yet: that needs a
/// storage package the project does not currently depend on.
class ThemeController {
  const ThemeController._();

  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static void toggle() =>
      mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
}

class AppTheme {
  const AppTheme._();

  static ThemeData _build(AppColors c, Brightness brightness) {
    final text = TextTheme(
      // Screen title - "Süreç Takibi"
      headlineSmall: TextStyle(
        fontFamily: kDisplay,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: c.ink,
      ),
      // Card title - "Süreç Takip"
      titleMedium: TextStyle(
        fontFamily: kDisplay,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: c.ink,
      ),
      // Row title
      titleSmall: TextStyle(
        fontFamily: kDisplay,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
      bodyLarge: TextStyle(fontFamily: kBody, fontSize: 15, color: c.ink),
      bodyMedium: TextStyle(
        fontFamily: kBody,
        fontSize: 13.5,
        height: 1.4,
        color: c.ink,
      ),
      bodySmall: TextStyle(
        fontFamily: kBody,
        fontSize: 11,
        height: 1.35,
        color: c.muted,
      ),
      labelSmall: TextStyle(
        fontFamily: kBody,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: c.muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: kBody,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: brightness,
      ).copyWith(
        primary: c.accent,
        surface: c.surface,
        onSurface: c.ink,
        error: c.bad,
      ),
      textTheme: text,
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(
          fontFamily: kBody,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: c.bg,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.rCard),
        ),
        titleTextStyle: TextStyle(
          fontFamily: kDisplay,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: c.ink,
        ),
        contentTextStyle: TextStyle(fontFamily: kBody, fontSize: 13.5, color: c.sub),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.sub,
          textStyle: const TextStyle(
            fontFamily: kBody,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ink,
          foregroundColor: c.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontFamily: kBody,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      extensions: [c],
    );
  }

  static ThemeData get lightTheme => _build(AppColors.light, Brightness.light);
  static ThemeData get darkTheme => _build(AppColors.dark, Brightness.dark);
}
