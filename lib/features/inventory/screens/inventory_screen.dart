import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/inventory_service.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../shared/theme.dart';
import 'category_screen.dart';

class InventoryScreen extends StatelessWidget {
  final String storeId;
  const InventoryScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final InventoryService inventoryService = InventoryService();
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris (Produk)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        // ===========================================
        // KODE YANG DITAMBAHKAN (BLOK actions)
        // ===========================================
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: "Manajemen Kategori",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(storeId: storeId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: inventoryService.getProducts(storeId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Terjadi kesalahan: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // No data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada produk.\nTekan tombol + untuk menambah produk.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Data ada
          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProductScreen(product: product),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (product.imageUrl != null &&
                            product.imageUrl!.isNotEmpty)
                        ? NetworkImage(product.imageUrl!)
                        : null,
                    child: (product.imageUrl == null ||
                            product.imageUrl!.isEmpty)
                        ? const Icon(Icons.inventory, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  // ===========================================
                  // KODE YANG DIPERBARUI (SUBTITLE)
                  // ===========================================
                  subtitle: Text(
                    "Kategori: ${product.categoryName ?? 'N/A'}\n"
                    "Stok: ${product.stok} | Modal: ${formatCurrency.format(product.hargaModal)}",
                  ),
                  trailing: Text(
                    formatCurrency.format(product.hargaJual),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // setelah menambah produk, refresh otomatis karena pakai StreamBuilder
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(storeId: storeId),
            ),
          );
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
