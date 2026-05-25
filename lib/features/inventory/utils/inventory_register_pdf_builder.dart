import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/inventory.dart';

/// Builds an A4 inventory / asset-register PDF, grouped by category with
/// per-group and grand-total summaries.
class InventoryRegisterPdfBuilder {
  InventoryRegisterPdfBuilder._();

  static Future<Uint8List> build({
    required List<Asset> assets,
    String? schoolName,
    String? generatedBy,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFmt = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Group by category name (uncategorised assets share a bucket)
    final grouped = <String, List<Asset>>{};
    for (final asset in assets) {
      final key = asset.category?.name ?? 'Uncategorised';
      grouped.putIfAbsent(key, () => []).add(asset);
    }
    final categories = grouped.keys.toList()..sort();

    final grandPurchase =
        assets.fold<double>(0, (sum, a) => sum + (a.purchasePrice ?? 0));
    final grandCurrent =
        assets.fold<double>(0, (sum, a) => sum + (a.currentValue ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _header(
          schoolName: schoolName,
          now: now,
          dateFmt: dateFmt,
          totalAssets: assets.length,
        ),
        footer: (context) => _footer(context, generatedBy),
        build: (context) {
          if (assets.isEmpty) {
            return [
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'No assets to report',
                  style: pw.TextStyle(
                      fontSize: 14, color: PdfColors.grey700),
                ),
              ),
            ];
          }

          return [
            // Summary card
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EEF2FF'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _summaryCell('Total Assets', '${assets.length}'),
                  _summaryCell('Categories', '${categories.length}'),
                  _summaryCell('Purchase Value', fmt.format(grandPurchase)),
                  _summaryCell('Current Value', fmt.format(grandCurrent)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            // Each category as its own section
            ...categories.map((cat) {
              final items = grouped[cat]!;
              final catPurchase = items.fold<double>(
                  0, (sum, a) => sum + (a.purchasePrice ?? 0));
              final catCurrent = items.fold<double>(
                  0, (sum, a) => sum + (a.currentValue ?? 0));

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      color: PdfColor.fromHex('#1E3A5F'),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            cat,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          pw.Text(
                            '${items.length} item(s)',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildAssetTable(items, fmt, dateFmt),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Subtotal',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Purchase: ${fmt.format(catPurchase)}    '
                            'Current: ${fmt.format(catCurrent)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Grand total
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1E3A5F'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'Purchase: ${fmt.format(grandPurchase)}    '
                    'Current: ${fmt.format(grandCurrent)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _header({
    String? schoolName,
    required DateTime now,
    required DateFormat dateFmt,
    required int totalAssets,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            schoolName ?? 'School Name',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A5F'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Asset / Inventory Register',
            style: pw.TextStyle(
              fontSize: 13,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${dateFmt.format(now)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Total Records: $totalAssets',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColor.fromHex('#1E3A5F')),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context, String? generatedBy) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedBy != null
                ? 'Generated by $generatedBy'
                : 'School Management System',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1E3A5F'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAssetTable(
    List<Asset> items,
    NumberFormat fmt,
    DateFormat dateFmt,
  ) {
    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = const pw.TextStyle(fontSize: 9);

    return pw.Table(
      border: pw.TableBorder.all(
          color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.2),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#2C5282')),
          children: [
            _cell('Code', headerStyle),
            _cell('Name', headerStyle),
            _cell('Serial', headerStyle),
            _cell('Location', headerStyle),
            _cell('Status', headerStyle),
            _cell('Purchase', headerStyle, alignRight: true),
            _cell('Current', headerStyle, alignRight: true),
          ],
        ),
        ...items.map((a) => pw.TableRow(
              children: [
                _cell(a.assetCode, cellStyle),
                _cell(a.name, cellStyle),
                _cell(a.serialNumber ?? '-', cellStyle),
                _cell(a.location ?? '-', cellStyle),
                _cell(a.statusDisplay, cellStyle),
                _cell(
                  a.purchasePrice != null
                      ? fmt.format(a.purchasePrice)
                      : '-',
                  cellStyle,
                  alignRight: true,
                ),
                _cell(
                  a.currentValue != null
                      ? fmt.format(a.currentValue)
                      : '-',
                  cellStyle,
                  alignRight: true,
                ),
              ],
            )),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        text,
        style: style,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
}
