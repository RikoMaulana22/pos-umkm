// lib/features/reports/screens/report_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../models/transaction_model.dart';
import '../services/report_service.dart';
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
      print('🔄 Memulai migration check...');
      await _reportService.migrateOldTransactions(widget.storeId);
      _isMigrationDone = true;
      print('✅ Migration check selesai');
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }

  void _refreshData() {
    print(
        '🔄 Refreshing data: days=$_selectedDays, cashierId=$_selectedUserId');
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _exportPdfReport(
    List<TransactionModel> transactions,
    double totalOmzet,
    double totalProfit,
    int totalItemsSold,
  ) async {
    if (transactions.isEmpty) {
      _showError("Tidak ada data transaksi untuk diekspor.");
      return;
    }

    setState(() => _isExporting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text("Membuat laporan PDF..."),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(minutes: 2),
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text("Laporan disimpan")),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: "Buka",
              onPressed: () => _pdfExportService.openPdfFile(path),
            ),
          ),
        );
      }
    } catch (e) {
      _showError("Gagal export PDF: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<TransactionModel>>(
        stream: _reportService.getTransactions(
          widget.storeId,
          cashierId: _selectedUserId,
          days: _selectedDays,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("📊 Laporan"),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat laporan...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Error"),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red[300]),
                      const SizedBox(height: 20),
                      const Text(
                        "Error Memuat Laporan",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedUserId = null;
                            _selectedDays = 7;
                            _refreshData();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Muat Ulang"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final List<TransactionModel> transactions = snapshot.data ?? [];

          double totalOmzet = 0;
          double totalProfit = 0;
          int totalItems = 0;
          Map<String, int> productSales = {};
          Map<int, int> hourlySales = Map.fromIterable(
            List.generate(24, (i) => i),
            key: (hour) => hour,
            value: (hour) => 0,
          );

          if (transactions.isNotEmpty) {
            for (var tx in transactions) {
              totalOmzet += tx.totalPrice;
              totalProfit += tx.totalProfit;
              totalItems += tx.totalItems;

              if (_isGold) {
                int hour = tx.timestamp.toDate().hour;
                hourlySales.update(hour, (value) => value + 1,
                    ifAbsent: () => 1);

                for (var item in tx.items) {
                  productSales.update(
                    item.productName,
                    (value) => value + item.quantity,
                    ifAbsent: () => item.quantity,
                  );
                }
              }
            }
          }

          final sortedProducts = productSales.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5Products = sortedProducts.take(5).toList();

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('📊 Laporan'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (_isSilverOrGold)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      tooltip: "Export PDF",
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
                  ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.calendar_today_rounded),
                  tooltip: "Filter Tanggal",
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 7,
                      child: Row(
                        children: [
                          Icon(Icons.date_range, size: 20),
                          SizedBox(width: 8),
                          Text("7 Hari"),
                        ],
                      ),
                    ),
                    if (_isSilverOrGold)
                      const PopupMenuItem(
                        value: 30,
                        child: Row(
                          children: [
                            Icon(Icons.date_range, size: 20),
                            SizedBox(width: 8),
                            Text("30 Hari"),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    setState(() => _selectedDays = value);
                    _refreshData();
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✨ Header dengan Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Period Info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Periode: $_selectedDays hari terakhir',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Title
                          Text(
                            'Ringkasan Penjualan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✨ User Filter (Gold only)
                  if (_isGold) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildUserFilterWidget(),
                    ),
                  ],

                  // ✨ Filter Indicator
                  if (_selectedUserId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt_rounded,
                                color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Filter kasir aktif",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() => _selectedUserId = null);
                                _refreshData();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ✨ Summary Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
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
                              title: "Total Laba",
                              value: formatCurrency.format(totalProfit),
                              icon: Icons.money_rounded,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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

                  // ✨ Sales Chart
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grafik Penjualan & Laba',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: SizedBox(
                            height: 280,
                            child: FutureBuilder(
                              future: _salesDataFuture,
                              builder: (context,
                                  AsyncSnapshot<
                                          Map<String, Map<String, double>>>
                                      snap) {
                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  );
                                }

                                if (snap.hasError) {
                                  return Center(
                                    child: Text("Error: ${snap.error}"),
                                  );
                                }

                                final salesData = snap.data!;
                                final dates = salesData.keys.toList();

                                if (dates.isEmpty) {
                                  return Center(
                                    child: Text(
                                      "Tidak ada data",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  );
                                }

                                final salesSpots = <FlSpot>[];
                                final profitSpots = <FlSpot>[];

                                for (int i = 0; i < dates.length; i++) {
                                  salesSpots.add(FlSpot(i.toDouble(),
                                      salesData[dates[i]]!["sales"]!));
                                  profitSpots.add(FlSpot(i.toDouble(),
                                      salesData[dates[i]]!["profit"]!));
                                }

                                return LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                        color: Colors.grey[200]!,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: (_selectedDays / 7)
                                              .ceilToDouble(),
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() < dates.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  dates[value.toInt()],
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                          reservedSize: 30,
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: salesSpots,
                                        isCurved: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue,
                                            Colors.blue.withOpacity(0.5)
                                          ],
                                        ),
                                        barWidth: 3,
                                        dotData: FlDotData(
                                          show: _selectedDays <= 7,
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.withOpacity(0.2),
                                              Colors.blue.withOpacity(0.01),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                      LineChartBarData(
                                        spots: profitSpots,
                                        isCurved: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green,
                                            Colors.green.withOpacity(0.5)
                                          ],
                                        ),
                                        barWidth: 3,
                                        dotData: FlDotData(
                                          show: _selectedDays <= 7,
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.withOpacity(0.2),
                                              Colors.green.withOpacity(0.01),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Penjualan',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Laba',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ✨ Recent Transactions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaksi Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (transactions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada transaksi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length > 10
                                ? 10
                                : transactions.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              final bool isFirst =
                                  index == 0;
                              final bool isLast = index ==
                                  (transactions.length > 10
                                      ? 9
                                      : transactions.length - 1);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: isFirst
                                        ? BorderSide(
                                            color: Colors.grey[200]!,
                                          )
                                        : BorderSide.none,
                                    bottom: isLast
                                        ? BorderSide(
                                            color: Colors.grey[200]!,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: _buildTransactionTile(tx),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  // ✨ Gold Analytics
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

  // ✨ Modern Summary Card
  Widget _buildModernSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ Transaction Tile
  Widget _buildTransactionTile(TransactionModel tx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCurrency.format(tx.totalPrice),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatDateTime.format(tx.timestamp.toDate()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Text(
            "Laba: ${formatCurrency.format(tx.totalProfit)}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }

  // ✨ User Filter Widget
  Widget _buildUserFilterWidget() {
    return StreamBuilder<List<UserModel>>(
      stream: _authService.getStoreUsersForFilter(widget.storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error memuat user: ${snapshot.error}"),
          );
        }

        final users = snapshot.data ?? [];
        final Map<String, UserModel> uniqueUsersMap = {};
        for (final user in users) {
          uniqueUsersMap[user.uid] = user;
        }
        final uniqueUsers = uniqueUsersMap.values.toList();

        String? dropdownValue = _selectedUserId;
        if (_selectedUserId != null) {
          bool isValidUser = uniqueUsers.any((u) => u.uid == _selectedUserId);
          if (!isValidUser) {
            dropdownValue = null;
          }
        }

        return DropdownButtonFormField<String>(
          value: dropdownValue ?? "ALL",
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person_rounded, color: primaryColor),
            hintText: "Filter berdasarkan kasir",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: [
            const DropdownMenuItem(
              value: "ALL",
              child: Text("Semua Kasir"),
            ),
            ...uniqueUsers.map((user) {
              return DropdownMenuItem(
                value: user.uid,
                child: Text("${user.username} (${user.role})"),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedUserId = value == "ALL" ? null : value;
            });
            _refreshData();
          },
        );
      },
    );
  }

  // ✨ Gold Analytics Widget
  Widget _buildGoldAnalytics(
    List<MapEntry<String, int>> topProducts,
    Map<int, int> hourlySales,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Products Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Produk Terlaris',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Belum ada data penjualan",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProducts.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final item = topProducts[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber[100],
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                        title: Text(
                          item.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Text(
                            "${item.value}x",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // Hourly Sales Chart
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Jam Ramai (Per Transaksi)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[200]!,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value % 6 == 0) {
                                return Text(
                                  "${value.toInt()}:00",
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text("");
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      barGroups: hourlySales.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.6)
                                ],
                              ),
                              width: 8,
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
          ),
        ),
      ],
    );
  }
}
