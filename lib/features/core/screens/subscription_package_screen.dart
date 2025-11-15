// lib/features/core/screens/subscription_package_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
// 1. HAPUS CUSTOM_BUTTON, KITA AKAN GUNAKAN ELEVATEDBUTTON
// 2. IMPOR HALAMAN UPLOAD BARU
import 'payment_upload_screen.dart';

class SubscriptionPackageScreen extends StatefulWidget {
  final String storeId;
  const SubscriptionPackageScreen({super.key, required this.storeId});

  @override
  State<SubscriptionPackageScreen> createState() =>
      _SubscriptionPackageScreenState();
}

class _SubscriptionPackageScreenState
    extends State<SubscriptionPackageScreen> {
  // 3. HAPUS _isLoading DAN FUNGSI _handlePackageSelection
  // Kita tidak perlu loading di sini lagi

  @override
  Widget build(BuildContext context) {
    // Placeholder untuk harga
    final prices = {
      'bronze': 50000.0,
      'silver': 150000.0,
      'gold': 300000.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Paket Langganan"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      // 4. HAPUS STACK DAN LOADING OVERLAY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPackageCard(
              context: context,
              title: "🟫 Paket Bronze",
              price: prices['bronze']!,
              features: [
                "Input Produk Basic",
                "Penjualan Basic (Cash Only)",
                "Struk via Printer Bluetooth",
                "Manajemen Stok Sederhana",
                "Dashboard Laporan Harian",
                "1 User Login / 1 Outlet",
                "Support Chat Basic"
              ],
              packageName: 'bronze',
              // 5. UBAH FUNGSI ONSELECT
              onSelect: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentUploadScreen(
                      storeId: widget.storeId,
                      packageName: 'bronze',
                      price: prices['bronze']!,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPackageCard(
              context: context,
              title: "⚪ Paket Silver",
              price: prices['silver']!,
              features: [
                "Semua fitur Bronze",
                "Multi Payment (Cash, eWallet, Transfer)",
                "Diskon, Promo, & Voucher",
                "Multi User (3-5 user)",
                "Export Laporan (PDF/Excel)",
                "Laporan Mingguan & Bulanan",
                "Support Prioritas"
              ],
              packageName: 'silver',
              // 6. UBAH FUNGSI ONSELECT
              onSelect: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentUploadScreen(
                      storeId: widget.storeId,
                      packageName: 'silver',
                      price: prices['silver']!,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPackageCard(
              context: context,
              title: "🟨 Paket Gold",
              price: prices['gold']!,
              features: [
                "Semua fitur Silver",
                "Multi Outlet (Cabang)",
                "Manajemen Akses User Lengkap",
                "Manajemen Stok Advance",
                "Cloud Backup Harian",
                "Advanced Analytics",
                "Support VIP 24/7"
              ],
              packageName: 'gold',
              // 7. UBAH FUNGSI ONSELECT
              onSelect: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentUploadScreen(
                      storeId: widget.storeId,
                      packageName: 'gold',
                      price: prices['gold']!,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk membuat kartu paket
  Widget _buildPackageCard({
    required BuildContext context,
    required String title,
    required double price,
    required List<String> features,
    required String packageName,
    required VoidCallback onSelect,
  }) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: (title.contains("Silver") || title.contains("Gold"))
                ? primaryColor
                : Colors.grey.shade300,
            width: (title.contains("Silver") || title.contains("Gold")) ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "${formatCurrency.format(price)} / bulan",
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor),
            ),
            const Divider(height: 24),
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50, // 8. GUNAKAN ELEVATEDBUTTON STANDAR
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onSelect,
                child: Text("Pilih Paket $packageName",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}