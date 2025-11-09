// lib/features/core/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/screens/login_or_register.dart';
import '../home/home_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../superadmin/screens/superadmin_dashboard.dart';
import 'subscription_expired_screen.dart';
// 1. IMPOR STORE MODEL
import '../settings/models/store_model.dart'; 

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. User belum login
          if (!authSnapshot.hasData) {
            return const LoginOrRegister();
          }

          // 2. User sudah login, cek rolenya di Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              // 3. Lagi loading data role
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              // 4. Gagal ambil data role

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                
                return const LoginOrRegister();
              }

              // 5. Data role ada, kita arahkan
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'unknown';
              final String? storeId = userData['storeId'];

              // 6. LOGIKA PERAN (ROLE)
              switch (role) {
                case 'superadmin':
                  return const SuperAdminDashboard();

                case 'admin':
                case 'kasir':
                  if (storeId == null) {
                    return const Scaffold(
                        body: Center(
                            child: Text("Error: Akun tidak terikat ke toko.")));
                  }

                  // 7. LOGIKA LANGGANAN (Subscription)
                  return StreamBuilder<StoreModel>( // Ubah ke StoreModel
                    stream: FirebaseFirestore.instance
                        .collection('stores')
                        .doc(storeId)
                        .snapshots()
                        .map((doc) => StoreModel.fromFirestore(doc)), // Konversi ke model
                    builder: (context, storeSnapshot) {
                      if (storeSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Scaffold(
                            body: Center(child: CircularProgressIndicator()));
                      }

                      if (!storeSnapshot.hasData) {
                        return const Scaffold(
                            body: Center(
                                child: Text("Error: Toko tidak ditemukan.")));
                      }

                      // 3. GUNAKAN MODEL.CANOPERATE
                      final store = storeSnapshot.data!;
                      
                      if (store.canOperate) { // <-- LOGIKA BARU DI SINI
                        // Jika toko aktif dan langganan valid
                        if (role == 'admin') {
                          return HomeScreen(storeId: storeId);
                        } else {
                          return PosScreen(storeId: storeId);
                        }
                      } else {
                        // Langganan Habis ATAU Toko di-suspend
                        return const SubscriptionExpiredScreen();
                      }
                    },
                  );

                default:
                  // Role tidak dikenal ('unknown')
                  return const LoginOrRegister();
              }
            },
          );
        },
      ),
    );
  }
}
