import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/inventory_service.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../shared/theme.dart';
import 'category_screen.dart';
import 'stock_adjustment_screen.dart';

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
  final InventoryService inventoryService = InventoryService();
  final CategoryService _categoryService = CategoryService();
  String? _selectedCategoryId; // Untuk menyimpan filter yang aktif

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris (Produk)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: "Penyesuaian Stok",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StockAdjustmentScreen(storeId: widget.storeId),
                ),
              );
            },
          ),
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
      // 4. UBAH BODY MENJADI COLUMN
      body: Column(
        children: [
          // 5. TAMBAHKAN WIDGET FILTER KATEGORI DI SINI
          _buildCategoryFilter(),
          const Divider(height: 1, thickness: 1),

          // 6. BUNGKUS STREAMBUILDER DENGAN EXPANDED
          Expanded(
            child: StreamBuilder<List<Product>>(
              // 7. HUBUNGKAN STREAM DENGAN FILTER
              stream: inventoryService.getProducts(widget.storeId,
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
                      // 8. BUAT PESAN LEBIH KONTEKSTUAL
                      _selectedCategoryId != null
                          ? "Tidak ada produk di kategori ini."
                          : "Belum ada produk.\nTekan tombol + untuk menambah produk.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
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
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // setelah menambah produk, refresh otomatis karena pakai StreamBuilder
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(storeId: widget.storeId),
            ),
          );
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 9. TAMBAHKAN WIDGET BUILDER UNTUK FILTER (COPY DARI POS_SCREEN)
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

  // 10. TAMBAHKAN WIDGET BUILDER UNTUK CHIP (COPY DARI POS_SCREEN)
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
