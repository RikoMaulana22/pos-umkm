import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Mengambil detail toko
  Future<StoreModel> getStoreDetails(String storeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('stores').doc(storeId).get();

      if (!doc.exists) {
        throw Exception("Toko tidak ditemukan");
      }

      // PERBAIKAN: Gunakan fromMap dan casting data dengan aman
      return StoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception("Gagal mengambil data toko: ${e.toString()}");
    }
  }

  // 2. Update nama toko
  Future<void> updateStoreName(String storeId, String newName) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'name': newName,
      });
    } catch (e) {
      throw Exception("Gagal update nama toko: ${e.toString()}");
    }
  }

  Future<void> updateBankDetails(
      String storeId, String bank, String number, String holder) async {
    await _firestore.collection('stores').doc(storeId).update({
      'bankName': bank,
      'accountNumber': number,
      'accountHolder': holder,
    });
  }

  // 3. Update Pengaturan Printer
  Future<void> updatePrinterSettings({
    required String storeId,
    required String printerName,
    required String printerAddress, // MAC Address untuk Bluetooth atau IP
    int paperSize = 58, // Default 58mm, opsi lain 80mm
  }) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'printerSettings': {
          'name': printerName,
          'address': printerAddress,
          'paperSize': paperSize,
        }
      });
    } catch (e) {
      throw Exception("Gagal menyimpan pengaturan printer: ${e.toString()}");
    }
  }

  Future<void> updateStoreSettings({
    required String storeId,
    required String name,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    await _firestore.collection('stores').doc(storeId).update({
      'name': name,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    });
  }

  // 4. Update Pengaturan Pajak
  Future<void> updateTaxSettings({
    required String storeId,
    required double taxRate, // Contoh: 11.0 untuk 11%
    required bool isTaxEnabled,
  }) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'taxSettings': {
          'rate': taxRate,
          'enabled': isTaxEnabled,
        }
      });
    } catch (e) {
      throw Exception("Gagal menyimpan pengaturan pajak: ${e.toString()}");
    }
  }
}
