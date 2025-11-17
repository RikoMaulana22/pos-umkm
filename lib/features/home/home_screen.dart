// lib/features/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/theme.dart';
import 'widgets/dashboard_button.dart';
import '../../shared/widgets/curved_header_clipper.dart';

// Impor semua halaman
import '../pos/screens/pos_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../reports/screens/report_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../admin/screens/manage_cashier_screen.dart';
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

  String _getPackageName() {
    switch (subscriptionPackage.toLowerCase()) {
      case 'gold':
        return '✨ Paket Gold';
      case 'silver':
        return '⭐ Paket Silver';
      case 'bronze':
        return '🥉 Paket Bronze';
      default:
        return '📦 Free';
    }
  }

  Color _getPackageColor() {
    switch (subscriptionPackage.toLowerCase()) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey[400]!;
      case 'bronze':
        return Colors.brown[300]!;
      default:
        return Colors.blue[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSilverOrGold =
        subscriptionPackage == 'silver' || subscriptionPackage == 'gold';
    final bool isAdmin = true;

    // Get user info
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ✨ Header dengan Gradient & Info User
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Title & Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang, 👋',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi Logout'),
                                  content: const Text(
                                      'Apakah Anda yakin ingin keluar?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        signOut();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.logout, size: 24),
                            color: Colors.white,
                            tooltip: "Logout",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Package Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPackageColor(),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getPackageColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _getPackageName(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✨ Konten dengan Better Spacing
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Low Stock Alert (jika ada)
                  if (isSilverOrGold) ...[
                    LowStockAlertWidget(
                      storeId: storeId,
                      lowStockThreshold: 5,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Section Title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✨ Grid Menu dengan Improved Design
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Transaksi Kasir
                      _buildModernMenuCard(
                        context: context,
                        label: "Transaksi",
                        subtitle: "Kasir & Pembayaran",
                        icon: Icons.point_of_sale_rounded,
                        color: Colors.blue,
                        onTap: () => _goTo(
                          context,
                          PosScreen(
                            storeId: storeId,
                            subscriptionPackage: subscriptionPackage,
                          ),
                        ),
                      ),

                      // Inventaris
                      _buildModernMenuCard(
                        context: context,
                        label: "Inventaris",
                        subtitle: "Kelola Produk",
                        icon: Icons.inventory_2_rounded,
                        color: Colors.green,
                        onTap: () => _goTo(
                          context,
                          InventoryScreen(storeId: storeId),
                        ),
                      ),

                      // Laporan
                      _buildModernMenuCard(
                        context: context,
                        label: "Laporan",
                        subtitle: "Analisis Penjualan",
                        icon: Icons.bar_chart_rounded,
                        color: Colors.orange,
                        onTap: () => _goTo(
                          context,
                          ReportScreen(
                            storeId: storeId,
                            subscriptionPackage: subscriptionPackage,
                          ),
                        ),
                      ),

                      // Pengaturan (Admin only)
                      if (isAdmin)
                        _buildModernMenuCard(
                          context: context,
                          label: "Pengaturan",
                          subtitle: "Konfigurasi Toko",
                          icon: Icons.settings_rounded,
                          color: Colors.purple,
                          onTap: () => _goTo(
                            context,
                            SettingsScreen(storeId: storeId),
                          ),
                        ),

                      // Manajemen Kasir (Silver/Gold + Admin)
                      if (isSilverOrGold && isAdmin)
                        _buildModernMenuCard(
                          context: context,
                          label: "Manajemen Kasir",
                          subtitle: "Kelola Staff",
                          icon: Icons.people_rounded,
                          color: Colors.teal,
                          badge: isSilverOrGold ? 'Premium' : null,
                          onTap: () => _goTo(
                            context,
                            ManageCashierScreen(
                              storeId: storeId,
                              subscriptionPackage: subscriptionPackage,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ✨ Footer Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'POS UMKM v1.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2025 All Rights Reserved',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Custom Modern Menu Card
  Widget _buildModernMenuCard({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Background Circle Decoration
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 32,
                      ),
                    ),

                    // Text Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge (Premium)
              if (badge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
