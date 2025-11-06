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
  int _selectedDays = 7; // Default 7 hari terakhir

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
          // Filter Dropdown
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              "Penjualan $_selectedDays Hari Terakhir",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
          // Grafik (sama seperti sebelumnya, tapi reload saat _selectedDays berubah)
          Container(
            height: 250,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<Map<String, double>>(
              future: _salesDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada data penjualan."));
                }
                final salesData = snapshot.data!;
                final List<FlSpot> spots = [];
                final List<String> dates = salesData.keys.toList();
                for (int i = 0; i < dates.length; i++) {
                  spots.add(FlSpot(i.toDouble(), salesData[dates[i]]!));
                }
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false), // Grid lebih bersih
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (_selectedDays / 7).ceilToDouble(), // Interval dinamis
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < dates.length) {
                              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(dates[value.toInt()], style: const TextStyle(fontSize: 10)));
                            }
                            return const Text("");
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: primaryColor,
                        barWidth: 3,
                        dotData: FlDotData(show: _selectedDays <= 7), // Hanya tunjukkan titik jika 7 hari
                        belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.2)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Riwayat Transaksi (Semua)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // Daftar Transaksi (sama seperti sebelumnya)
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _reportService.getTransactions(widget.storeId),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                 if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Belum ada transaksi."));
                 
                 final transactions = snapshot.data!;
                 return ListView.separated(
                   padding: const EdgeInsets.all(16),
                   itemCount: transactions.length,
                   separatorBuilder: (context, index) => const Divider(),
                   itemBuilder: (context, index) {
                     final tx = transactions[index];
                     return ListTile(
                       dense: true,
                       contentPadding: EdgeInsets.zero,
                       title: Text(formatCurrency.format(tx.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text(formatDateTime.format(tx.timestamp.toDate())),
                       trailing: Chip(label: Text(tx.paymentMethod, style: const TextStyle(fontSize: 12))),
                     );
                   },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }
}