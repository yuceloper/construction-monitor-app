import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../models/safety_document_summary.dart';
import '../services/safety_document_service.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final _service = SafetyDocumentService();

  bool _isLoading = true;
  String? _errorMessage;
  List<SafetyDocumentSummary> _documents = const [];

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
      final documents = await _service.getDocuments();
      if (!mounted) return;
      setState(() => _documents = documents);
    } on SafetyDocumentException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDocument(SafetyDocumentSummary document, {String? title}) async {
    await context.push(
      '/safety/pdf/${document.id}?title=${Uri.encodeComponent(title ?? document.title)}',
    );
  }

  IconData _iconFor(SafetyDocumentSummary document) {
    switch (document.documentType) {
      case 'DAILY_SITE_CONTROL_FORM':
        return LucideIcons.clipboardCheck;
      case 'MONTHLY_SITE_REPORT':
        return LucideIcons.flag;
      default:
        return LucideIcons.fileText;
    }
  }

  List<SafetyDocumentSummary> get _menuDocuments {
    final nonMonthly = _documents
        .where((document) => document.documentType != 'MONTHLY_SITE_REPORT')
        .toList();

    final monthly = _documents
        .where((document) => document.documentType == 'MONTHLY_SITE_REPORT')
        .toList()
      ..sort((a, b) {
        final aDate = a.documentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.documentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    if (monthly.isNotEmpty) {
      nonMonthly.insert(0, monthly.first);
    }

    return nonMonthly;
  }

  Widget build(BuildContext context) {
    final c = context.colors;

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            // Bu ekran kendi baslik satirini kuruyordu: logo yoktu, kullanici
            // kutusu baslikla ayni hizada duruyordu. Artik butun ekranlarla
            // ayni ust serit ve ayni baslik seridi kullaniliyor.
            const AppHeader(),
            ScreenTitleBar(
              title: 'İSG Takip',
              onBack: () => context.go('/dashboard'),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = context.colors;

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kBody, fontSize: 16, height: 1.45, color: c.ink),
              ),
              const SizedBox(height: 16),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _load,
              ),
            ],
          ),
        ),
      );
    }

    final menuDocuments = _menuDocuments;
    if (menuDocuments.isEmpty) {
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: const EmptyView(
                  icon: LucideIcons.shieldCheck,
                  title: 'İSG belgesi bulunmuyor.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: menuDocuments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, index) {
          final document = menuDocuments[index];
          final isMonthly = document.documentType == 'MONTHLY_SITE_REPORT';
          return _SafetyMenuCard(
            icon: _iconFor(document),
            title: isMonthly ? 'Aylık Saha Kontrol Raporu' : document.title,
            onTap: () => _openDocument(
              document,
              title: isMonthly ? 'Aylık Saha Kontrol Raporu' : null,
            ),
          );
        },
      ),
    );
  }
}

class _SafetyMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SafetyMenuCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.inset,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 27, color: c.accent),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kDisplay,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -.3,
                  color: c.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.inset, shape: BoxShape.circle),
              child: Icon(LucideIcons.chevronRight, size: 19, color: c.sub),
            ),
          ],
        ),
      ),
    );
  }
}
