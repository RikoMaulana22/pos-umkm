// lib/features/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import 'widgets/dashboard_button.dart';
import '../../shared/widgets/curved_header_clipper.dart';

// Impor semua halaman yang akan dituju
import '../pos/screens/pos_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../reports/screens/report_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../admin/screens/manage_cashier_screen.dart';
// 1. IMPOR WIDGET BARU
import 'widgets/low_stock_alert_widget.dart';

class HomeScreen extends StatelessWidget {
  final String storeId;
  final String subscriptionPackage;
  const HomeScreen({
    super.key,
    required this.storeId,
    required this.subscriptionPackage,
  });

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  void _goTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSilverOrGold =
        subscriptionPackage == 'silver' || subscriptionPackage == 'gold';

    return Scaffold(
      body: Column(
        children: [
          // Header Kustom (Tidak berubah)
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  left: -10,
                  top: -10,
                  child: ClipPath(
                    clipper: CurvedHeaderClipper(),
                    child: Container(
                      height: 160,
                      width: MediaQuery.of(context).size.width + 20,
                      color: primaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
                ClipPath(
                  clipper: CurvedHeaderClipper(),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: primaryColor,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: signOut,
                              icon: const Icon(Icons.logout, size: 28),
                              color: Colors.white,
                              tooltip: "Logout",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten Halaman (Grid Menu)
          Expanded(
            child: Stack(
              children: [
                // (Dekorasi background tidak berubah)
                Positioned(
                  bottom: -80,
                  right: -80,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(150),
                      ),
                    ),
                  ),
                ),

                // 2. UBAH Padding MENJADI ListView
                ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 3. TAMPILKAN WIDGET STOK JIKA SILVER/GOLD
                    if (isSilverOrGold)
                      LowStockAlertWidget(
                          storeId: storeId, lowStockThreshold: 5),

                    // 4. GridView sekarang di dalam ListView
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      shrinkWrap: true, // Wajib di dalam ListView
                      physics:
                          const NeverScrollableScrollPhysics(), // Wajib di dalam ListView
                      children: [
                        DashboardButton(
                          label: "Transaksi (Kasir)",
                          icon: Icons.point_of_sale,
                          onTap: () => _goTo(
                              context,
                              PosScreen(
                                  storeId: storeId,
                                  subscriptionPackage: subscriptionPackage)),
                        ),
                        DashboardButton(
                          label: "Produk (Inventaris)",
                          icon: Icons.inventory_2,
                          onTap: () =>
                              _goTo(context, InventoryScreen(storeId: storeId)),
                        ),
                        DashboardButton(
                          label: "Laporan",
                          icon: Icons.bar_chart,
                          onTap: () => _goTo(
                              context,
                              ReportScreen(
                                  storeId: storeId,
                                  subscriptionPackage: subscriptionPackage)),
                        ),
                        DashboardButton(
                          label: "Pengaturan",
                          icon: Icons.settings,
                          onTap: () =>
                              _goTo(context, SettingsScreen(storeId: storeId)),
                        ),
                        if (isSilverOrGold)
                          DashboardButton(
                            label: "Manajemen Kasir",
                            icon: Icons.person_add,
                            onTap: () {
                              _goTo(context,
                                  ManageCashierScreen(storeId: storeId));
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
