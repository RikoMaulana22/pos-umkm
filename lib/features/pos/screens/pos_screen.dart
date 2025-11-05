// lib/features/pos/screens/pos_screen.dart
import 'package:flutter/material.dart';
import '../../inventory/services/inventory_service.dart'; //
import '../../inventory/models/product_model.dart'; //
import '../../../shared/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PosScreen extends StatelessWidget {
  // 1. TAMBAHKAN INI: Terima storeId
  final String storeId;
  const PosScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final InventoryService _inventoryService = InventoryService();
    
    // Cek role user saat ini (untuk tombol logout)
    // Ini asumsi sederhana, idealnya pakai user data dari Firestore
    final bool isCashier = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir (Transaksi)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Jika yang login adalah Kasir, beri tombol logout
          if (isCashier)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () {
                FirebaseAuth.instance.signOut();
                // AuthGate akan otomatis menangani navigasi kembali ke Login
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        // 2. Gunakan storeId untuk mengambil produk yang TEPAT
        stream: _inventoryService.getProducts(storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("Toko ini belum memiliki produk."));
          }

          final products = snapshot.data!;

          // Tampilan Grid untuk Produk
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 kolom
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8, // Buat kartu sedikit lebih tinggi
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    // TODO: Tambahkan produk ke keranjang (Fitur selanjutnya)
                    print("${product.name} ditambahkan ke keranjang");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar Produk
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: (product.imageUrl != null)
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported,
                                  size: 50, color: Colors.grey),
                        ),
                      ),
                      // Info Produk
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rp ${product.hargaJual.toStringAsFixed(0)}",
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Stok: ${product.stok}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Nanti kita akan tambahkan BottomBar untuk total keranjang
      // bottomNavigationBar: ... 
    );
  }
}