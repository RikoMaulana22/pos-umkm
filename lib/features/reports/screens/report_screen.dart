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

    // Migration - comment setelah berhasil
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
          content: Text(message),
          backgroundColor: Colors.red,
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Laporan PDF berhasil di-download."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError("Gagal export PDF: ${e.toString()}");
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
                title: const Text("Laporan"),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Error"),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        "Error Memuat Transaksi",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
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
                        label: const Text("Reset Filter & Coba Lagi"),
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
            appBar: AppBar(
              title: Text("Laporan ${_selectedDays} Hari"),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
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
                    setState(() {
                      _selectedDays = value;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _refreshData();
                    });
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
                  if (_isGold) _buildUserFilterWidget(),

                  // Indikator filter sederhana (tanpa nested StreamBuilder)
                  if (_selectedUserId != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
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
                              setState(() {
                                _selectedUserId = null;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _refreshData();
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      "Grafik Penjualan Toko $_selectedDays Hari Terakhir",
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
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snap.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Error: ${snap.error}"),
                            ),
                          );
                        }

                        final salesData = snap.data!;
                        final dates = salesData.keys.toList();

                        if (dates.isEmpty) {
                          return const Center(
                            child: Text(
                              "Tidak ada data untuk ditampilkan",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

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
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      "Riwayat Transaksi Terbaru",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              "Tidak ada transaksi untuk filter ini.",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
                          // ✅ PERBAIKAN: Jangan gunakan Flexible di trailing
                          trailing: Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              "${tx.totalItems} item",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
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

  // ✅ FIXED: Widget filter user TANPA validasi yang menyebabkan loop
  Widget _buildUserFilterWidget() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: StreamBuilder<List<UserModel>>(
        stream: _authService.getStoreUsersForFilter(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error memuat user: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final users = snapshot.data ?? [];

          // ✅ Hapus duplikat berdasarkan UID
          final Map<String, UserModel> uniqueUsersMap = {};
          for (final user in users) {
            uniqueUsersMap[user.uid] = user;
          }
          final uniqueUsers = uniqueUsersMap.values.toList();

          // ✅ PERBAIKAN: Hanya validasi, JANGAN auto-reset
          String? dropdownValue = _selectedUserId;

          // Jika _selectedUserId tidak null, cek apakah ada di list
          if (_selectedUserId != null) {
            bool isValidUser = uniqueUsers.any((u) => u.uid == _selectedUserId);
            if (!isValidUser) {
              // User tidak ditemukan, set dropdown ke "ALL" tapi JANGAN ubah state
              dropdownValue = null;
              print(
                  '⚠️ Warning: Selected user $_selectedUserId not found in dropdown list');
            }
          }

          print(
              '👥 Users count: ${uniqueUsers.length}, Selected: $_selectedUserId, Dropdown value: ${dropdownValue ?? "ALL"}');

          return DropdownButtonFormField<String>(
            value: dropdownValue ?? "ALL",
            hint: const Text("Filter berdasarkan User"),
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_search, color: Colors.grey[600]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              fillColor: Colors.grey.shade50,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: "ALL",
                child: Text("Semua User",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...uniqueUsers.map((UserModel user) {
                return DropdownMenuItem<String>(
                  value: user.uid,
                  child: Text(
                    "${user.username} (${user.role})",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                );
              }).toList(),
            ],
            onChanged: (String? newValue) {
              print('🔄 User selected: $newValue');
              setState(() {
                _selectedUserId = newValue == "ALL" ? null : newValue;
              });
              // Jangan gunakan WidgetsBinding, langsung panggil
              _refreshData();
            },
          );
        },
      ),
    );
  }

  Widget _buildGoldAnalytics(
    List<MapEntry<String, int>> topProducts,
    Map<int, int> hourlySales,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: Colors.blue[800]),
              const SizedBox(width: 8),
              Text(
                "Analitik Gold: Jam Ramai (Per Transaksi)",
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
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
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
