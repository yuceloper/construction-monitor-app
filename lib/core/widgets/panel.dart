import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import 'empty_illustration.dart';
import 'pressable.dart';

/// White card - the body of every screen.
///
/// The edge is a gradient rather than a flat 1px line: unnoticeable on its own,
/// it gives the stack of cards a sense of depth.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = Sizes.rCard,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  /// For cards whose rows run edge to edge: padding is dropped and the content
  /// is clipped to the corners instead.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.border2.withValues(alpha: .75),
            c.border.withValues(alpha: .4),
          ],
        ),
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        padding: clip ? null : padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 1),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.surface, Color.lerp(c.surface, c.bg, .3)!],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Tinted icon square used by module tiles and list rows.
class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(size * .325),
      ),
      child: Icon(icon, size: size * .5, color: tint),
    );
  }
}

/// Two-column module card on the home screen.
class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Panel(
        radius: Sizes.rTile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBox(icon: icon),
            const SizedBox(height: 13),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kBody, fontSize: 12, color: c.sub),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width list row with an icon, two lines of text and a chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: Panel(
        radius: Sizes.rRow,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            IconBox(icon: icon, color: iconColor),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (showChevron) ...[
              const SizedBox(width: 10),
              Icon(LucideIcons.chevronRight, size: 18, color: c.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Titled section card - "Bağımlı İşler", "Tarihçe" and the like.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.ink),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.1,
                    color: c.ink,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Status pill. The colour carries meaning, never brand; the label always
/// says the same thing in words.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(Sizes.rChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: kBody,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sunken box for "nothing here" inside a section. It says what to do next
/// where there is something to do.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          // Tam ekran bos durumla ayni isaret, kucuk hali.
          const EmptyIllustration(size: 46),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kBody,
              fontSize: 12,
              height: 1.55,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The single urgent item, pinned near the top of the home screen.
///
/// A coloured edge and a faint wash set it apart from ordinary rows without
/// shouting.
class AttentionCard extends StatelessWidget {
  const AttentionCard({
    super.key,
    required this.title,
    required this.detail,
    this.badge,
    this.onTap,
  });

  final String title;
  final String detail;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Sizes.rRow),
          color: c.surface,
          border: Border.all(color: c.warn.withValues(alpha: .22)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: c.warn),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        c.warn.withValues(alpha: .07),
                        c.warn.withValues(alpha: 0),
                      ],
                      stops: const [0, .6],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.triangleAlert, size: 18, color: c.warn),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kDisplay,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 12,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        StatusChip(label: badge!, color: c.warn),
                      ],
                      const SizedBox(width: 6),
                      Icon(LucideIcons.chevronRight, size: 16, color: c.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal progress bar. [onDark] is for use inside the dark anchor card.
///
/// Width is pinned: inside a Column the width constraint is loose, and the bar
/// would shrink to the width of its filled part and lose its track.
class ProgressRail extends StatelessWidget {
  const ProgressRail({
    super.key,
    required this.percent,
    this.height = 7,
    this.onDark = false,
    this.dim = false,
    this.color,
  });

  final int percent;
  final double height;
  final bool onDark;

  /// Greys the fill, for an item that is not the one in focus.
  final bool dim;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final track = onDark ? Colors.white.withValues(alpha: .16) : c.track;
    final fill = color ?? (onDark ? Colors.white : (dim ? c.muted : c.ink));
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: double.infinity,
        height: height,
        color: track,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (percent / 100).clamp(0, 1)),
          duration: const Duration(milliseconds: 1100),
          curve: const Cubic(.2, .75, .28, 1),
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square checkbox mark. Read-only: the screen owns the state.
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.checked, this.size = 22});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? c.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(size * .32),
        border: Border.all(color: checked ? c.ink : c.border2, width: 2),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: size * .6, color: c.bg)
          : null,
    );
  }
}

/// Bir is kaleminin yanindaki kucuk gosterge: bagimli is, uyari gibi.
///
/// Renk anlami tasir, bicim her ekranda ayni: tonlu kare icinde ince ikon.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

enum StageState { done, active, waiting }

/// Round status mark for a stage: filled tick, ringed dot or empty ring.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.state, this.size = 26});

  final StageState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return switch (state) {
      StageState.done => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c.ok, shape: BoxShape.circle),
          child: Icon(LucideIcons.check, size: size * .54, color: c.bg),
        ),
      StageState.active => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c.warn.withValues(alpha: .14),
            shape: BoxShape.circle,
            border: Border.all(color: c.warn, width: 2),
          ),
          child: Center(
            child: Container(
              width: size * .35,
              height: size * .35,
              decoration: BoxDecoration(color: c.warn, shape: BoxShape.circle),
            ),
          ),
        ),
      StageState.waiting => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.border2, width: 2),
          ),
        ),
    };
  }
}

/// Small dark button on a light surface - "Ekle", "Tümünü oku".
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.busy = false,
    this.onDark = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;

  /// Inverts the button for use on the dark anchor card.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final faceColor = onDark ? Colors.white : c.ink;
    final labelColor = onDark ? c.anchorMid : c.bg;
    return Pressable(
      onTap: busy ? null : onTap,
      child: Opacity(
        opacity: onTap == null ? .45 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 9, 13, 9),
          decoration: BoxDecoration(
            color: faceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: labelColor,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 13, color: labelColor),
              if (busy || icon != null) const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width primary action - "GİRİŞ", "KAYDET". Shows a spinner while
/// [busy] and ignores taps.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Defaults to ink. Destructive actions pass the danger colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final background = color ?? c.ink;
    final foreground = color == null ? c.bg : Colors.white;
    final enabled = onPressed != null && !busy;

    return Pressable(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed == null && !busy ? .45 : 1,
        child: Container(
          height: Sizes.tapTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(Sizes.rBtn),
          ),
          child: busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: foreground,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: foreground,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Labelled text field in the app's style: label above, filled box, strong
/// outline that turns accent on focus.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.enabled = true,
    this.obscure = false,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.inputFormatters,
    this.showCounter = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool enabled;
  final bool obscure;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final List<dynamic>? inputFormatters;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .25,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          maxLength: maxLength,
          minLines: minLines,
          maxLines: obscure ? 1 : maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          inputFormatters: inputFormatters?.cast(),
          style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: kBody, fontSize: 16, color: c.faint),
            filled: true,
            fillColor: c.surface2,
            isDense: true,
            counterText: showCounter ? null : '',
            counterStyle: TextStyle(fontFamily: kBody, fontSize: 12, color: c.muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minHeight: 24),
            border: border(c.border2),
            enabledBorder: border(c.border2),
            disabledBorder: border(c.border),
            focusedBorder: border(c.accent, 1.8),
          ),
        ),
      ],
    );
  }
}

/// Cok satirli bir metin alanini kaydirma cubuguyla sarar.
///
/// Alan kendi icinde kayabiliyordu ama kaydigina dair bir isaret yoktu;
/// yazinin devami oldugu anlasilmiyordu. Kaydirma denetleyicisini bu
/// bilesen tutuyor ve kapanirken birakiyor.
class ScrollableField extends StatefulWidget {
  const ScrollableField({super.key, required this.builder});

  /// Alani kurar; verilen denetleyiciyi TextField'in scrollController'ina
  /// baglamak gerekiyor, yoksa cubuk alanla ayni seyi kaydirmaz.
  final Widget Function(ScrollController controller) builder;

  @override
  State<ScrollableField> createState() => _ScrollableFieldState();
}

class _ScrollableFieldState extends State<ScrollableField> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: widget.builder(_controller),
    );
  }
}
