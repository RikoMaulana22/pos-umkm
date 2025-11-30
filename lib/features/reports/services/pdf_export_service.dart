// lib/features/reports/services/pdf_export_service.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

import 'pdf_saver_stub.dart'
    if (dart.library.io) 'pdf_saver_mobile.dart'
    if (dart.library.html) 'pdf_saver_web.dart';

class PdfExportService {
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yy HH:mm');

  Future<String?> generateSalesReport({
    required List<TransactionModel> transactions,
    required double totalOmzet,
    required double totalProfit, // Ini Laba Kotor
    required double totalExpense, // [BARU] Total Pengeluaran
    required double netProfit, // [BARU] Laba Bersih
    required int totalTransactions,
    required int totalItemsSold,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(context),
            _buildSummary(
              totalOmzet: totalOmzet,
              totalProfit: totalProfit,
              totalExpense: totalExpense, // [BARU]
              netProfit: netProfit, // [BARU]
              totalTransactions: totalTransactions,
              totalItemsSold: totalItemsSold,
            ),
            pw.SizedBox(height: 20),
            _buildTransactionTable(context, transactions),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final String fileName =
        'Laporan_Keuangan_${DateFormat('yyyy-MM-dd-HH-mm').format(DateTime.now())}.pdf';

    final String? path = await savePdfFile(fileName: fileName, bytes: bytes);
    return path;
  }

  Future<void> openPdfFile(String path) async {
    if (kIsWeb) return;
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw Exception("Gagal membuka file PDF: ${result.message}");
    }
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Laporan Keuangan",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
        ),
        pw.Text(
          "Tanggal Cetak: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}",
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(height: 20),
      ],
    );
  }

  pw.Widget _buildSummary({
    required double totalOmzet,
    required double totalProfit,
    required double totalExpense, // [BARU]
    required double netProfit, // [BARU]
    required int totalTransactions,
    required int totalItemsSold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Ringkasan Keuangan",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
        pw.SizedBox(height: 10),
        // Baris 1: Omzet & Laba Kotor
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem("Total Omzet", formatCurrency.format(totalOmzet)),
            _summaryItem(
                "Laba Kotor (Gross)", formatCurrency.format(totalProfit)),
          ],
        ),
        pw.SizedBox(height: 10),
        // Baris 2: Pengeluaran & Laba Bersih [BARU]
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem(
                "Total Pengeluaran", formatCurrency.format(totalExpense),
                color: PdfColors.red900),
            _summaryItem("Laba Bersih (Net)", formatCurrency.format(netProfit),
                isHighlight: true),
          ],
        ),
        pw.SizedBox(height: 10),
        // Baris 3: Statistik
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem("Total Transaksi", totalTransactions.toString()),
            _summaryItem("Item Terjual", totalItemsSold.toString()),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryItem(String title, String value,
      {PdfColor? color, bool isHighlight = false}) {
    return pw.Container(
      width: PdfPageFormat.a4.availableWidth / 2.2,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
            color: isHighlight ? PdfColors.green : PdfColors.grey300,
            width: isHighlight ? 2 : 1),
        borderRadius: pw.BorderRadius.circular(5),
        color: isHighlight ? PdfColors.green50 : null,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
              color:
                  color ?? (isHighlight ? PdfColors.green900 : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionTable(
      pw.Context context, List<TransactionModel> transactions) {
    // ... (Kode tabel sama seperti sebelumnya)
    final headers = ['Tanggal', 'Items', 'Metode', 'Total', 'Laba'];
    final data = transactions.map((tx) {
      final itemsList = tx.items
          .map((item) => "${item.quantity}x ${item.productName}")
          .join('\n');
      return [
        formatDateTime.format(tx.timestamp.toDate()),
        itemsList,
        tx.paymentMethod,
        formatCurrency.format(tx.totalPrice),
        formatCurrency.format(tx.totalProfit),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Detail Transaksi",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.2),
          },
        ),
      ],
    );
  }
}
