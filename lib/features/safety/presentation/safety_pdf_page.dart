import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

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
      if (mounted) setState(() => _errorMessage = 'PDF açılırken beklenmeyen bir hata oluştu.');
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
      if (mounted) setState(() => _errorMessage = 'PDF açılırken beklenmeyen bir hata oluştu.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          if (_isMonthlyReport && _monthlyDocuments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: DropdownButtonFormField<int>(
                value: _selectedDocumentId,
                isExpanded: true,
                items: _monthlyDocuments
                    .map(
                      (document) => DropdownMenuItem<int>(
                        value: document.id,
                        child: Text(_monthLabel(document)),
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
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 52, color: Colors.redAccent),
              const SizedBox(height: 14),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => _loadPdf(_selectedDocumentId ?? widget.documentId),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = _pdfBytes;
    if (bytes == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return PdfViewer.data(
      bytes,
      sourceName: 'safety_document_${_selectedDocumentId ?? widget.documentId}.pdf',
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
