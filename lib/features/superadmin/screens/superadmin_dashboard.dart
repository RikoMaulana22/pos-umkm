// lib/features/superadmin/screens/superadmin_dashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../../settings/models/store_model.dart';
import '../services/superadmin_service.dart';
import 'add_store_screen.dart';
import 'edit_store_screen.dart';
import 'superadmin_revenue_screen.dart';
import '../models/upgrade_request_model.dart';
import 'upgrade_requests_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final SuperAdminService _service = SuperAdminService();
  final Color superAdminColor = Colors.red[800]!;

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
          // ✨ Notification Button dengan Badge
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Badge(
                    label: Text('$requestCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        )),
                    isLabelVisible: requestCount > 0,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  tooltip: "Permintaan Upgrade ($requestCount)",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpgradeRequestsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ✨ Revenue Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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

          // ✨ Logout Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
          // ✨ Header Section
          _buildHeaderSection(),

          // ✨ Store List
          Expanded(
            child: StreamBuilder<List<StoreModel>>(
              stream: _service.getAllStores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: superAdminColor),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat toko...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 80, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi Kesalahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined,
                            size: 100, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Toko',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan tombol + untuk menambah toko pertama',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
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
        ],
      ),
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
        tooltip: "Tambah Toko Baru",
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            superAdminColor,
            superAdminColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Super Admin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kelola Semua Toko',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✨ Stats Row
          StreamBuilder<List<StoreModel>>(
            stream: _service.getAllStores(),
            builder: (context, snapshot) {
              final int totalStores =
                  (snapshot.hasData) ? snapshot.data!.length : 0;
              final int goldStores = (snapshot.hasData)
                  ? snapshot.data!
                      .where((s) => s.subscriptionPackage == 'gold')
                      .length
                  : 0;
              final int silverStores = (snapshot.hasData)
                  ? snapshot.data!
                      .where((s) => s.subscriptionPackage == 'silver')
                      .length
                  : 0;

              return Row(
                children: [
                  _buildStatCard(
                    icon: Icons.store_rounded,
                    label: 'Total Toko',
                    value: '$totalStores',
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.star_rounded,
                    label: 'Gold',
                    value: '$goldStores',
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.star_outline_rounded,
                    label: 'Silver',
                    value: '$silverStores',
                    color: Colors.grey[300]!,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    // Determine package color
    Color packageColor;
    String packageLabel;
    IconData packageIcon;

    switch (store.subscriptionPackage.toLowerCase()) {
      case 'gold':
        packageColor = Colors.amber;
        packageLabel = 'Gold';
        packageIcon = Icons.star_rounded;
        break;
      case 'silver':
        packageColor = Colors.grey[400]!;
        packageLabel = 'Silver';
        packageIcon = Icons.star_outline_rounded;
        break;
      case 'bronze':
        packageColor = Colors.brown[400]!;
        packageLabel = 'Bronze';
        packageIcon = Icons.star_outline_rounded;
        break;
      default:
        packageColor = Colors.blue[300]!;
        packageLabel = 'Free';
        packageIcon = Icons.check_circle_outline_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditStoreScreen(store: store),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✨ Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          superAdminColor,
                          superAdminColor.withOpacity(0.7)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        store.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${store.ownerId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Package Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: packageColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: packageColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(packageIcon, color: packageColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          packageLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: packageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ✨ Details Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.location_on_rounded,
                      label: 'Lokasi',
                      value: 'N/A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Dibuat',
                      value: _formatDate(DateTime
                          .timestamp()), // TODO: replace with actual StoreModel date field when available
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ✨ Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStoreScreen(store: store),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: superAdminColor.withOpacity(0.1),
                    foregroundColor: superAdminColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
