// lib/features/inventory/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/inventory_service.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart'; // <-- 1. IMPOR HALAMAN EDIT
import '../../../shared/theme.dart';

class InventoryScreen extends StatelessWidget {
  final String storeId;
  const InventoryScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final InventoryService _inventoryService = InventoryService();
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris (Produk)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Product>>(
        stream: _inventoryService.getProducts(storeId), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada produk."));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen(product: product),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: (product.imageUrl != null)
                      ? NetworkImage(product.imageUrl!)
                      : null,
                  child: (product.imageUrl == null)
                      ? const Icon(Icons.inventory)
                      : null,
                ),
                title: Text(product.name),
                subtitle: Text("Stok: ${product.stok} | Modal: ${formatCurrency.format(product.hargaModal)}"),
                trailing: Text(
                  formatCurrency.format(product.hargaJual),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(storeId: storeId),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}