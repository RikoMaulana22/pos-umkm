import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> addProduct({
    required String name,
    required double hargaModal,
    required double hargaJual,
    required int stok,
    required Uint8List imageBytes,
    required String imageName,
    required String storeId,
  }) async {
    if (_userId == null) throw Exception("User tidak login");

    try {
      String fileExtension = imageName.split('.').last;
      String fileName =
          'products/$storeId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      UploadTask uploadTask = _storage.ref().child(fileName).putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      Product product = Product(
        name: name,
        hargaModal: hargaModal,
        hargaJual: hargaJual,
        stok: stok,
        imageUrl: downloadUrl,
        createdBy: _userId!,
      );

      Map<String, dynamic> productData = product.toMap();
      productData['storeId'] = storeId;

      await _firestore.collection('products').add(productData);
    } on FirebaseException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Gagal menambah produk: ${e.toString()}");
    }
  }

  Stream<List<Product>> getProducts(String storeId) {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection('products')
        .where('storeId', isEqualTo: storeId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateProduct({
    required Product product,
    Uint8List? newImageBytes,
    String? newImageName,
  }) async {
    if (product.id == null) throw Exception("ID Produk tidak valid");
    if (_userId == null) throw Exception("User tidak login");

    try {
      String? newImageUrl = product.imageUrl;

      if (newImageBytes != null && newImageName != null) {
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          try {
            await _storage.refFromURL(product.imageUrl!).delete();
          } catch (e) {
            print("Gagal hapus gambar lama: $e");
          }
        }

        String fileExtension = newImageName.split('.').last;
        String fileName =
            'products/${product.createdBy}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        UploadTask uploadTask =
            _storage.ref().child(fileName).putData(newImageBytes);
        TaskSnapshot snapshot = await uploadTask;
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      Map<String, dynamic> updatedData = {
        'name': product.name,
        'hargaModal': product.hargaModal,
        'hargaJual': product.hargaJual,
        'stok': product.stok,
        'imageUrl': newImageUrl,
      };

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updatedData);
    } on FirebaseException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Gagal update produk: ${e.toString()}");
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (_userId == null) throw Exception("User tidak login");

    try {
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) throw Exception("Produk tidak ditemukan");

      String? imageUrl = (doc.data() as Map<String, dynamic>)['imageUrl'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print("Gagal hapus gambar dari storage: $e");
        }
      }

      await _firestore.collection('products').doc(productId).delete();
    } on FirebaseException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Gagal menghapus produk: ${e.toString()}");
    }
  }
}