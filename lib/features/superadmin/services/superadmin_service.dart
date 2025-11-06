// lib/features/superadmin/services/superadmin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. Tambahkan impor ini
import 'package:firebase_core/firebase_core.dart'; // <-- 2. Tambahkan impor ini
import '../../settings/models/store_model.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // 3. Tambahkan properti auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk mengambil semua toko (sudah ada)
  Stream<List<StoreModel>> getAllStores() {
    return _firestore
        .collection('stores')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .toList();
    });
  }

  // ==========================================================
  // 4. FUNGSI BARU: Super Admin membuat Toko & Admin baru
  // ==========================================================
  Future<void> createStoreWithAdmin({
    required String adminEmail,
    required String adminPassword,
    required String adminUsername,
    required String storeName,
    required DateTime expiryDate, // Terima tanggal kedaluwarsa
    required double subscriptionPrice,
  }) async {
    try {
      // Trik untuk mendaftar user baru tanpa me-logout Super Admin
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempApp-${DateTime.now().millisecondsSinceEpoch}', // Nama unik
        options: Firebase.app().options, // Gunakan opsi yang sama
      );

      // 1. Buat user (Admin) baru di Firebase Auth menggunakan instance tempApp
      UserCredential userCredential =
          await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      
      // Hapus app sementara
      await tempApp.delete();

      // 2. Buat Toko baru di koleksi 'stores'
      DocumentReference storeDoc = await _firestore.collection('stores').add({
        'name': storeName,
        'ownerId': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'subscriptionExpiry': Timestamp.fromDate(expiryDate), // <-- SET LANGGANAN
        'subscriptionPrice': subscriptionPrice,
      });

      // 3. Simpan data user (Admin) di koleksi 'users'
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': adminEmail,
        'username': adminUsername,
        'role': 'admin',
        'storeId': storeDoc.id,
      });
    } on FirebaseAuthException catch (e) {
      throw Exception("Gagal membuat user Auth: ${e.message}");
    } catch (e) {
      throw Exception("Gagal membuat toko: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> getRevenueData() async {
  double totalRevenue = 0.0;
  int activeSubscriptions = 0;
  int expiredSubscriptions = 0;

  QuerySnapshot storeSnapshot = await _firestore.collection('stores').get();

  for (var doc in storeSnapshot.docs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Tambahkan ke total penghasilan (asumsi harga sewa adalah per pendaftaran)
    totalRevenue += (data['subscriptionPrice'] ?? 0.0).toDouble();

    // Cek status langganan
    final Timestamp? expiry = data['subscriptionExpiry'];
    if (expiry != null && expiry.toDate().isAfter(DateTime.now())) {
      activeSubscriptions++;
    } else {
      expiredSubscriptions++;
    }
  }

  return {
    'totalRevenue': totalRevenue,
    'totalStores': storeSnapshot.size,
    'activeSubscriptions': activeSubscriptions,
    'expiredSubscriptions': expiredSubscriptions,
  };
}

  Future<void> updateStoreSubscription({
    required String storeId,
    required DateTime newExpiryDate,
    required double newPrice, // Kita tambahkan harga
  }) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'subscriptionExpiry': Timestamp.fromDate(newExpiryDate),
        'subscriptionPrice': newPrice, // Simpan harga
      });
    } catch (e) {
      throw Exception("Gagal update langganan: ${e.toString()}");
    }
  }

  Future<void> deleteStore(String storeId, String ownerId) async {
    // INI ADALAH OPERASI BERBAHAYA DAN KOMPLEKS
    // Idealnya, ini harus dijalankan oleh Cloud Function untuk menghapus
    // semua produk, transaksi, dan user (kasir) yang terkait.

    // Untuk saat ini, kita hanya hapus data user admin dan data tokonya.
    try {
      // 1. Hapus dokumen toko
      await _firestore.collection('stores').doc(storeId).delete();

      // 2. Hapus dokumen user admin
      await _firestore.collection('users').doc(ownerId).delete();

      // 3. Hapus user admin dari Authentication
      // PERINGATAN: Ini tidak bisa dilakukan dari aplikasi klien
      // Ini harus dilakukan oleh Cloud Function.
      // Kita akan skip langkah ini untuk sekarang.

    } catch (e) {
      throw Exception("Gagal menghapus toko: ${e.toString()}");
    }
  }
}