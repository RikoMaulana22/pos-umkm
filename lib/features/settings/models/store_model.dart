// lib/features/settings/models/store_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String ownerId;

  StoreModel({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? 'Nama Toko Tidak Ditemukan',
      ownerId: data['ownerId'] ?? '',
    );
  }
}