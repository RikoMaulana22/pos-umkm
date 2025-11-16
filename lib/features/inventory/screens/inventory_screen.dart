// lib/features/inventory/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/inventory_service.dart';
import '../../../shared/theme.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'category_screen.dart';
import 'stock_adjustment_screen.dart';
import 'package:intl/intl.dart';

// 1. IMPOR BARU UNTUK KATEGORI
import '../models/category_model.dart';
import '../services/category_service.dart';

// 2. UBAH MENJADI STATEFULWIDGET
class InventoryScreen extends StatefulWidget {
  final String storeId;
  const InventoryScreen({super.key, required this.storeId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // 3. TAMBAHKAN STATE DAN SERVICE YANG DIPERLUKAN
  final InventoryService _inventoryService = InventoryService();
  final CategoryService _categoryService = CategoryService();
  String? _selectedCategoryId; // Untuk menyimpan filter yang aktif

  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris (Produk)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: "Manajemen Kategori",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(storeId: widget.storeId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 4. TAMBAHKAN WIDGET FILTER KATEGORI
          _buildCategoryFilter(),
          const Divider(height: 1, thickness: 1),

          // 5. BUNGKUS STREAMBUILDER DENGAN EXPANDED
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _inventoryService.getProducts(widget.storeId,
                  categoryId: _selectedCategoryId),
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
                  return Center(
                    child: Text(
                      _selectedCategoryId != null
                          ? "Tidak ada produk di kategori ini."
                          : "Belum ada produk.\nTekan tombol + untuk menambah produk.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Data ada
                final products = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      bottom: 160), // Beri ruang untuk FAB
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: (product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(product.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (product.imageUrl == null ||
                                  product.imageUrl!.isEmpty)
                              ? const Icon(Icons.inventory_2,
                                  color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kategori: ${product.categoryName ?? 'N/A'}",
                            ),
                            if (product.isVariantProduct)
                              Text(
                                "Stok: ${product.totalStok} (Bervarian)",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )
                            else
                              Text(
                                "Stok: ${product.totalStok} | Jual: ${formatCurrency.format(product.hargaJualFinal)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.edit, color: Colors.grey),

                        // ===================================
                        // PERBAIKAN ERROR ADA DI SINI
                        // ===================================
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProductScreen(
                                product: product,
                                storeId: widget.storeId, // <-- TAMBAHKAN INI
                              ),
                            ),
                          );
                        },
                        // ===================================
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 6. KEMBALIKAN MULTI FAB
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddProductScreen(storeId: widget.storeId),
                ),
              );
            },
            heroTag: 'addProduct',
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            tooltip: "Tambah Produk",
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StockAdjustmentScreen(storeId: widget.storeId),
                ),
              );
            },
            heroTag: 'adjustStock',
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.compare_arrows),
            label: const Text("Penyesuaian Stok"),
          ),
        ],
      ),
    );
  }

  // 7. TAMBAHKAN WIDGET BUILDER UNTUK FILTER
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: StreamBuilder<List<Category>>(
        stream: _categoryService.getCategories(widget.storeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text("Memuat kategori..."));
          }

          var categories = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length + 1, // +1 untuk tombol "Semua"
            itemBuilder: (context, index) {
              if (index == 0) {
                // Tombol "Semua"
                return _buildCategoryChip(
                  label: "Semua",
                  isSelected: _selectedCategoryId == null,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                );
              }

              final category = categories[index - 1];
              return _buildCategoryChip(
                label: category.name,
                isSelected: _selectedCategoryId == category.id,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  // 8. TAMBAHKAN WIDGET BUILDER UNTUK CHIP
  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : primaryColor,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: isSelected ? primaryColor : Colors.white,
        side: BorderSide(color: isSelected ? primaryColor : Colors.grey[300]!),
        onPressed: onTap,
      ),
    );
  }
}
