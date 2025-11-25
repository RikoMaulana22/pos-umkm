import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class PackageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get all active packages (or all packages for management)
  Stream<List<PackageModel>> getPackages() {
    return _firestore
        .collection('packages')
        .orderBy('price', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PackageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Future to add a package
  Future<void> addPackage(PackageModel package) async {
    await _firestore.collection('packages').add(package.toMap());
  }

  // Update package data (Partial update)
  // Metode ini diperlukan untuk fitur Edit dan Switch Active/Inactive
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _firestore.collection('packages').doc(id).update(data);
  }

  // Initialize default packages (Tombol Refresh/Restore)
  // Metode ini diperlukan untuk mengisi data awal jika kosong
  Future<void> initializeDefaultPackages() async {
    final snapshot = await _firestore.collection('packages').get();
    if (snapshot.docs.isNotEmpty) return; // Jangan timpa jika sudah ada data

    final defaults = [
      PackageModel(
          id: '',
          name: 'Bronze',
          price: 50000,
          durationDays: 30,
          features: ['Laporan Dasar', '1 Kasir'],
          isActive: true),
      PackageModel(
          id: '',
          name: 'Silver',
          price: 100000,
          durationDays: 30,
          features: ['Laporan Lengkap', '3 Kasir', 'Backup Harian'],
          isActive: true),
      PackageModel(
          id: '',
          name: 'Gold',
          price: 150000,
          durationDays: 30,
          features: [
            'Unlimited Kasir',
            'Prioritas Support',
            'Laporan Analitik'
          ],
          isActive: true),
    ];

    for (var p in defaults) {
      await _firestore.collection('packages').add(p.toMap());
    }
  }
}
