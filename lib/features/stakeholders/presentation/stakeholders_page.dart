import 'package:flutter/material.dart';
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
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<StakeholderSummary> _items = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StakeholderSummary> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      return item.companyName.toLowerCase().contains(query) ||
          item.contactPerson.toLowerCase().contains(query) ||
          item.detail.toLowerCase().contains(query) ||
          item.phoneNumber.toLowerCase().contains(query);
    }).toList();
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
      _show('Bu paydaş için telefon numarası kayıtlı değil.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _show('Arama açılamadı. Gerçek cihazda tekrar deneyin.');
    }
  }

  Future<void> _openWhatsApp(StakeholderSummary item) async {
    final phone = _normalizePhone(item.phoneNumber);
    if (phone.isEmpty) {
      _show('Bu paydaş için telefon numarası kayıtlı değil.');
      return;
    }

    final nativeUri = Uri.parse('whatsapp://send?phone=$phone');
    final webUri = Uri.https('wa.me', '/$phone');
    if (await canLaunchUrl(nativeUri)) {
      final opened = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (opened) return;
    }
    final opened = await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Paydaş ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
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

    final items = _filteredItems;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(child: Text(_query.isEmpty ? 'Henüz paydaş bulunmuyor.' : 'Aramaya uygun paydaş bulunamadı.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = items[index];
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
                          Text(item.phoneNumber, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ara',
                    onPressed: () => _call(item),
                    icon: const Icon(Icons.call_rounded, size: 30, color: Color(0xFF0077B5)),
                  ),
                  IconButton(
                    tooltip: 'WhatsApp',
                    onPressed: () => _openWhatsApp(item),
                    icon: const _WhatsAppIcon(size: 34),
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

class _WhatsAppIcon extends StatelessWidget {
  final double size;
  const _WhatsAppIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _WhatsAppPainter()));
  }
}

class _WhatsAppPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()..color = const Color(0xFF25D366);
    final whiteBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09;
    final whitePhone = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width * 0.5, size.height * 0.46);
    final radius = size.width * 0.36;
    canvas.drawCircle(center, radius + size.width * 0.055, whiteBorder);
    canvas.drawCircle(center, radius, green);

    final tail = Path()
      ..moveTo(size.width * 0.27, size.height * 0.69)
      ..lineTo(size.width * 0.18, size.height * 0.91)
      ..lineTo(size.width * 0.40, size.height * 0.80)
      ..close();
    canvas.drawPath(tail, green);

    final phone = Path()
      ..moveTo(size.width * 0.36, size.height * 0.31)
      ..cubicTo(size.width * 0.28, size.height * 0.39, size.width * 0.38, size.height * 0.59,
          size.width * 0.48, size.height * 0.67)
      ..cubicTo(size.width * 0.58, size.height * 0.75, size.width * 0.70, size.height * 0.76,
          size.width * 0.76, size.height * 0.66);
    canvas.drawPath(phone, whitePhone);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
