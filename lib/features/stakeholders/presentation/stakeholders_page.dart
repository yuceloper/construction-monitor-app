import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_header.dart';
import '../models/stakeholder_summary.dart';
import '../services/stakeholder_service.dart';

class StakeholdersPage extends StatefulWidget {
  const StakeholdersPage({super.key});

  @override
  State<StakeholdersPage> createState() => _StakeholdersPageState();
}

class _StakeholdersPageState extends State<StakeholdersPage> {
  final _service = StakeholderService();

  bool _isLoading = true;
  String? _errorMessage;
  List<StakeholderSummary> _items = const [];

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
      final items = await _service.getStakeholders();
      if (!mounted) return;
      setState(() => _items = items);
    } on StakeholderException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _call(StakeholderSummary item) async {
    final phone = item.phoneNumber.trim();
    if (phone.isEmpty) {
      _show('Geçerli telefon numarası bulunamadı.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _show('Arama ekranı açılamadı.');
    }
  }

  Future<void> _openWhatsApp(StakeholderSummary item) async {
    final phone = _normalizePhone(item.phoneNumber);
    if (phone.isEmpty) {
      _show('Geçerli telefon numarası bulunamadı.');
      return;
    }

    final uri = Uri.https('wa.me', '/$phone');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _show('WhatsApp açılamadı.');
    }
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0') && digits.length == 11) {
      digits = '90${digits.substring(1)}';
    } else if (digits.length == 10 && digits.startsWith('5')) {
      digits = '90$digits';
    }
    return digits;
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/dashboard'),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Paydaşlar',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildContent()),
          ],
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
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Henüz paydaş bulunmuyor.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = _items[index];
          return Material(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.companyName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        if (item.detail.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(item.detail, style: const TextStyle(fontSize: 14)),
                        ],
                        if (item.contactPerson.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 20),
                              const SizedBox(width: 5),
                              Expanded(child: Text(item.contactPerson)),
                            ],
                          ),
                        ],
                        if (item.phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 20),
                              const SizedBox(width: 5),
                              Text(item.phoneNumber),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ara',
                    onPressed: item.phoneNumber.trim().isEmpty ? null : () => _call(item),
                    icon: const Icon(Icons.call_rounded, size: 29, color: Color(0xFF0066A6)),
                  ),
                  IconButton(
                    tooltip: 'WhatsApp',
                    onPressed: item.phoneNumber.trim().isEmpty ? null : () => _openWhatsApp(item),
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 30,
                      color: Color(0xFF25D366),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
