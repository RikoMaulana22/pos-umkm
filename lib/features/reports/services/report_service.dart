// lib/features/reports/services/report_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erp_umkm/features/reports/models/transaction_model.dart';
import 'package:intl/intl.dart';
// Impor ini sudah benar
import '../../reports/models/transaction_item_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // FUNGSI INI SUDAH BENAR
  // ==========================================================
  Stream<List<TransactionModel>> getTransactions(String storeId,
      {String? cashierId}) {
    Query query = _firestore
        .collection('transactions')
        .where('storeId', isEqualTo: storeId);
    if (cashierId != null && cashierId.isNotEmpty) {
      query = query.where('cashierId', isEqualTo: cashierId);
    }

    // 4. Tambahkan pengurutan
    query = query.orderBy('timestamp', descending: true);
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromFirestore(doc);
      }).toList();
    });
  }

  // ==========================================================
  // PERBAIKAN: Ganti fungsi getDailySalesData dengan yang ini
  // ==========================================================
  Future<Map<String, Map<String, double>>> getDailySalesAndProfitData(
      String storeId, int days) async {
    // 1. Tentukan rentang waktu
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days - 1));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day));

    // 2. Siapkan Map untuk menampung hasil (sales dan profit)
    Map<String, Map<String, double>> dailyData = {};
    for (int i = 0; i < days; i++) {
      DateTime day = startDate.add(Duration(days: i));
      String formattedDate = DateFormat('dd/MM').format(day);
      // Inisialisasi sales dan profit dengan 0.0
      dailyData[formattedDate] = {'sales': 0.0, 'profit': 0.0};
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
      // Gunakan TransactionModel untuk mendapatkan helper totalProfit
      TransactionModel tx = TransactionModel.fromFirestore(doc);
      String formattedDate = DateFormat('dd/MM').format(tx.timestamp.toDate());

      // Tambahkan total penjualan DAN total profit ke hari yang sesuai
      if (dailyData.containsKey(formattedDate)) {
        dailyData[formattedDate]!['sales'] =
            (dailyData[formattedDate]!['sales'] ?? 0) + tx.totalPrice;

        dailyData[formattedDate]!['profit'] =
            (dailyData[formattedDate]!['profit'] ?? 0) + tx.totalProfit;
      }
    }

    return dailyData;
  }
}
