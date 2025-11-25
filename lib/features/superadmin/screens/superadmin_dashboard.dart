import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Pastikan import ini sesuai dengan struktur folder Anda
import '../../../shared/theme.dart';
import '../../settings/models/store_model.dart';
import '../services/superadmin_service.dart';
import '../models/upgrade_request_model.dart'; // Model asli

// Screen Imports
import 'add_store_screen.dart';
import 'edit_store_screen.dart';
import 'superadmin_revenue_screen.dart';
import 'upgrade_requests_screen.dart' as request_screen; // ✅ Pake alias
import 'complaints_screen.dart';
import 'manage_packages_screen.dart';
import 'manage_payment_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final SuperAdminService _service = SuperAdminService();
  final Color superAdminColor = const Color(0xFFC62828);

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('👑 Super Admin'),
        backgroundColor: superAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 🔔 Badge permintaan upgrade
          StreamBuilder<List<UpgradeRequestModel>>(
            stream: _service.getUpgradeRequests(),
            builder: (context, snapshot) {
              final int requestCount =
                  (snapshot.hasData && snapshot.data != null)
                      ? snapshot.data!.length
                      : 0;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Badge(
                    label: Text(
                      '$requestCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    isLabelVisible: requestCount > 0,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  tooltip: "Permintaan Upgrade ($requestCount)",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // ✅ Panggil Class dengan prefix "request_screen."
                        builder: (context) =>
                            request_screen.UpgradeRequestsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // ... (Sisa kode tombol Revenue & Logout sama seperti sebelumnya)
          // 💰 Revenue Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuperAdminRevenueScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.monetization_on_rounded),
              tooltip: "Laporan Penghasilan",
            ),
          ),

          // 🚪 Logout Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: "Logout",
              onPressed: signOut,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderSection(),
          // ... (Sisa body dashboard sama seperti kode Anda sebelumnya)
          // 👇 MENU KELOLA (Fitur Baru)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'Kelola Paket',
                    icon: Icons.card_membership_rounded,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManagePackagesScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'Metode Bayar',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManagePaymentScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                // 📋 Daftar Toko
                Expanded(
                  child: StreamBuilder<List<StoreModel>>(
                    stream: _service.getAllStores(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child:
                              CircularProgressIndicator(color: superAdminColor),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Belum Ada Toko'));
                      }
                      final stores = snapshot.data!;
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: stores.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          return _buildStoreCard(store);
                        },
                      );
                    },
                  ),
                ),
                // 📢 Tombol Pengaduan
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.campaign_rounded,
                          color: Colors.white),
                      label: const Text(
                        "Pengaduan Customer",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ComplaintsScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ... (Floating Action Button sama)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddStoreScreen(),
            ),
          );
        },
        backgroundColor: superAdminColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Toko Baru'),
      ),
    );
  }

  // ... (Helper Widgets: _buildHeaderSection, _buildMenuCard, _buildStatCard, _buildStoreCard, _buildDetailItem, _formatDate sama persis seperti kode Anda sebelumnya)

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [superAdminColor, superAdminColor.withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard Super Admin',
              style: TextStyle(color: Colors.white)),
          const Text('Kelola Semua Toko',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          StreamBuilder<List<StoreModel>>(
              stream: _service.getAllStores(),
              builder: (context, snapshot) {
                // Statistik sederhana untuk demo
                return Row(children: [
                  _buildStatCard(
                      icon: Icons.store,
                      label: 'Total',
                      value: '${snapshot.data?.length ?? 0}',
                      color: Colors.white),
                ]);
              })
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
        onTap: onTap,
        child: Card(
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                    children: [Icon(icon, color: color), Text(title)]))));
  }

  Widget _buildStatCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Expanded(
        child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Icon(icon, color: color),
              Text(value, style: TextStyle(color: Colors.white)),
              Text(label, style: TextStyle(color: Colors.white70))
            ])));
  }

  Widget _buildStoreCard(StoreModel store) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(store.name[0])),
        title: Text(store.name),
        subtitle: Text(store.ownerId),
        trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditStoreScreen(store: store)));
            }),
      ),
    );
  }
}
