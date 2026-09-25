import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/brand.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
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
      setState(() => _errorMessage = 'Şantiyeler yüklenirken beklenmeyen bir hata oluştu.');
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const BrandLogo(height: 50),
                  const SizedBox(height: 40),
                  Text(
                    'Şantiye Takip Uygulaması',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: c.sub,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.border),
                      boxShadow: kLiftShadow,
                    ),
                    child: _buildSelectorContent(),
                  ),
                  const SizedBox(height: 18),
                  ValueListenableBuilder<BrandConfig>(
                    valueListenable: Brand.config,
                    builder: (context, brand, _) => Text(
                      '© Copyright 2026 ${brand.name} tüm hakları saklıdır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: kBody, fontSize: 13, color: c.faint),
                    ),
                  ),
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
        height: 150,
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
        children: [
          Icon(LucideIcons.circleAlert, color: c.bad, size: 38),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: kBody, fontSize: 15, height: 1.45, color: c.ink),
          ),
          const SizedBox(height: 18),
          SmallButton(
            label: 'Tekrar Dene',
            icon: LucideIcons.refreshCw,
            onTap: _loadSites,
          ),
          const SizedBox(height: 12),
          _BackToLogin(onTap: _goBackToLogin),
        ],
      );
    }

    if (_sites.isEmpty) {
      return Column(
        children: [
          Text(
            'Bu kullanıcıya atanmış şantiye bulunmuyor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: kBody, fontSize: 15, height: 1.45, color: c.ink),
          ),
          const SizedBox(height: 16),
          _BackToLogin(onTap: _goBackToLogin),
        ],
      );
    }

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 125,
              child: Text(
                'Şantiye',
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedSite?.id,
                isExpanded: true,
                icon: Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
                dropdownColor: c.surface,
                style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  filled: true,
                  fillColor: c.surface2,
                  border: border(c.border2),
                  enabledBorder: border(c.border2),
                  focusedBorder: border(c.accent, 1.8),
                ),
                items: _sites
                    .map(
                      (site) => DropdownMenuItem<int>(
                        value: site.id,
                        child: Text(
                          site.name,
                          style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _selectedSite = _sites.firstWhere((site) => site.id == id);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        PrimaryButton(
          label: 'DEVAM',
          onPressed: _selectedSite == null ? null : _continue,
        ),
        const SizedBox(height: 16),
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
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.chevronLeft, size: 17, color: c.accent),
            const SizedBox(width: 4),
            Text(
              "GİRİŞ'e Dön",
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
