import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/secim_paneli.dart';
import '../../auth/services/session_manager.dart';
import '../models/site_summary.dart';
import '../services/site_service.dart';

class SiteSelectionPage extends StatefulWidget {
  const SiteSelectionPage({super.key});

  @override
  State<SiteSelectionPage> createState() => _SiteSelectionPageState();
}

class _SiteSelectionPageState extends State<SiteSelectionPage> {
  final _siteService = SiteService();

  bool _isLoading = true;
  String? _errorMessage;
  List<SiteSummary> _sites = const [];
  SiteSummary? _selectedSite;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sites = await _siteService.getSites();
      if (!mounted) return;

      if (sites.length == 1) {
        SessionManager.instance.setSelectedSite(sites.first);
        context.go('/dashboard');
        return;
      }

      final currentSite = SessionManager.instance.selectedSite;
      SiteSummary? selected;
      if (currentSite != null) {
        for (final site in sites) {
          if (site.id == currentSite.id) {
            selected = site;
            break;
          }
        }
      }
      selected ??= sites.isNotEmpty ? sites.first : null;

      setState(() {
        _sites = sites;
        _selectedSite = selected;
      });
    } on SiteException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continue() {
    final selectedSite = _selectedSite;
    if (selectedSite == null) return;
    SessionManager.instance.setSelectedSite(selectedSite);
    context.go('/dashboard');
  }

  void _goBackToLogin() {
    SessionManager.instance.clear();
    context.go('/login');
  }

  /// Santiye secimi: acilir liste yerine alttan acilan panel - telefonda
  /// parmakla secmesi kolay, secili olan net gorunuyor.
  /// Santiye secimi: acilir liste yerine alttan acilan panel - telefonda
  /// parmakla secmesi kolay, secili olan net gorunuyor.
  Future<void> _openSitePicker() async {
    final selected = await secimPaneliAc<int>(
      context,
      baslik: 'Şantiye',
      secenekler: [
        for (final site in _sites) SecimSecenegi(site.id, site.name),
      ],
      secili: _selectedSite?.id,
    );
    if (selected == null || !mounted) return;
    for (final site in _sites) {
      if (site.id == selected) {
        setState(() => _selectedSite = site);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 44).clamp(0.0, double.infinity),
                ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: BrandLogo(height: 74)),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                      boxShadow: kLiftShadow,
                    ),
                    child: _buildSelectorContent(),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '© Copyright 2026 SefaTech tüm hakları saklıdır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kBody, fontSize: 12.5, color: c.faint),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorContent() {
    final c = context.colors;

    if (_isLoading) {
      return SizedBox(
        height: 140,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: c.bad.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.circleAlert, size: 18, color: c.bad),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 14.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: c.bad,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SmallButton(
              label: 'Tekrar Dene',
              icon: LucideIcons.refreshCw,
              onTap: _loadSites,
            ),
          ),
          const SizedBox(height: 10),
          _BackToLogin(onTap: _goBackToLogin),
        ],
      );
    }

    if (_sites.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EmptyView(
            title: 'Bu kullanıcıya atanmış şantiye bulunmuyor.',
          ),
          const SizedBox(height: 14),
          _BackToLogin(onTap: _goBackToLogin),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Şantiye',
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 9),
        Pressable(
          onTap: _openSitePicker,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 17, 14, 17),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(Sizes.rField),
              border: Border.all(color: c.border2, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSite?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
                Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        PrimaryButton(
          label: 'DEVAM',
          onPressed: _selectedSite == null ? null : _continue,
        ),
        const SizedBox(height: 8),
        _BackToLogin(onTap: _goBackToLogin),
      ],
    );
  }
}

class _BackToLogin extends StatelessWidget {
  const _BackToLogin({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.chevronLeft, size: 17, color: c.accent),
              const SizedBox(width: 4),
              Text(
                "GİRİŞ'e Dön",
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
