// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../models/transaction_model.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  final String storeId;
  const ReportScreen({super.key, required this.storeId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');
  
  late Future<Map<String, double>> _salesDataFuture;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _salesDataFuture = _reportService.getDailySalesData(widget.storeId, _selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filter Tanggal",
            onSelected: (value) {
              _selectedDays = value;
              _refreshData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text("7 Hari Terakhir")),
              const PopupMenuItem(value: 30, child: Text("30 Hari Terakhir")),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _reportService.getTransactions(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
             return const Center(child: Text("Belum ada data transaksi."));
          }

          final transactions = snapshot.data!;
          
          // Hitung Ringkasan
          double totalOmzet = 0;
          int totalItemsSold = 0;
          for (var tx in transactions) {
            totalOmzet += tx.totalPrice;
            totalItemsSold += tx.totalItems;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KARTU RINGKASAN (WOW FACTOR)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildSummaryCard("Total Omzet", formatCurrency.format(totalOmzet), Icons.monetization_on, Colors.green),
                      const SizedBox(width: 12),
                      _buildSummaryCard("Transaksi", transactions.length.toString(), Icons.receipt_long, Colors.blue),
                      const SizedBox(width: 12),
                      _buildSummaryCard("Item Terjual", totalItemsSold.toString(), Icons.shopping_bag, Colors.orange),
                    ],
                  ),
                ),

                // 2. GRAFIK PENJUALAN
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text("Grafik $_selectedDays Hari Terakhir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                ),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<Map<String, double>>(
                    future: _salesDataFuture,
                    builder: (context, chartSnapshot) {
                      if (!chartSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final salesData = chartSnapshot.data!;
                      final List<FlSpot> spots = [];
                      final List<String> dates = salesData.keys.toList();
                      for (int i = 0; i < dates.length; i++) {
                        spots.add(FlSpot(i.toDouble(), salesData[dates[i]]!));
                      }
                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: (_selectedDays/7).ceilToDouble(), getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < dates.length) {
                                return Padding(padding: const EdgeInsets.only(top:8), child: Text(dates[value.toInt()], style: const TextStyle(fontSize: 10)));
                              }
                              return const Text("");
                            }, reservedSize: 22)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(spots: spots, isCurved: true, color: primaryColor, barWidth: 3, dotData: FlDotData(show: _selectedDays <= 7), belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.15))),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 3. DAFTAR RIWAYAT TERAKHIR
                const Divider(thickness: 8, color: Color(0xFFF5F5F5)), // Pemisah tebal
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text("Riwayat Transaksi Terbaru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListView.separated(
                  shrinkWrap: true, // Agar bisa di dalam SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Matikan scroll listviewnya
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length > 10 ? 10 : transactions.length, // Tampilkan max 10 terakhir
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(formatCurrency.format(tx.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(formatDateTime.format(tx.timestamp.toDate())),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Text("${tx.totalItems} item • ${tx.paymentMethod}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}