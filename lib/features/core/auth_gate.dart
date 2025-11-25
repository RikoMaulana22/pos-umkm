import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import screens
import '../auth/screens/login_or_register.dart';
import '../home/home_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../superadmin/screens/superadmin_dashboard.dart';
import 'screens/subscription_package_screen.dart'; // Pastikan path import ini benar
import '../settings/models/store_model.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. Cek Auth Firebase
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData) {
            return const LoginOrRegister();
          }

          final User currentUser = authSnapshot.data!;

          // 2. Stream Data User (Role & StoreID)
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                // User login di Auth tapi data di Firestore hilang? Logout kan.
                FirebaseAuth.instance.signOut();
                return const LoginOrRegister();
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'unknown';
              final String? storeId = userData['storeId'];

              // 3. Routing Berdasarkan Role
              if (role == 'superadmin') {
                return const SuperAdminDashboard();
              }

              // Jika role Admin/Kasir tapi tidak punya StoreID
              if ((role == 'admin' || role == 'kasir') && storeId == null) {
                return const Scaffold(
                  body: Center(
                      child:
                          Text("Error: Akun tidak terikat ke toko manapun.")),
                );
              }

              // 4. Stream Data Toko (Cek Expired)
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stores')
                    .doc(storeId)
                    .snapshots(),
                builder: (context, storeSnapshot) {
                  if (storeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                    return const Scaffold(
                      body: Center(
                          child: Text("Error: Data toko tidak ditemukan.")),
                    );
                  }

                  // Konversi ke StoreModel
                  StoreModel store;
                  try {
                    store = StoreModel.fromMap(
                      storeSnapshot.data!.data() as Map<String, dynamic>,
                      storeSnapshot.data!.id,
                    );
                  } catch (e) {
                    return Scaffold(
                      body: Center(child: Text("Error parsing data toko: $e")),
                    );
                  }

                  // 5. LOGIKA UTAMA: CEK MASA AKTIF
                  // Cek manual expiry date
                  bool isExpired = false;
                  if (store.subscriptionExpiry != null) {
                    isExpired =
                        store.subscriptionExpiry!.isBefore(DateTime.now());
                  }

                  // Jika Expired, arahkan ke layar langganan habis
                  if (isExpired) {
                    // PERBAIKAN: Sesuaikan argumen dengan definisi SubscriptionExpiredScreen
                    return SubscriptionExpiredScreen(
                      storeId: store.id,
                      userRole: role,
                    );
                  }

                  // Jika aktif, arahkan sesuai role dan kirim data yang diperlukan
                  if (role == 'admin') {
                    // PERBAIKAN: Kirim storeId dan subscriptionPackage ke HomeScreen
                    return HomeScreen(
                      storeId: store.id,
                      subscriptionPackage: store.subscriptionPackage ?? 'Free',
                    );
                  } else if (role == 'kasir') {
                    // PERBAIKAN: Kirim storeId dan subscriptionPackage ke PosScreen
                    return PosScreen(
                      storeId: store.id,
                      subscriptionPackage: store.subscriptionPackage ?? 'Free',
                    );
                  }
                  return const Center(child: Text("Role tidak dikenal."));
                },
              );
            },
          );
        },
      ),
    );
  }
}
