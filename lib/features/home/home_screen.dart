// lib/features/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import 'widgets/dashboard_button.dart';
import '../../shared/widgets/curved_header_clipper.dart'; // <-- IMPOR CLIPPER KITA
import '../pos/screens/pos_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../reports/screens/report_screen.dart';
import '../settings/screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    return Scaffold(
      body: Column(
        children: [
          // ===========================================
          // HEADER KUSTOM BARU DENGAN DUA LAPISAN
          // ===========================================
          Container(
            // Bungkus ClipPath dalam Container untuk memberi tinggi tetap
            height: 150, // Sesuaikan tinggi sesuai keinginan
            width: double.infinity,
            child: Stack(
              children: [
                // LAPISAN BAWAH (lebih terang, sedikit ke kiri dan atas)
                Positioned(
                  // Geser sedikit ke kiri dan atas
                  left: -95,
                  top: -15,
                  child: ClipPath(
                    clipper: CurvedHeaderClipper(),
                    child: Container(
                      height: 165, // Sedikit lebih tinggi dari lapisan atas
                      width: MediaQuery.of(context).size.width +
                          100, // Sedikit lebih lebar
                      color: const Color.fromARGB(255, 64, 204, 102).withOpacity(
                          0.7), // Warna yang lebih terang atau berbeda
                    ),
                  ),
                ),
                // LAPISAN ATAS (warna utama)
                ClipPath(
                  clipper: CurvedHeaderClipper(),
                  child: Container(
                    height: 550, // Tinggi yang sama dengan Container pembungkus
                    width: double.infinity,
                    color: const Color.fromARGB(255, 42, 161, 144), // Warna utama
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

          // ===========================================
          // KONTEN HALAMAN (GRID MENU)
          // ===========================================
          Expanded(
            child: Stack(
              children: [
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      DashboardButton(
                        label: "Transaksi (Kasir)",
                        icon: Icons.point_of_sale,
                        onTap: () => _goTo(context, const PosScreen()),
                      ),
                      DashboardButton(
                        label: "Produk (Inventaris)",
                        icon: Icons.inventory_2,
                        onTap: () => _goTo(context, const InventoryScreen()),
                      ),
                      DashboardButton(
                        label: "Laporan",
                        icon: Icons.bar_chart,
                        onTap: () => _goTo(context, const ReportScreen()),
                      ),
                      DashboardButton(
                        label: "Pengaturan",
                        icon: Icons.settings,
                        onTap: () => _goTo(context, const SettingsScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
