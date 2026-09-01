import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/session_manager.dart';
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

  Future<void> _openDocument(SafetyDocumentSummary document) async {
    await context.push(
      '/safety/pdf/${document.id}?title=${Uri.encodeComponent(document.title)}',
    );
  }

  IconData _iconFor(SafetyDocumentSummary document) {
    switch (document.documentType) {
      case 'DAILY_SITE_CONTROL_FORM':
        return Icons.checklist_rounded;
      case 'MONTHLY_SITE_REPORT':
        return Icons.outlined_flag;
      default:
        return Icons.picture_as_pdf_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    final auth = session.auth;
    final displayName = auth?.fullName.isNotEmpty == true
        ? auth!.fullName
        : (auth?.username.isNotEmpty == true ? auth!.username : 'Kullanıcı');
    final siteName = session.selectedSiteName ?? '-';

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/dashboard'),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
                      child: Icon(Icons.arrow_back_ios_new, size: 24),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'İSG Takip',
                      style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(siteName, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.account_circle_outlined, size: 42, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 38),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Bu şantiye için İSG belgesi bulunmuyor.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (_, index) {
          final document = _documents[index];
          return _SafetyMenuCard(
            icon: _iconFor(document),
            title: document.title,
            onTap: () => _openDocument(document),
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
    return Material(
      color: const Color(0xFFF7E3F7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 108,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(icon, size: 36, color: Colors.black),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
