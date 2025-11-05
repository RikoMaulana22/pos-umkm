// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // 1. FUNGSI SIGN IN (LOGIN)
  // ==========================================================
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik Firebase
      throw Exception(e.message);
    } catch (e) {
      // Menangkap error umum lainnya (misal: tidak ada internet)
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // 2. FUNGSI SIGN UP (REGISTER) UNTUK ADMIN (PEMILIK TOKO)
  // ==========================================================
  Future<UserCredential> signUpAdmin({
    required String email,
    required String password,
    required String username,
    required String storeName,
  }) async {
    try {
      // 1. Buat user baru di Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. BUAT TOKO BARU di koleksi 'stores'
      DocumentReference storeDoc = await _firestore.collection('stores').add({
        'name': storeName,
        'ownerId': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Simpan data user (sebagai 'admin')
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'role': 'admin',
        'storeId': storeDoc.id,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik Firebase
      throw Exception(e.message);
    } catch (e) {
      // Menangkap error umum lainnya
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // 3. FUNGSI BUAT KASIR BARU (Dipanggil oleh Admin)
  // ==========================================================
  Future<void> createCashier({
    required String email,
    required String password,
    required String username,
    required String storeId,
  }) async {
    try {
      // (Komentar tentang batasan SDK klien tetap berlaku)
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data kasir di Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'role': 'kasir',
        'storeId': storeId,
      });
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik Firebase
      throw Exception(e.message);
    } catch (e) {
      // Menangkap error umum lainnya
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // 4. FUNGSI SIGN OUT (LOGOUT)
  // ==========================================================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      // Menangkap error spesifik Firebase
      throw Exception(e.message);
    } catch (e) {
      // PERBAIKAN DI SINI:
      // Mengganti e.message (yang tidak ada) menjadi e.toString()
      throw Exception(e.toString());
    }
  }
}
