// lib/features/inventory/screens/category_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  final String storeId;
  const CategoryScreen({super.key, required this.storeId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _categoryController = TextEditingController();

  // ===========================================
  // FUNGSI DIALOG TAMBAH (Sudah Bagus)
  // ===========================================
  void _showAddCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) {
        bool isAdding = false; // State untuk loading di dalam dialog
        return StatefulBuilder(
          // Gunakan ini agar dialog bisa update state
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Kategori Baru"),
              content: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(hintText: "Nama Kategori"),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          if (_categoryController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Nama kategori tidak boleh kosong"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isAdding = true;
                          });

                          try {
                            await _categoryService.addCategory(
                              _categoryController.text.trim(),
                              widget.storeId,
                            );

                            if (!mounted) return;
                            Navigator.pop(
                                context); // Tutup dialog jika berhasil
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text("Gagal menyimpan: ${e.toString()}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isAdding = false;
                              });
                            }
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================
  // FUNGSI DIALOG HAPUS BARU (Perbaikan)
  // ===========================================
  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Kategori"),
          content: Text(
              "Anda yakin ingin menghapus kategori '${category.name}'?\n\nPERINGATAN: Produk yang menggunakan kategori ini tidak akan terhapus, tetapi kategorinya akan kosong."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _categoryService.deleteCategory(category.id!);

                  if (!mounted) return;
                  Navigator.pop(context); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("Kategori '${category.name}' berhasil dihapus."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Category>>(
        stream: _categoryService.getCategories(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              "Belum ada kategori.\nTekan tombol + untuk menambah.",
              textAlign: TextAlign.center,
            ));
          }

          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  // ===========================================
                  // PERBAIKI ONPRESSED DI SINI
                  // ===========================================
                  onPressed: () {
                    _showDeleteCategoryDialog(category);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: "Tambah Kategori",
      ),
    );
  }
}
