import 'package:flutter/material.dart';
import '../services/inventory_service.dart'; //
import '../models/product_model.dart'; //

class InventoryScreen extends StatelessWidget {
  final String storeId; // 1. TERIMA storeId
  const InventoryScreen({super.key, required this.storeId}); // 2. Modifikasi constructor

  @override
  Widget build(BuildContext context) {
    // Buat instance service di dalam build (atau gunakan Provider)
    final InventoryService _inventoryService = InventoryService();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventaris (Produk)')),
      body: StreamBuilder<List<Product>>(
        // 3. KIRIM storeId ke service untuk filtering
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
                leading: CircleAvatar(
                  backgroundImage: (product.imageUrl != null)
                      ? NetworkImage(product.imageUrl!)
                      : null,
                  child: (product.imageUrl == null)
                      ? const Icon(Icons.inventory)
                      : null,
                ),
                title: Text(product.name),
                subtitle: Text("Stok: ${product.stok}"),
                trailing: Text("Rp ${product.hargaJual.toStringAsFixed(0)}"),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Nanti kita buat halaman 'AddProductScreen'
          // Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen(storeId: storeId)));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}