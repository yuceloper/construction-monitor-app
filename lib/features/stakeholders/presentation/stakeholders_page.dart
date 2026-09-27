import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
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

  Widget build(BuildContext context) {
    final c = context.colors;

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: 'Paydaşlar',
              onBack: () => context.go('/dashboard'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  hintText: 'Paydaş ara',
                  hintStyle: TextStyle(fontFamily: kBody, fontSize: 16, color: c.faint),
                  prefixIcon: Icon(LucideIcons.search, size: 20, color: c.muted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: Icon(LucideIcons.x, size: 19, color: c.sub),
                        ),
                  filled: true,
                  fillColor: c.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  border: border(c.border2),
                  enabledBorder: border(c.border2),
                  focusedBorder: border(c.accent, 1.8),
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

    final items = _filteredItems;
    if (items.isEmpty) {
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _load,
        child: CenteredScrollMessage(
          message: _query.isEmpty
              ? 'Henüz paydaş bulunmuyor.'
              : 'Aramaya uygun paydaş bulunamadı.',
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
              boxShadow: kLiftShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.companyName,
                        style: TextStyle(
                          fontFamily: kDisplay,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.2,
                          color: c.ink,
                        ),
                      ),
                      if (item.detail.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.detail,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14.5,
                            height: 1.35,
                            color: c.sub,
                          ),
                        ),
                      ],
                      if (item.contactPerson.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(LucideIcons.user, size: 17, color: c.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.contactPerson,
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.phoneNumber,
                          style: TextStyle(fontFamily: kBody, fontSize: 14.5, color: c.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ara',
                  onPressed: () => _call(item),
                  icon: Icon(LucideIcons.phone, size: 24, color: c.accent),
                ),
                IconButton(
                  tooltip: 'WhatsApp',
                  onPressed: () => _openWhatsApp(item),
                  icon: const _WhatsAppIcon(size: 30),
                ),
              ],
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
