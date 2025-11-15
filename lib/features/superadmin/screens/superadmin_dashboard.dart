// lib/features/superadmin/screens/superadmin_dashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../../settings/models/store_model.dart';
import '../services/superadmin_service.dart';
import 'add_store_screen.dart';
import 'edit_store_screen.dart';
import 'superadmin_revenue_screen.dart';

// 1. IMPOR DUA FILE BARU
import '../models/upgrade_request_model.dart';
import 'upgrade_requests_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final SuperAdminService _service = SuperAdminService();

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final Color superAdminColor = Colors.red[800]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: superAdminColor,
        foregroundColor: Colors.white,
        actions: [
          // 2. TOMBOL NOTIFIKASI UPGRADE (DENGAN BADGE)
          StreamBuilder<List<UpgradeRequestModel>>(
            stream: _service.getUpgradeRequests(),
            builder: (context, snapshot) {
              final int requestCount =
                  (snapshot.hasData && snapshot.data != null)
                      ? snapshot.data!.length
                      : 0;
              
              return IconButton(
                icon: Badge(
                  label: Text('$requestCount'),
                  isLabelVisible: requestCount > 0,
                  child: const Icon(Icons.notifications),
                ),
                tooltip: "Permintaan Upgrade",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpgradeRequestsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuperAdminRevenueScreen(),
                ),
              );
            },
            icon: const Icon(Icons.monetization_on),
            tooltip: "Laporan Penghasilan",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: signOut,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Manajemen Toko",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          // Daftar semua toko
          Expanded(
            child: StreamBuilder<List<StoreModel>>(
              stream: _service.getAllStores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error.toString()}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Belum ada toko yang terdaftar."));
                }

                final stores = snapshot.data!;
                return ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          child: Text(store.name[0].toUpperCase()), // Inisial
                        ),
                        title: Text(store.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Paket: ${store.subscriptionPackage} / Owner ID: ${store.ownerId}"), // Tampilkan info paket
                        trailing: const Icon(Icons.edit, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditStoreScreen(store: store),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Buka halaman AddStoreScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStoreScreen()),
          );
        },
        backgroundColor: superAdminColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_business),
        tooltip: "Tambah Toko Baru",
      ),
    );
  }
}