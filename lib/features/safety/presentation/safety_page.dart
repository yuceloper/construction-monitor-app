import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/session_manager.dart';
import '../services/safety_document_service.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  Future<void> _openLatest(BuildContext context, String type, String fallbackTitle) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final document = await SafetyDocumentService().getLatest(type);
      if (!context.mounted) return;
      if (document == null) {
        messenger.showSnackBar(SnackBar(content: Text('$fallbackTitle için henüz PDF eklenmemiş.')));
        return;
      }
      await context.push('/safety/pdf/${document.id}?title=${Uri.encodeComponent(document.title)}');
    } on SafetyDocumentException catch (error) {
      if (context.mounted) messenger.showSnackBar(SnackBar(content: Text(error.message)));
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
              const SizedBox(height: 50),
              _SafetyMenuCard(
                icon: Icons.outlined_flag,
                title: 'Aylık Saha Kontrol Raporu',
                onTap: () => _openLatest(context, 'MONTHLY_SITE_REPORT', 'Aylık Saha Kontrol Raporu'),
              ),
              const SizedBox(height: 20),
              _SafetyMenuCard(
                icon: Icons.checklist_rounded,
                title: 'Günlük Saha Kontrol Formu',
                onTap: () => _openLatest(context, 'DAILY_SITE_CONTROL_FORM', 'Günlük Saha Kontrol Formu'),
              ),
              const Spacer(),
            ],
          ),
        ),
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
