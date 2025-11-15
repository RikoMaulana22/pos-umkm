// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../models/transaction_model.dart';
import '../services/report_service.dart';

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

  late Future<Map<String, Map<String, double>>> _salesDataFuture;
  int _selectedDays = 7;

  bool _isSilverOrGold = false; // <-- Penanda fitur premium

  @override
  void initState() {
    super.initState();

    _isSilverOrGold = widget.subscriptionPackage == "silver" ||
        widget.subscriptionPackage == "gold";

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

  // Dialog export (premium)
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Fitur Export"),
        content: const Text(
          "Fitur export laporan (PDF/Excel) hanya untuk paket Silver & Gold.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Export hanya muncul jika Silver/Gold
          if (_isSilverOrGold)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Export Laporan",
              onPressed: _showExportDialog,
            ),

          // Filter tanggal
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final transactions = snapshot.data!;

          if (transactions.isEmpty) {
            return const Center(child: Text("Belum ada data transaksi."));
          }

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
          // HITUNG PRODUK TERLARIS
          // ================================
          final Map<String, int> productSales = {};
          final Map<String, String> productNames = {};

          for (var tx in transactions) {
            for (var item in tx.items) {
              productSales.update(item.productId, (v) => v + item.quantity,
                  ifAbsent: () => item.quantity);
              productNames.putIfAbsent(item.productId, () => item.productName);
            }
          }

          final topProducts = (productSales.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(5)
              .toList();

          return SingleChildScrollView(
            child: Column(
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
                        AsyncSnapshot<Map<String, Map<String, double>>> snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
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
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < dates.length) {
                                    return Text(dates[value.toInt()],
                                        style: const TextStyle(fontSize: 10));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: salesSpots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      transactions.length > 10 ? 10 : transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];

                    return ListTile(
                      title: Text(formatCurrency.format(tx.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "${formatDateTime.format(tx.timestamp.toDate())}\n"
                        "Laba: ${formatCurrency.format(tx.totalProfit)}",
                        style: TextStyle(color: Colors.green[700]),
                      ),
                      trailing: Text(
                        "${tx.totalItems} item • ${tx.paymentMethod}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),

                const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

                // ===========================
                // PRODUK TERLARIS
                // ===========================
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "Produk Terlaris (Top 5)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                if (topProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Belum ada produk terjual.",
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topProducts.length,
                    itemBuilder: (context, index) {
                      final item = topProducts[index];
                      final name =
                          productNames[item.key] ?? "Produk tidak ditemukan";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(.1),
                          child: Text("${index + 1}",
                              style: TextStyle(color: primaryColor)),
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text("${item.value}x Terjual",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),

                const SizedBox(height: 40),
              ],
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
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
