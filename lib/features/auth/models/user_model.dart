// lib/features/auth/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String role;
  final String storeId;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    required this.storeId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      role: data['role'] ?? '',
      storeId: data['storeId'] ?? '',
    );
  }
}