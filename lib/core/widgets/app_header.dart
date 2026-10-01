import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/active_site.dart';
import '../../app/theme.dart';
import '../../features/auth/services/session_manager.dart';
import '../../features/site_selection/models/site_summary.dart';
import '../../features/site_selection/services/site_service.dart';
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
///
/// Kutuya dokununca santiye degistirme paneli aciliyor; baska bir santiye
/// secilirse ana sayfaya donuluyor, boylece ekranda onceki santiyenin verisi
/// kalmiyor.
class UserChip extends StatelessWidget {
  const UserChip({super.key});

  Future<void> _openSiteSwitcher(BuildContext context) async {
    final selected = await showModalBottomSheet<SiteSummary>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SiteSwitchSheet(),
    );

    if (selected == null || !context.mounted) return;
    if (selected.id == SessionManager.instance.selectedSiteId) return;

    SessionManager.instance.setSelectedSite(selected);
    ActiveSite.changed();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ActiveSite.revision,
      builder: (context, _, __) => _buildChip(context),
    );
  }

  Widget _buildChip(BuildContext context) {
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
    final initials = (letters.isEmpty ? displayName.substring(0, 1) : letters)
        .toUpperCase();

    return Pressable(
      onTap: () => _openSiteSwitcher(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
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
                        const SizedBox(width: 3),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 13,
                          color: c.accent,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Santiye degistirme paneli: mevcut santiyeler listelenir, secili olanda tik.
class _SiteSwitchSheet extends StatefulWidget {
  const _SiteSwitchSheet();

  @override
  State<_SiteSwitchSheet> createState() => _SiteSwitchSheetState();
}

class _SiteSwitchSheetState extends State<_SiteSwitchSheet> {
  final _siteService = SiteService();

  bool _isLoading = true;
  String? _errorMessage;
  List<SiteSummary> _sites = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final sites = await _siteService.getSites();
      if (!mounted) return;
      setState(() => _sites = sites);
    } on SiteException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Şantiyeler yüklenirken bir hata oluştu.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selectedId = SessionManager.instance.selectedSiteId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .6,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: c.border2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Şantiye',
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
                color: c.ink,
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: c.ink,
                  ),
                ),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 15,
                      height: 1.45,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Pressable(
                    onTap: _load,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tekrar Dene',
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.bg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _sites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final site = _sites[index];
                  final isSelected = site.id == selectedId;
                  return Pressable(
                    onTap: () => Navigator.of(context).pop(site),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.accent.withValues(alpha: .08)
                            : c.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? c.accent : c.border,
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              site.name,
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(LucideIcons.check, size: 20, color: c.accent),
                        ],
                      ),
                    ),
                  );
                },
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
        // Ayni tonda oldugu icin zeminde kayboluyordu.
        border: Border(bottom: BorderSide(color: c.border2)),
      ),
      child: Row(
        children: [
          // Yazi kutusunun ustunde altindan daha cok bosluk var; kutular
          // ortalandiginda ok, harflerin gorsel merkezinin 1.5dp uzerinde
          // kaliyordu. Ok o kadar asagi alindi, dokunma alani 44 kaldi.
          Pressable(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 11.5, 10, 8.5),
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

/// Alt ekranlarin basligi: geri oku, ust sayfanin adi ve bulunulan yer.
/// Butun alt ekranlarda ayni hizada ve ayni olculerde duruyor.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.title,
    required this.onBack,
    this.parent,
    this.onParentTap,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final String? parent;
  final VoidCallback? onParentTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parentLabel = parent;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 20, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Pressable(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(LucideIcons.chevronLeft, size: 24, color: c.ink),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (parentLabel != null && parentLabel.isNotEmpty)
                  Pressable(
                    onTap: onParentTap,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        parentLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .6,
                          color: c.accent,
                        ),
                      ),
                    ),
                  ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -.4,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
