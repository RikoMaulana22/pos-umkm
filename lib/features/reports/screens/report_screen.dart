// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart'; // <-- 1. Impor FL Chart
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
  
  // Variabel untuk menyimpan data chart
  late Future<Map<String, double>> _salesDataFuture;

  @override
  void initState() {
    super.initState();
    // Ambil data penjualan 7 hari terakhir saat halaman dibuka
    _salesDataFuture = _reportService.getDailySalesData(widget.storeId, 7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // BAGIAN 1: GRAFIK (Sekarang Fungsional)
          // ==================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              "Penjualan 7 Hari Terakhir",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
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
                // Siapkan titik (spot) untuk grafik
                final List<FlSpot> spots = [];
                final List<String> dates = salesData.keys.toList();
                
                for (int i = 0; i < dates.length; i++) {
                  spots.add(FlSpot(i.toDouble(), salesData[dates[i]]!));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            // Tampilkan label tanggal di sumbu X
                            if (value.toInt() < dates.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(dates[value.toInt()], style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return const Text("");
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            // Sembunyikan label sumbu Y
                            return const Text("");
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    minY: 0,
                    // max-Y bisa diatur otomatis atau manual
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: primaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // ==================================================
          // BAGIAN 2: RIWAYAT TRANSAKSI
          // ==================================================
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Detail Riwayat",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _reportService.getTransactions(widget.storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada transaksi."));
                }

                final transactions = snapshot.data!;

                // Menggunakan ListView agar lebih mobile-friendly
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: primaryColor),
                        title: Text(
                          formatCurrency.format(tx.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(formatDateTime.format(tx.timestamp.toDate())),
                        trailing: Text("${tx.totalItems} item (${tx.paymentMethod})"),
                        onTap: () {
                          // TODO: Buka halaman detail struk
                          print("Membuka detail transaksi: ${tx.id}");
                        },
                      ),
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