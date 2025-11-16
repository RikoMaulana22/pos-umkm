// lib/features/home/widgets/low_stock_alert_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../inventory/models/product_model.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../shared/theme.dart';
// Impor ini untuk menavigasi ke halaman edit produk
import '../../inventory/screens/edit_product_screen.dart'; 

class LowStockAlertWidget extends StatelessWidget {
  final String storeId;
  final int lowStockThreshold; // Kita set batas stok (misal: 5)

  LowStockAlertWidget({
    super.key,
    required this.storeId,
    this.lowStockThreshold = 5, // Default stok menipis adalah 5
  });

  final InventoryService _inventoryService = InventoryService();
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      // Kita gunakan stream produk yang sudah ada
      stream: _inventoryService.getProducts(storeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Jangan tampilkan apa-apa saat loading
          return const SizedBox.shrink(); 
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error memuat stok: ${snapshot.error}"));
        }

        final allProducts = snapshot.data!;
        
        // --- INI LOGIKA PENTINGNYA ---
        // Kita filter untuk menemukan produk/varian yang stoknya menipis
        final List<Map<String, dynamic>> lowStockItems = [];

        for (var product in allProducts) {
          if (product.isVariantProduct) {
            // Cek setiap varian
            for (var variant in product.variants) {
              if (variant.stok > 0 && variant.stok <= lowStockThreshold) {
                lowStockItems.add({
                  'product': product,
                  'name': "${product.name} - ${variant.name}",
                  'stok': variant.stok,
                });
              }
            }
          } else {
            // Cek produk simpel
            if (product.stok > 0 && product.stok <= lowStockThreshold) {
              lowStockItems.add({
                'product': product,
                'name': product.name,
                'stok': product.stok,
              });
            }
          }
        }
        // --- AKHIR LOGIKA ---

        // Jika tidak ada stok menipis, jangan tampilkan apa-apa
        if (lowStockItems.isEmpty) {
          return const SizedBox.shrink();
        }

        // Jika ada, tampilkan widget peringatan
        return Container(
          margin: const EdgeInsets.only(bottom: 16), // Hapus margin horizontal
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Text(
                    "Stok Segera Habis!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Terdapat ${lowStockItems.length} item yang stoknya di bawah $lowStockThreshold. Segera lakukan restock.",
                style: TextStyle(color: Colors.orange[700]),
              ),
              const Divider(height: 20),
              
              // Tampilkan 3 item teratas
              ...lowStockItems.take(3).map((item) {
                final product = item['product'] as Product;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    "Sisa: ${item['stok']}",
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // Arahkan langsung ke halaman edit produk
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProductScreen(
                          product: product,
                          storeId: storeId,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}