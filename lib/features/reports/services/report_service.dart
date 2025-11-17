import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erp_umkm/features/reports/models/transaction_model.dart';
import 'package:intl/intl.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================
  // MIGRATION: Jalankan sekali untuk menambahkan field cashierId ke transaksi lama
  // ==========================================================
  Future<void> migrateOldTransactions(String storeId) async {
    try {
      print('🔄 Memulai migrasi transaksi untuk storeId: $storeId');

      // Ambil semua transaksi dari store ini
      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('storeId', isEqualTo: storeId)
          .get();

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Cek apakah dokumen tidak memiliki field cashierId
        if (!data.containsKey('cashierId')) {
          batch.update(doc.reference, {
            'cashierId': null, // Set ke null untuk transaksi lama
          });
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        print('✅ Migrasi selesai: $count transaksi diupdate');
      } else {
        print('✅ Tidak ada transaksi yang perlu dimigrasi');
      }
    } catch (e) {
      print('❌ Error migrasi: $e');
      rethrow;
    }
  }

  // ==========================================================
  // Stream transaksi dengan filter cashierId dan days
  // ==========================================================
  Stream<List<TransactionModel>> getTransactions(
    String storeId, {
    String? cashierId,
    int? days,
  }) {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('storeId', isEqualTo: storeId);

      // Filter berdasarkan cashierId jika diberikan
      if (cashierId != null && cashierId.isNotEmpty) {
        query = query.where('cashierId', isEqualTo: cashierId);
      }

      // Filter berdasarkan tanggal jika days diberikan
      if (days != null) {
        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.subtract(Duration(days: days - 1));
        Timestamp startTimestamp = Timestamp.fromDate(
          DateTime(startDate.year, startDate.month, startDate.day),
        );
        query =
            query.where('timestamp', isGreaterThanOrEqualTo: startTimestamp);
      }

      return query.orderBy('timestamp', descending: true).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .toList(),
          );
    } catch (e) {
      print('❌ Error getTransactions: $e');
      rethrow;
    }
  }

  // ==========================================================
  // Data grafik dengan filter cashierId yang benar
  // ==========================================================
  Future<Map<String, Map<String, double>>> getDailySalesAndProfitData(
    String storeId,
    int days, {
    String? cashierId,
  }) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days - 1));
      Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day),
      );

      // Inisialisasi data untuk semua hari
      Map<String, Map<String, double>> dailyData = {};
      for (int i = 0; i < days; i++) {
        DateTime day = startDate.add(Duration(days: i));
        String formattedDate = DateFormat('dd/MM').format(day);
        dailyData[formattedDate] = {'sales': 0.0, 'profit': 0.0};
      }

      // Build query dengan filter yang sama seperti getTransactions
      Query query = _firestore
          .collection('transactions')
          .where('storeId', isEqualTo: storeId)
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp);

      // PENTING: Filter cashierId harus sama dengan getTransactions
      if (cashierId != null && cashierId.isNotEmpty) {
        query = query.where('cashierId', isEqualTo: cashierId);
      }

      QuerySnapshot querySnapshot =
          await query.orderBy('timestamp', descending: true).get();

      // Agregasi data transaksi
      for (var doc in querySnapshot.docs) {
        TransactionModel tx = TransactionModel.fromFirestore(doc);
        String formattedDate =
            DateFormat('dd/MM').format(tx.timestamp.toDate());

        if (dailyData.containsKey(formattedDate)) {
          dailyData[formattedDate]!['sales'] =
              (dailyData[formattedDate]!['sales'] ?? 0) + tx.totalPrice;

          dailyData[formattedDate]!['profit'] =
              (dailyData[formattedDate]!['profit'] ?? 0) + tx.totalProfit;
        }
      }

      print(
          '✅ getDailySalesAndProfitData: ${querySnapshot.docs.length} transaksi ditemukan untuk filter cashierId=$cashierId, days=$days');
      return dailyData;
    } catch (e) {
      print('❌ Error getDailySalesAndProfitData: $e');
      return {};
    }
  }
}
