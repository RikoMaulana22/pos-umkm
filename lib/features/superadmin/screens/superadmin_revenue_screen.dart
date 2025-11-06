// lib/features/superadmin/screens/superadmin_revenue_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/superadmin_service.dart';
import '../../../shared/theme.dart';

class SuperAdminRevenueScreen extends StatefulWidget {
  const SuperAdminRevenueScreen({super.key});

  @override
  State<SuperAdminRevenueScreen> createState() => _SuperAdminRevenueScreenState();
}

class _SuperAdminRevenueScreenState extends State<SuperAdminRevenueScreen> {
  final SuperAdminService _service = SuperAdminService();
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penghasilan'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getRevenueData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Tidak ada data."));
          }

          final data = snapshot.data!;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Card Total Penghasilan
                Card(
                  elevation: 4,
                  color: primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          "Total Potensi Penghasilan",
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatCurrency.format(data['totalRevenue']),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Grid Statistik
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true, // Penting di dalam Column
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard("Total Toko", data['totalStores'].toString(), Icons.store, Colors.blue),
                    _buildStatCard("Langganan Aktif", data['activeSubscriptions'].toString(), Icons.check_circle, Colors.green),
                    _buildStatCard("Langganan Habis", data['expiredSubscriptions'].toString(), Icons.timer_off, Colors.orange),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget helper untuk kartu statistik
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(title, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}