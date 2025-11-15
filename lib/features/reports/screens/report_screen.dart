// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../models/transaction_model.dart';
import '../services/report_service.dart';
// 1. IMPOR LAYANAN PDF BARU
import '../services/pdf_export_service.dart';

class ReportScreen extends StatefulWidget {
  final String storeId;
  final String subscriptionPackage; // <-- Tambahan

  const ReportScreen({
    super.key,
    required this.storeId,
    required this.subscriptionPackage,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();

  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');
  // 2. INISIALISASI LAYANAN PDF
  final PdfExportService _pdfExportService = PdfExportService();

  late Future<Map<String, Map<String, double>>> _salesDataFuture;
  int _selectedDays = 7;

  bool _isSilverOrGold = false; // <-- Penanda fitur premium
  bool _isExporting = false; // 3. STATE LOADING EXPORT

  @override
  void initState() {
    super.initState();

    _isSilverOrGold = widget.subscriptionPackage == "silver" ||
        widget.subscriptionPackage == "gold";

    // Jika bronze, paksa filter ke 7 hari
    if (!_isSilverOrGold) {
      _selectedDays = 7;
    }
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _salesDataFuture = _reportService.getDailySalesAndProfitData(
        widget.storeId,
        _selectedDays,
      );
    });
  }

  // 4. UBAH FUNGSI INI MENJADI LOGIKA EKSPOR
  Future<void> _exportPdfReport(
    List<TransactionModel> transactions,
    double totalOmzet,
    double totalProfit,
    int totalItemsSold,
  ) async {
    setState(() {
      _isExporting = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Membuat laporan PDF..."),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final String? path = await _pdfExportService.generateSalesReport(
        transactions: transactions,
        totalOmzet: totalOmzet,
        totalProfit: totalProfit,
        totalTransactions: transactions.length,
        totalItemsSold: totalItemsSold,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Tampilkan snackbar sukses dengan tombol "Buka"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 10),
            content: Text("Laporan berhasil disimpan: $path"),
            action: SnackBarAction(
              label: "Buka",
              onPressed: () {
                _pdfExportService.openPdfFile(path);
              },
            ),
          ),
        );
        // Buka file secara otomatis
        await _pdfExportService.openPdfFile(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export PDF: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 5. Kita perlu data dari StreamBuilder untuk export,
          // jadi kita akan gunakan "builder" AppBar di bawah.
          // Tombol-tombol ini adalah placeholder sementara.
          if (_isSilverOrGold)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Export Laporan",
              onPressed: () {
                // Aksi akan ditangani oleh AppBar di dalam StreamBuilder
              },
            ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              _selectedDays = value;
              _refreshData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text("7 Hari Terakhir")),
              if (_isSilverOrGold)
                const PopupMenuItem(value: 30, child: Text("30 Hari Terakhir")),
            ],
          ),
        ],
      ),

      // STREAM transaksi realtime
      body: StreamBuilder<List<TransactionModel>>(
        stream: _reportService.getTransactions(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data transaksi."));
          }

          final transactions = snapshot.data!;

          // Hitung summary
          double totalOmzet = 0;
          double totalProfit = 0;
          int totalItems = 0;

          for (var tx in transactions) {
            totalOmzet += tx.totalPrice;
            totalProfit += tx.totalProfit;
            totalItems += tx.totalItems;
          }

          // ================================
          // 6. HAPUS LOGIKA PRODUK TERLARIS
          // ================================

          return Scaffold(
            // 7. GUNAKAN APPBAR BARU DI SINI
            // Ini memungkinkan tombol Export mengakses data 'transactions'
            appBar: AppBar(
              title: const Text("Laporan"),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                if (_isSilverOrGold)
                  IconButton(
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download),
                    tooltip: "Export Laporan (PDF)",
                    onPressed: _isExporting
                        ? null
                        : () {
                            // Panggil fungsi ekspor dengan data yang sudah siap
                            _exportPdfReport(
                              transactions,
                              totalOmzet,
                              totalProfit,
                              totalItems,
                            );
                          },
                  ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: "Filter Tanggal",
                  onSelected: (value) {
                    _selectedDays = value;
                    _refreshData();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 7, child: Text("7 Hari Terakhir")),
                    if (_isSilverOrGold)
                      const PopupMenuItem(
                          value: 30, child: Text("30 Hari Terakhir")),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================
                  // SUMMARY CARD
                  // ===========================
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildSummaryCard(
                                "Total Omzet",
                                formatCurrency.format(totalOmzet),
                                Icons.monetization_on,
                                Colors.blue),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                                "Total Laba",
                                formatCurrency.format(totalProfit),
                                Icons.trending_up,
                                Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildSummaryCard(
                                "Transaksi",
                                transactions.length.toString(),
                                Icons.receipt_long,
                                Colors.orange),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                                "Item Terjual",
                                totalItems.toString(),
                                Icons.shopping_bag,
                                Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ===========================
                  // GRAFIK
                  // ===========================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      "Grafik $_selectedDays Hari Terakhir",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                  ),

                  SizedBox(
                    height: 220,
                    child: FutureBuilder(
                      future: _salesDataFuture,
                      builder: (context,
                          AsyncSnapshot<Map<String, Map<String, double>>>
                              snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final salesData = snap.data!;
                        final dates = salesData.keys.toList();

                        final salesSpots = <FlSpot>[];
                        final profitSpots = <FlSpot>[];

                        for (int i = 0; i < dates.length; i++) {
                          salesSpots.add(FlSpot(
                              i.toDouble(), salesData[dates[i]]!["sales"]!));
                          profitSpots.add(FlSpot(
                              i.toDouble(), salesData[dates[i]]!["profit"]!));
                        }

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: (_selectedDays / 7)
                                      .ceilToDouble(), // Perbaikan interval
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < dates.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(dates[value.toInt()],
                                            style:
                                                const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 22,
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: salesSpots,
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: FlDotData(show: _selectedDays <= 7),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue.withOpacity(.15),
                                ),
                              ),
                              LineChartBarData(
                                spots: profitSpots,
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 3,
                                dotData: FlDotData(show: _selectedDays <= 7),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.withOpacity(.15),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

                  // ===========================
                  // RIWAYAT TRANSAKSI
                  // ===========================
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      "Riwayat Transaksi Terbaru",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        transactions.length > 10 ? 10 : transactions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(formatCurrency.format(tx.totalPrice),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${formatDateTime.format(tx.timestamp.toDate())}\n"
                          "Laba: ${formatCurrency.format(tx.totalProfit)}",
                          style: TextStyle(color: Colors.green[700]),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "${tx.totalItems} item • ${tx.paymentMethod}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================
  // WIDGET KARTU RINGKASAN
  // ===========================
  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
