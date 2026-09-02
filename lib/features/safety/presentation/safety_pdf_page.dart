import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _pdfBytes = null;
      _errorMessage = null;
    });
    try {
      final bytes = await _service.getPdfBytes(widget.documentId);
      if (!mounted) return;
      setState(() => _pdfBytes = bytes);
    } on SafetyDocumentException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'PDF açılırken beklenmeyen bir hata oluştu.');
    }
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
      body: _buildBody(),
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
              ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
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
      sourceName: 'safety_document_${widget.documentId}.pdf',
    );
  }
}
