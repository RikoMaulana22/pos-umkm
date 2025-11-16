// lib/features/reports/services/pdf_export_service.dart
import 'dart:typed_data'; // Tambahan
import 'package:flutter/foundation.dart'; // Import baru untuk kIsWeb
import 'package:flutter/services.dart';
import 'package:open_file_plus/open_file_plus.dart';
// import 'package:path_provider/path_provider.dart'; // Dihapus, dipindah ke helper
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:permission_handler/permission_handler.dart'; // Dihapus, dipindah ke helper
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

// 1. IMPOR KONDISIONAL
// Ini akan otomatis memilih file yang benar saat kompilasi
import 'pdf_saver_stub.dart'
    if (dart.library.io) 'pdf_saver_mobile.dart' // Untuk Android/iOS
    if (dart.library.html) 'pdf_saver_web.dart'; // Untuk Web

class PdfExportService {
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yy HH:mm');

  Future<String?> generateSalesReport({
    required List<TransactionModel> transactions,
    required double totalOmzet,
    required double totalProfit,
    required int totalTransactions,
    required int totalItemsSold,
  }) async {
    // 2. HAPUS SEMUA BLOK IZIN DARI SINI
    // Logika izin sekarang ada di 'pdf_saver_mobile.dart'

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
              totalTransactions: totalTransactions,
              totalItemsSold: totalItemsSold,
            ),
            pw.SizedBox(height: 20),
            _buildTransactionTable(context, transactions),
          ];
        },
      ),
    );

    // 3. UBAH LOGIKA PENYIMPANAN
    final Uint8List bytes = await pdf.save(); // Dapatkan bytes PDF
    final String fileName =
        'Laporan_Penjualan_${DateFormat('yyyy-MM-dd-HH-mm').format(DateTime.now())}.pdf';

    // 4. PANGGIL HELPER KONDISIONAL
    // 'savePdfFile' sekarang akan merujuk ke 'pdf_saver_mobile.dart' di HP
    // atau 'pdf_saver_web.dart' di Web
    final String? path = await savePdfFile(fileName: fileName, bytes: bytes);

    return path;
  }

  // Fungsi helper untuk membuka file
  Future<void> openPdfFile(String path) async {
    // 5. PENGECEKAN kIsWeb
    // Membuka file di web tidak dimungkinkan dari path,
    // karena file sudah langsung di-download oleh browser.
    if (kIsWeb) {
      return;
    }

    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      throw Exception("Gagal membuka file PDF: ${result.message}");
    }
  }

  // ... (Semua widget _buildHeader, _buildSummary, _summaryItem, _buildTransactionTable TIDAK BERUBAH) ...

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Laporan Penjualan",
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
    required int totalTransactions,
    required int totalItemsSold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Ringkasan",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem("Total Omzet", formatCurrency.format(totalOmzet)),
            _summaryItem("Total Laba", formatCurrency.format(totalProfit)),
          ],
        ),
        pw.SizedBox(height: 10),
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

  pw.Widget _summaryItem(String title, String value) {
    return pw.Container(
      width: PdfPageFormat.a4.availableWidth / 2.2,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
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
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionTable(
      pw.Context context, List<TransactionModel> transactions) {
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
        pw.Text(
          "Detail Transaksi",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
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
