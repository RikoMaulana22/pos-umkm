import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Impor semua halaman
import '../pos/screens/pos_screen.dart';
import '../inventory/screens/inventory_screen.dart';
import '../reports/screens/report_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../admin/screens/manage_cashier_screen.dart';

// -----------------------------------------------------------------------------------------------------------------
// HomeScreen Design Modern
// -----------------------------------------------------------------------------------------------------------------
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
          // --------------------- Modern Header ---------------------
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1765CB),
                  Color(0xFF2351A2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 15,
                    offset: Offset(0, 6)),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Profile
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.10),
                            blurRadius: 18,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        backgroundImage: NetworkImage(
                          user?.photoURL ??
                              'https://ui-avatars.com/api/?name=$userName&background=1765CB&color=fff',
                        ),
                        radius: 23,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Welcome text and package badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Selamat Datang",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.95)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPackageColor(),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: _getPackageColor().withOpacity(0.18),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              _getPackageName(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Logout button, more minimal
                    Material(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(13),
                      child: IconButton(
                        icon: const Icon(Icons.logout,
                            color: Colors.white, size: 21),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Logout'),
                              content:
                                  const Text('Apakah Anda yakin ingin keluar?'),
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
                                  child: const Text('Logout'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: "Logout",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --------------------- Main Content ---------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFF1765CB),
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

                  // Grid Menu Modern
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
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

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'EZZEN v1.0.0.1',
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------- Modern Card Menu ---------------------
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
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.09),
                color.withOpacity(0.14),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.09),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.03),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(7),
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
