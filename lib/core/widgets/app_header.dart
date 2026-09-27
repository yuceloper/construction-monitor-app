import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../features/auth/services/session_manager.dart';
import 'brand_logo.dart';
import 'pressable.dart';

/// Brand row at the top of every signed-in screen: the logo on the left, the
/// signed-in user and the active site on the right.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: () => context.go('/dashboard'),
                  child: const BrandLogo(height: 26, compact: true),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const UserChip(),
        ],
      ),
    );
  }
}

/// Signed-in user: initials, name, and the site being worked on.
class UserChip extends StatelessWidget {
  const UserChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = SessionManager.instance;
    final auth = session.auth;
    final first = auth?.firstName ?? '';
    final last = auth?.lastName ?? '';
    final fullName = [first, last].where((p) => p.trim().isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty
        ? fullName
        : (auth?.username.isNotEmpty == true ? auth!.username : 'Kullanıcı');
    final siteName = session.selectedSiteName ?? '';

    final letters = [
      if (first.trim().isNotEmpty) first.trim()[0],
      if (last.trim().isNotEmpty) last.trim()[0],
    ].join();
    final initials =
        (letters.isEmpty ? displayName.substring(0, 1) : letters).toUpperCase();

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
        boxShadow: kLiftShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
                color: c.bg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: c.ink,
                  ),
                ),
                if (siteName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mapPin, size: 11, color: c.accent),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          siteName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                            color: c.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The row under the brand: back arrow and the screen's title, where the app
/// had it before.
class ScreenTitleBar extends StatelessWidget {
  const ScreenTitleBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 20, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(LucideIcons.chevronLeft, size: 24, color: c.ink),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
                color: c.ink,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
