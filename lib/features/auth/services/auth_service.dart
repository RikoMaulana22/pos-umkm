// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- 1. IMPOR INI

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // 1. FUNGSI SIGN IN (LOGIN) - (Tidak berubah)
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
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // 2. FUNGSI SIGN UP (REGISTER) - (DIHAPUS)
  // ==========================================================
  // Fungsi 'signUpAdmin' sudah kita pindahkan ke SuperAdminService
  // jadi kita hapus dari sini agar kode bersih.

  // ==========================================================
  // 3. FUNGSI BUAT KASIR BARU (DIPERBAIKI)
  // ==========================================================
  Future<void> createCashier({
    required String email,
    required String password,
    required String username,
    required String storeId,
  }) async {
    try {
      // 2. Buat instance Firebase sementara untuk mendaftarkan user baru
      // Ini adalah trik agar Admin tidak logout
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempApp-${DateTime.now().millisecondsSinceEpoch}', // Nama unik
        options: Firebase.app().options, // Gunakan opsi yang sama
      );

      // 3. Buat user baru menggunakan instance 'tempApp'
      UserCredential userCredential =
          await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Hapus instance 'tempApp' setelah selesai
      await tempApp.delete();

      // 5. Simpan data kasir di Firestore (menggunakan instance utama)
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
  // 4. FUNGSI SIGN OUT (LOGOUT) - (Tidak berubah)
  // ==========================================================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
