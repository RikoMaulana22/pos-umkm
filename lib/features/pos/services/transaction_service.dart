import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // --- 1. FUNGSI UNTUK KASIR (Create Transaksi) ---
  Future<String> processTransaction({
    required CartProvider cart,
    required String storeId,
    required String paymentMethod,
    double? cashReceived,
    double? change,
    required String customerName,
  }) async {
    if (_userId == null) throw Exception("User tidak login");

    WriteBatch batch = _firestore.batch();
    DocumentReference transactionDoc =
        _firestore.collection('transactions').doc();

    // Logika Hitung Hutang Awal
    double total = cart.totalPrice;
    double paid = 0;
    double debt = 0;
    String status = 'Lunas';

    if (paymentMethod == 'Hutang') {
      paid = 0;
      debt = total;
      status = 'Belum Lunas';
    } else if (paymentMethod == 'Split') {
      paid = cashReceived ?? 0;
      debt = total - paid;
      if (debt <= 0) {
        debt = 0;
        paid = total;
        status = 'Lunas';
      } else {
        status = 'Sebagian';
      }
    } else {
      paid = total;
      debt = 0;
      status = 'Lunas';
    }

    // Siapkan data item
    List<Map<String, dynamic>> itemsData = cart.items.entries.map((entry) {
      final item = entry.value;
      return {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.hargaJual,
        'cost': item.product.hargaModal,
      };
    }).toList();

    // Simpan Transaksi
    batch.set(transactionDoc, {
      'storeId': storeId,
      'cashierId': _userId,
      'totalPrice': total,
      'totalItems': cart.totalItems,
      'paymentMethod': paymentMethod,
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      // Field penting untuk tracking hutang
      'paid': paid,
      'debt': debt,
      'customerName': customerName,
      'paymentStatus': status,
    });

    // Simpan ke koleksi 'debts' jika ada hutang
    if (debt > 0) {
      DocumentReference debtDoc = _firestore.collection('debts').doc();
      batch.set(debtDoc, {
        'transactionId': transactionDoc.id,
        'customerName': customerName,
        'storeId': storeId,
        'originalTotal': total,
        'amountPaid': paid,
        'remainingAmount': debt,
        'status': status == 'Belum Lunas' ? 'unpaid' : 'partial',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    // Kurangi Stok
    for (var item in cart.items.values) {
      DocumentReference productDoc =
          _firestore.collection('products').doc(item.product.id);
      batch.update(productDoc, {
        'stok': FieldValue.increment(-item.quantity),
      });
    }

    try {
      await batch.commit();
      return transactionDoc.id;
    } catch (e) {
      throw Exception("Gagal memproses transaksi: ${e.toString()}");
    }
  }

  // --- 2. FUNGSI UNTUK BAYAR HUTANG (Yang Hilang Sebelumnya) ---
  Future<void> payDebt({
    required String debtId,
    required String transactionId,
    required double amountPay,
    required double currentPaid,
    required double totalDebt,
  }) async {
    WriteBatch batch = _firestore.batch();
    DocumentReference debtDoc = _firestore.collection('debts').doc(debtId);
    DocumentReference transactionDoc =
        _firestore.collection('transactions').doc(transactionId);

    // Hitung nilai baru
    double newPaid = currentPaid + amountPay;
    double newRemaining = totalDebt - newPaid;

    if (newRemaining < 0) newRemaining = 0;

    // Tentukan Status Baru
    String newStatusDebt = newRemaining <= 0 ? 'paid' : 'partial';
    String newStatusTrans = newRemaining <= 0 ? 'Lunas' : 'Sebagian';

    // Update Dokumen Hutang
    batch.update(debtDoc, {
      'amountPaid': newPaid,
      'remainingAmount': newRemaining,
      'status': newStatusDebt,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Update Dokumen Transaksi (agar laporan sinkron)
    batch.update(transactionDoc, {
      'paid': newPaid,
      'debt': newRemaining,
      'paymentStatus': newStatusTrans,
    });

    try {
      await batch.commit();
    } catch (e) {
      throw Exception("Gagal memproses pembayaran hutang: ${e.toString()}");
    }
  }
}
