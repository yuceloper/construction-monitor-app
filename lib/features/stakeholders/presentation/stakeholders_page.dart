import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/genisleyen_metin.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
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
        separatorBuilder: (_, __) => const SizedBox(height: Sizes.gap),
        itemBuilder: (_, index) {
          final item = items[index];
          // Telefonu olmayan paydasta Ara ve WhatsApp dugmeleri hicbir ise
          // yaramiyordu; KONACIK'taki 68 kaydin 56'sinda telefon yok.
          // Dugmeler kalkinca kart da ismin boyuna oturuyor, yarisi bos
          // durmuyor.
          final telefonVar = item.phoneNumber.isNotEmpty;
          final altSatirVar =
              item.detail.isNotEmpty || item.contactPerson.isNotEmpty;
          return Container(
            padding: EdgeInsets.fromLTRB(16, 15, telefonVar ? 10 : 16, 15),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Sizes.rCard),
              border: Border.all(color: c.border),
              boxShadow: kLiftShadow,
            ),
            child: Row(
              // Tek satirlik isimde yazi, dugmelerin hizasina ortaliyor;
              // alt satirlar varsa yukaridan basliyor.
              crossAxisAlignment: altSatirVar
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.companyName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kDisplay,
                          // Firma adlari bir santiyede tamamen buyuk harf
                          // ("3S KARADENIZ SU"), digerinde normal yazim
                          // ("Bitez Yapi Market") giriliyor. Ayni puntoda
                          // buyuk harf cok daha iri okunuyordu.
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.2,
                          color: c.ink,
                        ),
                      ),
                      if (item.detail.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        // Kart hicbir yere gitmiyor; kesilen aciklama
                        // okunamiyordu, acilip kapanabiliyor.
                        GenisleyenMetin(
                          metin: item.detail,
                          satir: 2,
                          bicim: TextStyle(
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.contactPerson,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        // Numara tek basina bosta duruyordu; ustundeki kisi
                        // satiriyla ayni ritme girdi.
                        Row(
                          children: [
                            Icon(LucideIcons.phone, size: 17, color: c.muted),
                            const SizedBox(width: 8),
                            Text(
                              item.phoneNumber,
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                                color: c.sub,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Iki eylem de ayni capta yuvarlak dugme: biri markanin
                // mavisi, digeri WhatsApp'in kendi yesili.
                if (telefonVar) ...[
                  const SizedBox(width: 10),
                  _ContactAction(
                    tooltip: 'Ara',
                    onTap: () => _call(item),
                    background: Color.lerp(c.surface, c.accent, .12)!,
                    child: Icon(LucideIcons.phone, size: 21, color: c.accent),
                  ),
                  const SizedBox(width: 8),
                  _ContactAction(
                    tooltip: 'WhatsApp',
                    onTap: () => _openWhatsApp(item),
                    background: const Color(0xFF25D366),
                    // Mesaj balonu: ayni capta dursalar da hangisinin arama
                    // hangisinin WhatsApp oldugu sekilden anlasiliyor.
                    child: const Icon(
                      LucideIcons.messageCircle,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}


/// Paydas kartinin sag ucundaki eylem dugmesi. Gorsel cap 42, dokunma
/// alani 48: eldivenli parmakla da rahat basiliyor.
class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.tooltip,
    required this.onTap,
    required this.background,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
