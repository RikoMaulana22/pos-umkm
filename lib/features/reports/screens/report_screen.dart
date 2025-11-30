// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart'; // [WAJIB] Import Expense Model
import '../services/report_service.dart';
import '../services/expense_service.dart'; // [WAJIB] Import Expense Service
import '../services/pdf_export_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';

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
  final ExpenseService _expenseService =
      ExpenseService(); // Service Pengeluaran
  final PdfExportService _pdfExportService = PdfExportService();
  final AuthService _authService = AuthService();

  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');

  late Future<Map<String, Map<String, double>>> _salesDataFuture;
  int _selectedDays = 7;
  bool _isSilverOrGold = false;
  bool _isGold = false;
  bool _isExporting = false;
  String? _selectedUserId;
  bool _isMigrationDone = false;

  @override
  void initState() {
    super.initState();
    _isSilverOrGold = widget.subscriptionPackage == "silver" ||
        widget.subscriptionPackage == "gold";
    _isGold = widget.subscriptionPackage == "gold";

    if (!_isSilverOrGold) {
      _selectedDays = 7;
    }

    _runMigrationOnce();
    _refreshData();
  }

  Future<void> _runMigrationOnce() async {
    if (_isMigrationDone) return;
    try {
      await _reportService.migrateOldTransactions(widget.storeId);
      _isMigrationDone = true;
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }

  void _refreshData() {
    setState(() {
      _salesDataFuture = _reportService.getDailySalesAndProfitData(
        widget.storeId,
        _selectedDays,
        cashierId: _selectedUserId,
      );
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // Fungsi Export PDF yang Diperbarui
  Future<void> _exportPdfReport(
    List<TransactionModel> transactions,
    double totalOmzet,
    double totalProfit,
    double totalExpense, // Parameter Baru
    double netProfit, // Parameter Baru
    int totalItemsSold,
  ) async {
    if (transactions.isEmpty) {
      _showError("Tidak ada data transaksi untuk diekspor.");
      return;
    }

    setState(() => _isExporting = true);
    try {
      final String? path = await _pdfExportService.generateSalesReport(
        transactions: transactions,
        totalOmzet: totalOmzet,
        totalProfit: totalProfit,
        totalExpense: totalExpense, // Kirim ke service PDF
        netProfit: netProfit, // Kirim ke service PDF
        totalTransactions: transactions.length,
        totalItemsSold: totalItemsSold,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Laporan berhasil disimpan"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "Buka",
              textColor: Colors.white,
              onPressed: () => _pdfExportService.openPdfFile(path),
            ),
          ),
        );
      }
    } catch (e) {
      _showError("Gagal export PDF: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // 1. Stream Pertama: Ambil Data Transaksi
      body: StreamBuilder<List<TransactionModel>>(
        stream: _reportService.getTransactions(
          widget.storeId,
          cashierId: _selectedUserId,
          days: _selectedDays,
        ),
        builder: (context, txSnapshot) {
          if (txSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (txSnapshot.hasError) {
            return Center(child: Text("Error: ${txSnapshot.error}"));
          }

          final transactions = txSnapshot.data ?? [];

          // Hitung Metrik Transaksi
          double totalOmzet = 0;
          double totalGrossProfit = 0; // Laba Kotor
          int totalItems = 0;
          Map<String, int> productSales = {};
          Map<int, int> hourlySales = {};

          for (var tx in transactions) {
            totalOmzet += tx.totalPrice;
            totalGrossProfit += tx.totalProfit;
            totalItems += tx.totalItems;

            if (_isGold) {
              int hour = tx.timestamp.toDate().hour;
              hourlySales.update(hour, (v) => v + 1, ifAbsent: () => 1);
              for (var item in tx.items) {
                productSales.update(item.productName, (v) => v + item.quantity,
                    ifAbsent: () => item.quantity);
              }
            }
          }

          final sortedProducts = productSales.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5Products = sortedProducts.take(5).toList();

          // 2. Stream Kedua: Ambil Data Pengeluaran
          return StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.getExpenses(widget.storeId,
                days: _selectedDays),
            builder: (context, expSnapshot) {
              // Jika loading pengeluaran, kita tetap tampilkan UI tapi dengan nilai 0 sementara
              // atau tampilkan loading kecil. Disini kita pakai default 0 agar UI mulus.

              final expenses = expSnapshot.data ?? [];

              // Hitung Total Pengeluaran
              double totalExpense =
                  expenses.fold(0, (sum, item) => sum + item.amount);

              // Hitung Laba Bersih
              double netProfit = totalGrossProfit - totalExpense;

              return Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: _buildAppBar(transactions, totalOmzet, totalGrossProfit,
                    totalExpense, netProfit, totalItems),
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Gradient
                      _buildHeader(),

                      // Filter User (Gold)
                      if (_isGold)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildUserFilterWidget(),
                        ),

                      if (_selectedUserId != null) _buildFilterIndicator(),

                      // KARTU RINGKASAN (UPDATED)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Baris 1: Omzet & Laba Kotor
                            Row(
                              children: [
                                _buildModernSummaryCard(
                                  title: "Total Omzet",
                                  value: formatCurrency.format(totalOmzet),
                                  icon: Icons.trending_up_rounded,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 12),
                                _buildModernSummaryCard(
                                  title: "Laba Kotor",
                                  value:
                                      formatCurrency.format(totalGrossProfit),
                                  icon: Icons.monetization_on_rounded,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Baris 2: Pengeluaran & Laba Bersih [BARU]
                            Row(
                              children: [
                                _buildModernSummaryCard(
                                  title: "Pengeluaran",
                                  value: formatCurrency.format(totalExpense),
                                  icon: Icons.money_off_rounded,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                _buildModernSummaryCard(
                                  title: "Laba Bersih",
                                  value: formatCurrency.format(netProfit),
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: netProfit >= 0
                                      ? Colors.teal
                                      : Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Baris 3: Statistik Jumlah
                            Row(
                              children: [
                                _buildModernSummaryCard(
                                  title: "Transaksi",
                                  value: transactions.length.toString(),
                                  icon: Icons.receipt_rounded,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                _buildModernSummaryCard(
                                  title: "Item Terjual",
                                  value: totalItems.toString(),
                                  icon: Icons.shopping_bag_rounded,
                                  color: Colors.purple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Grafik Penjualan (Hanya menampilkan penjualan & laba kotor harian)
                      _buildSalesChart(
                          dates: [],
                          salesSpots: [],
                          profitSpots: []), // Placeholder, logic chart ada di method bawah

                      // Transaksi Terbaru
                      _buildRecentTransactions(transactions),

                      // Analitik Gold
                      if (_isGold)
                        _buildGoldAnalytics(top5Products, hourlySales),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  PreferredSizeWidget _buildAppBar(List<TransactionModel> tx, double omzet,
      double grossProfit, double expense, double netProfit, int items) {
    return AppBar(
      title: const Text('📊 Laporan Keuangan'),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_isSilverOrGold)
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download_rounded),
            onPressed: _isExporting
                ? null
                : () => _exportPdfReport(
                    tx, omzet, grossProfit, expense, netProfit, items),
          ),
        PopupMenuButton<int>(
          icon: const Icon(Icons.calendar_today_rounded),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 7, child: Text("7 Hari")),
            if (_isSilverOrGold)
              const PopupMenuItem(value: 30, child: Text("30 Hari")),
          ],
          onSelected: (value) {
            setState(() => _selectedDays = value);
            _refreshData();
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Periode: $_selectedDays hari terakhir',
              style: const TextStyle(color: Colors.white70)),
          const Text('Ringkasan Bisnis',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildModernSummaryCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(
      {required List<FlSpot> salesSpots,
      required List<FlSpot> profitSpots,
      required List<String> dates}) {
    // Menggunakan FutureBuilder yang sudah ada untuk grafik
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: FutureBuilder(
          future: _salesDataFuture,
          builder:
              (context, AsyncSnapshot<Map<String, Map<String, double>>> snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snap.hasError || !snap.hasData)
              return const Center(child: Text("Gagal memuat grafik"));

            final data = snap.data!;
            final datesList = data.keys.toList();
            if (datesList.isEmpty)
              return const Center(child: Text("Tidak ada data grafik"));

            final sSpots = <FlSpot>[];
            final pSpots = <FlSpot>[];
            for (int i = 0; i < datesList.length; i++) {
              sSpots.add(FlSpot(i.toDouble(), data[datesList[i]]!['sales']!));
              pSpots.add(FlSpot(i.toDouble(), data[datesList[i]]!['profit']!));
            }

            return LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() >= 0 &&
                              val.toInt() < datesList.length) {
                            return Text(datesList[val.toInt()],
                                style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                        interval: (datesList.length / 7).ceilToDouble()),
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
                      spots: sSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false)),
                  LineChartBarData(
                      spots: pSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: false)),
                ]));
          },
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Transaksi Terbaru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final tx = transactions[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(formatCurrency.format(tx.totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(formatDateTime.format(tx.timestamp.toDate())),
                trailing: Text("Laba: ${formatCurrency.format(tx.totalProfit)}",
                    style: TextStyle(color: Colors.green[700], fontSize: 12)),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildGoldAnalytics(List topProducts, Map hourlySales) {
    // Placeholder simple untuk analytics
    return const SizedBox.shrink();
  }

  // Widget filter user dan filter indicator bisa disalin dari kode sebelumnya jika diperlukan
  Widget _buildUserFilterWidget() => const SizedBox.shrink();
  Widget _buildFilterIndicator() => const SizedBox.shrink();
}
