import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_models.dart';

class ReportPdfService {
  Future<Uint8List> build(ReportData data) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'),
    );
    final medium = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSans-Medium.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSans-SemiBold.ttf'),
    );

    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: regular,
        boldItalic: bold,
      ),
    );

    final allBlocks = data.groups.expand((group) => group.blocks).toList();
    final total = allBlocks.length;
    final completed = allBlocks
        .where((block) => block.state == BlockState.completed)
        .length;
    final delayed = allBlocks
        .where((block) => block.state == BlockState.delayed)
        .length;
    final inProgress = allBlocks
        .where((block) => block.state == BlockState.inProgress)
        .length;
    final notStarted = allBlocks
        .where((block) => block.state == BlockState.notStarted)
        .length;
    final average = total == 0
        ? 0
        : (allBlocks.fold<int>(0, (sum, block) => sum + block.progress) / total)
              .round();

    final now = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 34, 32, 34),
        header: (context) => _header(data, now, bold, medium),
        footer: (context) => _footer(context, medium),
        build: (context) => [
          pw.SizedBox(height: 14),
          _overallSummary(
            total: total,
            completed: completed,
            inProgress: inProgress,
            delayed: delayed,
            notStarted: notStarted,
            average: average,
            bold: bold,
            medium: medium,
          ),
          pw.SizedBox(height: 18),
          ...data.groups.expand(
            (group) => [
              _groupSection(group, bold, medium),
              pw.SizedBox(height: 18),
            ],
          ),
          if (data.updates.isNotEmpty) ...[
            _sectionTitle('Son Güncellemeler', bold),
            pw.SizedBox(height: 8),
            ...data.updates.take(20).map(
              (update) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 7),
                padding: const pw.EdgeInsets.all(9),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            update.title,
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 9.5,
                              color: PdfColors.blueGrey900,
                            ),
                          ),
                        ),
                        pw.Text(
                          _date(update.date),
                          style: pw.TextStyle(
                            font: medium,
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    if (update.detail.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        update.detail,
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 8.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                    if ((update.blockName ?? '').trim().isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Blok: ${update.blockName}',
                        style: pw.TextStyle(
                          font: medium,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(
    ReportData data,
    DateTime now,
    pw.Font bold,
    pw.Font medium,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: .8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SAHADA',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 19,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Süreç Takip Raporu',
                  style: pw.TextStyle(
                    font: medium,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (data.siteName.trim().isNotEmpty)
                pw.Text(
                  data.siteName,
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 10,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Rapor tarihi: ${_date(now)}',
                style: pw.TextStyle(
                  font: medium,
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                data.sitePlannedEnd == null
                    ? 'Planlanan bitiş: Tanımlı değil'
                    : 'Planlanan bitiş: ${_date(data.sitePlannedEnd!)}',
                style: pw.TextStyle(
                  font: medium,
                  fontSize: 8.5,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context, pw.Font medium) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: .8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SAHADA Süreç Takip',
            style: pw.TextStyle(
              font: medium,
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              font: medium,
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _overallSummary({
    required int total,
    required int completed,
    required int inProgress,
    required int delayed,
    required int notStarted,
    required int average,
    required pw.Font bold,
    required pw.Font medium,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Genel Özet - Tüm Blok Tipleri', bold),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metric('Toplam Blok', '$total', bold, medium),
            _metric('Genel İlerleme', '%$average', bold, medium),
            _metric('Tamamlanan', '$completed', bold, medium),
            _metric('Devam Eden', '$inProgress', bold, medium),
            _metric('Geciken', '$delayed', bold, medium),
            _metric('Başlanmadı', '$notStarted', bold, medium),
          ],
        ),
      ],
    );
  }

  pw.Widget _metric(
    String label,
    String value,
    pw.Font bold,
    pw.Font medium,
  ) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300, width: .7),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: medium,
              fontSize: 8.5,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: 11,
              color: PdfColors.blueGrey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _groupSection(
    BlockGroup group,
    pw.Font bold,
    pw.Font medium,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          '${group.label} - ${group.total} Blok - Ortalama %${group.averageProgress}',
          bold,
        ),
        pw.SizedBox(height: 7),
        pw.Row(
          children: [
            _smallMetric('Tamamlanan', group.completed, bold, medium),
            pw.SizedBox(width: 7),
            _smallMetric('Devam Eden', group.inProgress, bold, medium),
            pw.SizedBox(width: 7),
            _smallMetric('Geciken', group.delayed, bold, medium),
            pw.SizedBox(width: 7),
            _smallMetric('Başlanmadı', group.notStarted, bold, medium),
          ],
        ),
        pw.SizedBox(height: 8),
        _blockTable(group.blocks, bold, medium),
      ],
    );
  }

  pw.Widget _smallMetric(
    String label,
    int value,
    pw.Font bold,
    pw.Font medium,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: medium,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '$value',
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: PdfColors.blueGrey900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _blockTable(
    List<BlockReport> blocks,
    pw.Font bold,
    pw.Font medium,
  ) {
    if (blocks.isEmpty) {
      return pw.Text(
        'Bu tipte blok bulunmuyor.',
        style: pw.TextStyle(
          font: medium,
          fontSize: 8.5,
          color: PdfColors.grey600,
        ),
      );
    }

    pw.Widget cell(
      String text, {
      bool header = false,
      pw.Alignment alignment = pw.Alignment.centerLeft,
    }) {
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: header ? bold : medium,
            fontSize: header ? 8 : 7.8,
            color: header ? PdfColors.blueGrey900 : PdfColors.grey800,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .6),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.7),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.35),
        3: pw.FlexColumnWidth(1.15),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            cell('Blok', header: true),
            cell('İlerleme', header: true, alignment: pw.Alignment.center),
            cell('Durum', header: true),
            cell('Beklenen', header: true, alignment: pw.Alignment.center),
          ],
        ),
        ...blocks.map(
          (block) => pw.TableRow(
            children: [
              cell(block.name),
              cell('%${block.progress}', alignment: pw.Alignment.center),
              cell(block.state.label),
              cell(
                block.expectedProgress == null
                    ? '-'
                    : '%${block.expectedProgress}',
                alignment: pw.Alignment.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}
