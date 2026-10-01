import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../models/safety_document_summary.dart';
import '../services/safety_document_service.dart';

class SafetyPdfPage extends StatefulWidget {
  final int documentId;
  final String title;

  const SafetyPdfPage({
    super.key,
    required this.documentId,
    required this.title,
  });

  @override
  State<SafetyPdfPage> createState() => _SafetyPdfPageState();
}

class _SafetyPdfPageState extends State<SafetyPdfPage> {
  final _service = SafetyDocumentService();

  Uint8List? _pdfBytes;
  String? _errorMessage;
  List<SafetyDocumentSummary> _monthlyDocuments = const [];
  int? _selectedDocumentId;
  bool _isMonthlyReport = false;

  @override
  void initState() {
    super.initState();
    _selectedDocumentId = widget.documentId;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _pdfBytes = null;
      _errorMessage = null;
    });

    try {
      final documents = await _service.getDocuments();
      final current = documents.where((document) => document.id == widget.documentId).firstOrNull;
      final isMonthly = current?.documentType == 'MONTHLY_SITE_REPORT';

      final monthlyByKey = <String, SafetyDocumentSummary>{};
      if (isMonthly) {
        final monthly = documents
            .where((document) =>
                document.documentType == 'MONTHLY_SITE_REPORT' && document.documentDate != null)
            .toList()
          ..sort((a, b) => b.documentDate!.compareTo(a.documentDate!));

        for (final document in monthly) {
          final date = document.documentDate!;
          final key = '${date.year}-${date.month}';
          monthlyByKey.putIfAbsent(key, () => document);
        }
      }

      if (!mounted) return;
      setState(() {
        _isMonthlyReport = isMonthly;
        _monthlyDocuments = monthlyByKey.values.toList();
        if (_isMonthlyReport &&
            !_monthlyDocuments.any((document) => document.id == _selectedDocumentId) &&
            _monthlyDocuments.isNotEmpty) {
          _selectedDocumentId = _monthlyDocuments.first.id;
        }
      });

      await _loadPdf(_selectedDocumentId ?? widget.documentId);
    } on SafetyDocumentException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }

  Future<void> _loadPdf(int documentId) async {
    setState(() {
      _selectedDocumentId = documentId;
      _pdfBytes = null;
      _errorMessage = null;
    });

    try {
      final bytes = await _service.getPdfBytes(documentId);
      if (!mounted) return;
      setState(() => _pdfBytes = bytes);
    } on SafetyDocumentException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }

  String _monthLabel(SafetyDocumentSummary document) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final date = document.documentDate!;
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget build(BuildContext context) {
    final c = context.colors;

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 20, 14),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(LucideIcons.chevronLeft, size: 24, color: c.ink),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kDisplay,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isMonthlyReport && _monthlyDocuments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: DropdownButtonFormField<int>(
                  value: _selectedDocumentId,
                  isExpanded: true,
                  icon: Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
                  dropdownColor: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
                  items: _monthlyDocuments
                      .map(
                        (document) => DropdownMenuItem<int>(
                          value: document.id,
                          child: Text(
                            _monthLabel(document),
                            style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedDocumentId) {
                      _loadPdf(value);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Ay seçiniz',
                    labelStyle: TextStyle(fontFamily: kBody, fontSize: 14, color: c.muted),
                    isDense: true,
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    border: border(c.border2),
                    enabledBorder: border(c.border2),
                    focusedBorder: border(c.accent, 1.8),
                  ),
                ),
              ),
            Expanded(child: ColoredBox(color: c.inset, child: _buildBody())),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final c = context.colors;

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.fileText, size: 52, color: c.bad),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kBody, fontSize: 16, height: 1.45, color: c.ink),
              ),
              const SizedBox(height: 18),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: () => _loadPdf(_selectedDocumentId ?? widget.documentId),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = _pdfBytes;
    if (bytes == null) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }

    return PdfViewer.data(
      bytes,
      sourceName: 'safety_document_${_selectedDocumentId ?? widget.documentId}.pdf',
      params: PdfViewerParams(backgroundColor: c.inset),
    );
  }
}


extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
