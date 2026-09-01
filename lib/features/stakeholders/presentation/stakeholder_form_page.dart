import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
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
                    onTap: () => context.pop(false),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.pop(false),
                    child: const Text(
                      'Paydaşlar',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF0066A6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(' > ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Düzenle' : 'Ekle',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  _FieldLabel('Firma Adı'),
                  TextField(
                    controller: _companyController,
                    maxLength: 150,
                    inputFormatters: [LengthLimitingTextInputFormatter(150)],
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Detay'),
                  TextField(
                    controller: _detailController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    decoration: const InputDecoration(
                      hintText: 'Lütfen detay giriniz.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('İlgili Kişi'),
                  TextField(
                    controller: _contactController,
                    maxLength: 120,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Telefon Numarası'),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 30,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    decoration: const InputDecoration(
                      hintText: '05xx xxx xx xx',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving || _isDeleting ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isEdit ? 'GÜNCELLE' : 'KAYDET', style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isSaving || _isDeleting ? null : _delete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Paydaşı Sil', style: TextStyle(color: Colors.red)),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    );
  }
}
