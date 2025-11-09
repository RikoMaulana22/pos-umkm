// lib/features/inventory/screens/add_product_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/inventory_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../widgets/image_picker_widget.dart';
import '../../../shared/theme.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class AddProductScreen extends StatefulWidget {
  final String storeId;
  const AddProductScreen({super.key, required this.storeId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final InventoryService _inventoryService = InventoryService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController modalController = TextEditingController();
  final TextEditingController jualController = TextEditingController();
  final TextEditingController stokController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  // ===========================================
  // PERBAIKAN 1: Ubah tipe state
  // ===========================================
  String? _selectedCategoryId; // Simpan ID-nya saja, bukan objek

  // ===========================================
  // PERBAIKAN 2: Buat variabel untuk stream & cache
  // ===========================================
  late Stream<List<Category>> _categoryStream;
  List<Category> _cachedCategories = []; // Cache untuk mencari nama

  @override
  void initState() {
    super.initState();
    // ===========================================
    // PERBAIKAN 3: Panggil stream hanya satu kali di initState
    // ===========================================
    _categoryStream = _categoryService.getCategories(widget.storeId);
  }

  Future<void> _saveProduct() async {
    // Validasi dasar (sudah benar)
    if (nameController.text.isEmpty ||
        modalController.text.isEmpty ||
        jualController.text.isEmpty ||
        stokController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Nama, harga, dan stok harus diisi"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // ===========================================
    // PERBAIKAN 4: Validasi _selectedCategoryId (String)
    // ===========================================
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Kategori harus dipilih"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parsing angka (sudah benar)
      final hargaModal =
          double.tryParse(modalController.text.replaceAll(',', '.'));
      final hargaJual =
          double.tryParse(jualController.text.replaceAll(',', '.'));
      final stok = int.tryParse(stokController.text);

      if (hargaModal == null || hargaJual == null || stok == null) {
        throw const FormatException(
            "Format angka tidak valid. Gunakan angka saja.");
      }

      // ===========================================
      // PERBAIKAN 5: Cari objek kategori dari cache
      // ===========================================
      final selectedCategoryObject = _cachedCategories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => throw Exception("Kategori tidak ditemukan"),
      );

      // Panggil service dengan data kategori (sudah benar)
      await _inventoryService.addProduct(
        name: nameController.text.trim(),
        hargaModal: hargaModal,
        hargaJual: hargaJual,
        stok: stok,
        imageBytes: _imageBytes,
        imageName: _imageName,
        storeId: widget.storeId,
        categoryId: selectedCategoryObject.id!, // Kirim ID
        categoryName: selectedCategoryObject.name, // Kirim Nama
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Produk berhasil ditambahkan!"),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.message}"),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Gagal menambah produk: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Produk Baru"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CustomTextField(
                  controller: nameController,
                  hintText: "Nama Produk",
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: modalController,
                  hintText: "Harga Modal (Beli)",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: jualController,
                  hintText: "Harga Jual",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: stokController,
                  hintText: "Stok Awal",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),

                const SizedBox(height: 16),

                // ===========================================
                // PERBAIKAN 6: Gunakan _categoryStream
                // ===========================================
                StreamBuilder<List<Category>>(
                  stream: _categoryStream, // Gunakan stream dari initState
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data == null || snapshot.data!.isEmpty) {
                      _cachedCategories = []; // Kosongkan cache
                      return const Center(
                        child: Text(
                          "Belum ada kategori. Silakan tambah di menu Inventaris.",
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // Simpan data ke cache
                    _cachedCategories = snapshot.data!;

                    // Validasi
                    if (_selectedCategoryId != null &&
                        !_cachedCategories
                            .any((c) => c.id == _selectedCategoryId)) {
                      _selectedCategoryId = null;
                    }

                    // ===========================================
                    // PERBAIKAN 7: Ubah Dropdown ke <String>
                    // ===========================================
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId, // value adalah String?
                      hint: const Text("Pilih Kategori"),
                      isExpanded: true,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 16.0),
                      ),
                      items: _cachedCategories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.id, // value adalah String ID
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // newValue adalah String?
                        setState(() {
                          _selectedCategoryId = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Kategori harus diisi' : null,
                    );
                  },
                ),

                const SizedBox(height: 24),
                ImagePickerWidget(
                  onImagePicked: (imageBytes, fileName) {
                    setState(() {
                      _imageBytes = imageBytes;
                      _imageName = fileName;
                    });
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _saveProduct,
                  text: _isLoading ? "Menyimpan..." : "Simpan Produk",
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
