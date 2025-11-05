// lib/features/pos/screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format Rupiah
import 'package:provider/provider.dart'; // Impor Provider
import '../../inventory/services/inventory_service.dart';
import '../../inventory/models/product_model.dart';
import '../../../shared/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart'; // Impor CartProvider
import 'payment_screen.dart';
// import '../screens/payment_screen.dart'; // Nanti kita buat ini

class PosScreen extends StatelessWidget {
  final String storeId;
  const PosScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final InventoryService _inventoryService = InventoryService();

    final bool isCashier = FirebaseAuth.instance.currentUser != null;

    // Format Rupiah
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir (Transaksi)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isCashier)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Daftar Produk (Mengisi sisa ruang)
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _inventoryService.getProducts(storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error.toString()}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Toko ini belum memiliki produk."));
                }

                final products = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          // PANGGIL FUNGSI ADD ITEM DARI PROVIDER
                          if (product.stok > 0) {
                            Provider.of<CartProvider>(context, listen: false)
                                .addItem(product);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${product.name} ditambahkan"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Stok produk habis"),
                                duration: Duration(seconds: 1),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: (product.imageUrl != null)
                                    ? Image.network(product.imageUrl!,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrency.format(product.hargaJual),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Stok: ${product.stok}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
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
          ),

          // ==========================================================
          // BAGIAN BARU: Total Keranjang (sesuai Figma)
          // ==========================================================
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              // Jangan tampilkan jika keranjang kosong
              if (cart.items.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Harga
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${cart.totalItems} Item",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        Text(
                          formatCurrency.format(cart.totalPrice),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    // Tombol Bayar
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Navigasi ke Halaman Bayar (Layar 6)
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                      storeId: storeId,
                                    )));
                      },
                      child: const Text(
                        "BAYAR",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
