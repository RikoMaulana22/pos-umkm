// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../models/transaction_model.dart';
import '../services/report_service.dart';
import '../services/pdf_export_service.dart';

class ReportScreen extends StatefulWidget {
  final String storeId;
  final String subscriptionPackage;

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
  final PdfExportService _pdfExportService = PdfExportService();

  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');

  late Future<Map<String, Map<String, double>>> _salesDataFuture;
  int _selectedDays = 7;

  bool _isSilverOrGold = false;
  bool _isGold = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _isSilverOrGold = widget.subscriptionPackage == "silver" ||
        widget.subscriptionPackage == "gold";
    _isGold = widget.subscriptionPackage == "gold";

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

  // Fungsi export PDF (tidak berubah)
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
      // ===========================================
      // PERBAIKAN: HAPUS AppBar DARI SINI
      // ===========================================
      // appBar: AppBar(
      //   title: const Text("Laporan"),
      //   ...
      // ),

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
            // Kita tetap perlu AppBar meski data kosong
            return Scaffold(
                appBar: AppBar(
                  title: const Text("Laporan"),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                body: const Center(child: Text("Belum ada data transaksi.")));
          }

          final transactions = snapshot.data!;

          // Hitung summary
          double totalOmzet = 0;
          double totalProfit = 0;
          int totalItems = 0;

          // LOGIKA ANALITIK GOLD
          Map<String, int> productSales = {};
          Map<int, int> hourlySales = Map.fromIterable(
            List.generate(24, (i) => i),
            key: (hour) => hour,
            value: (hour) => 0,
          );

          for (var tx in transactions) {
            // Summary
            totalOmzet += tx.totalPrice;
            totalProfit += tx.totalProfit;
            totalItems += tx.totalItems;

            if (_isGold) {
              // --- Logika Jam Ramai ---
              int hour = tx.timestamp.toDate().hour;
              hourlySales.update(
                  hour, (value) => value + 1, // Hitung jumlah transaksi
                  ifAbsent: () => 1);

              // --- Logika Produk Terlaris ---
              for (var item in tx.items) {
                productSales.update(
                  item.productName,
                  (value) => value + item.quantity,
                  ifAbsent: () => item.quantity,
                );
              }
            }
          }

          // Urutkan map produk
          final sortedProducts = productSales.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5Products = sortedProducts.take(5).toList();

          // ================================

          return Scaffold(
            // Ini adalah AppBar YANG BENAR (di dalam StreamBuilder)
            appBar: AppBar(
              title: const Text("Laporan"),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              // automaticallyImplyLeading: false, // Hapus ini agar tombol back muncul
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
                  // SUMMARY CARD
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

                  // GRAFIK
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
                                  interval: (_selectedDays / 7).ceilToDouble(),
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

                  // RIWAYAT TRANSAKSI
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
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

                  // TAMPILKAN ANALITIK GOLD
                  if (_isGold) _buildGoldAnalytics(top5Products, hourlySales),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET ANALITIK GOLD
  Widget _buildGoldAnalytics(
    List<MapEntry<String, int>> topProducts,
    Map<int, int> hourlySales,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- PRODUK TERLARIS ---
        const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.star_rate_rounded, color: Colors.amber[800]),
              const SizedBox(width: 8),
              Text(
                "Analitik Gold: Produk Terlaris",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900]),
              ),
            ],
          ),
        ),
        if (topProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Data penjualan belum cukup.",
                style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topProducts.length,
            itemBuilder: (context, index) {
              final item = topProducts[index];
              return Card(
                elevation: 0,
                color: Colors.amber[50],
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber[100],
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900]),
                    ),
                  ),
                  title: Text(item.key,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    "${item.value}x Terjual",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),

        // --- JAM RAMAI ---
        const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: Colors.blue[800]),
              const SizedBox(width: 8),
              Text(
                "Analitik Gold: Jam Ramai",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900]),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Tampilkan label jam setiap 6 jam
                        if (value % 6 == 0) {
                          return Text("${value.toInt()}:00",
                              style: const TextStyle(fontSize: 10));
                        }
                        return const Text("");
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: hourlySales.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key, // Jam (0-23)
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(), // Jumlah transaksi
                        color: primaryColor,
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET KARTU RINGKASAN (tidak berubah)
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
