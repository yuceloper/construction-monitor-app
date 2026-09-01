import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'SefaTech',
                    style: TextStyle(
                      fontSize: 46,
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Şantiye Takip Uygulaması',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildSelectorContent(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '© Copyright 2026 SefaTech tüm hakları saklıdır.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black26),
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
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 38),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _loadSites,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _goBackToLogin, child: const Text("< GİRİŞ'e Dön")),
        ],
      );
    }

    if (_sites.isEmpty) {
      return Column(
        children: [
          const Text('Bu kullanıcıya atanmış şantiye bulunmuyor.'),
          const SizedBox(height: 16),
          TextButton(onPressed: _goBackToLogin, child: const Text("< GİRİŞ'e Dön")),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 120,
              child: Text(
                'Şantiye',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedSite?.id,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Colors.black, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Colors.black, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Colors.black, width: 1.4),
                  ),
                ),
                items: _sites
                    .map(
                      (site) => DropdownMenuItem<int>(
                        value: site.id,
                        child: Text(site.name, style: const TextStyle(fontSize: 14)),
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
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _selectedSite == null ? null : _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: const Text(
              'DEVAM',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _goBackToLogin,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0066AA)),
          child: const Text(
            "< GİRİŞ'e Dön",
            style: TextStyle(
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF0066AA),
            ),
          ),
        ),
      ],
    );
  }
}
