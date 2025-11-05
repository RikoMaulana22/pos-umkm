// lib/features/reports/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erp_umkm/features/reports/models/transaction_model.dart';
import 'package:intl/intl.dart'; // <-- 1. TAMBAHKAN IMPOR INI

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // 2. FUNGSI UNTUK DAFTAR RIWAYAT (Sudah ada)
  // ==========================================================
  Stream<List<TransactionModel>> getTransactions(String storeId) {
    return _firestore
        .collection('transactions')
        .where('storeId', isEqualTo: storeId) // Filter berdasarkan ID toko
        .orderBy('timestamp', descending: true) // Tampilkan yang terbaru di atas
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    });
  }

  // ==========================================================
  // 3. FUNGSI BARU: Mengambil data untuk GRAFIK (Dari kode Anda)
  // ==========================================================
  Future<Map<String, double>> getDailySalesData(String storeId, int days) async {
    // 1. Tentukan rentang waktu
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days - 1));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day));

    // 2. Siapkan Map untuk menampung hasil
    // Kita inisialisasi dengan 0 untuk setiap hari
    Map<String, double> dailySales = {};
    for (int i = 0; i < days; i++) {
      DateTime day = startDate.add(Duration(days: i));
      String formattedDate = DateFormat('dd/MM').format(day);
      dailySales[formattedDate] = 0.0;
    }

    // 3. Ambil data transaksi dari Firestore
    var querySnapshot = await _firestore
        .collection('transactions')
        .where('storeId', isEqualTo: storeId)
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .orderBy('timestamp', descending: true)
        .get();

    // 4. Kelompokkan (agregat) data di sisi klien (Dart)
    for (var doc in querySnapshot.docs) {
      TransactionModel tx = TransactionModel.fromFirestore(doc);
      String formattedDate = DateFormat('dd/MM').format(tx.timestamp.toDate());
      
      // Tambahkan total penjualan ke hari yang sesuai
      if (dailySales.containsKey(formattedDate)) {
        dailySales[formattedDate] = dailySales[formattedDate]! + tx.totalPrice;
      }
    }

    return dailySales;
  }
}