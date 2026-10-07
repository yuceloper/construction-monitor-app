import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../models/stakeholder_summary.dart';
import '../services/stakeholder_service.dart';

class StakeholderFormPage extends StatefulWidget {
  final StakeholderSummary? stakeholder;

  const StakeholderFormPage({super.key, this.stakeholder});

  @override
  State<StakeholderFormPage> createState() => _StakeholderFormPageState();
}

class _StakeholderFormPageState extends State<StakeholderFormPage> {
  final _service = StakeholderService();
  final _companyController = TextEditingController();
  final _detailController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEdit => widget.stakeholder != null;

  @override
  void initState() {
    super.initState();
    final item = widget.stakeholder;
    if (item != null) {
      _companyController.text = item.companyName;
      _detailController.text = item.detail;
      _contactController.text = item.contactPerson;
      _phoneController.text = item.phoneNumber;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _detailController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || _isDeleting) return;
    final company = _companyController.text.trim();
    final detail = _detailController.text.trim();
    final contact = _contactController.text.trim();
    final phone = _phoneController.text.trim();

    if (company.isEmpty) return _show('Firma adı zorunludur.');
    if (contact.isEmpty) return _show('İlgili kişi zorunludur.');
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      return _show('Geçerli bir telefon numarası giriniz.');
    }

    setState(() => _isSaving = true);
    try {
      await _service.save(
        id: widget.stakeholder?.id,
        companyName: company,
        detail: detail,
        contactPerson: contact,
        phoneNumber: phone,
      );
      if (!mounted) return;
      _show(_isEdit ? 'Paydaş güncellendi.' : 'Paydaş eklendi.');
      context.pop(true);
    } on StakeholderException catch (error) {
      if (mounted) _show(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.stakeholder?.id;
    if (id == null || _isSaving || _isDeleting) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paydaşı sil'),
        content: const Text('Bu paydaş kaydı silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _service.delete(id);
      if (!mounted) return;
      context.pop(true);
    } on StakeholderException catch (error) {
      if (mounted) _show(error.message);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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

    InputDecoration field({String? hint}) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: kBody, fontSize: 16, color: c.faint),
          counterStyle: TextStyle(fontFamily: kBody, fontSize: 12, color: c.muted),
          isDense: true,
          filled: true,
          fillColor: c.surface2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: border(c.border2),
          enabledBorder: border(c.border2),
          disabledBorder: border(c.border),
          focusedBorder: border(c.accent, 1.8),
        );

    final textStyle = TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink);

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 20, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.pop(false),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(LucideIcons.chevronLeft, size: 24, color: c.ink),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Pressable(
                    onTap: () => context.pop(false),
                    child: Text(
                      'Paydaşlar',
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Icon(LucideIcons.chevronRight, size: 15, color: c.muted),
                  ),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Düzenle' : 'Ekle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kDisplay,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: [
                  _FieldLabel('Firma Adı'),
                  TextField(
                    controller: _companyController,
                    maxLength: 150,
                    inputFormatters: [LengthLimitingTextInputFormatter(150)],
                    style: textStyle,
                    cursorColor: c.accent,
                    decoration: field(),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Detay'),
                  TextField(
                    controller: _detailController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    style: textStyle,
                    cursorColor: c.accent,
                    decoration: field(hint: 'Lütfen detay giriniz.'),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('İlgili Kişi'),
                  TextField(
                    controller: _contactController,
                    maxLength: 120,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    style: textStyle,
                    cursorColor: c.accent,
                    decoration: field(),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Telefon Numarası'),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 30,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    style: textStyle,
                    cursorColor: c.accent,
                    decoration: field(hint: '05xx xxx xx xx'),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: _isEdit ? 'GÜNCELLE' : 'KAYDET',
                    busy: _isSaving,
                    onPressed: _isSaving || _isDeleting ? null : _save,
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Pressable(
                        onTap: _isSaving || _isDeleting ? null : _delete,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.trash2, size: 19, color: c.bad),
                              const SizedBox(width: 8),
                              Text(
                                'Paydaşı Sil',
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.bad,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kBody,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
          color: context.colors.ink,
        ),
      ),
    );
  }
}
