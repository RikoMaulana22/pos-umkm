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
import '../models/product_variant_model.dart';

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

  // --- Kontroler Produk Simpel ---
  final TextEditingController modalController = TextEditingController();
  final TextEditingController jualController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController diskonController = TextEditingController();
  final TextEditingController skuController = TextEditingController();

  // --- Controller Varian ---
  final List<TextEditingController> _variantNameCtrls = [];
  final List<TextEditingController> _variantModalCtrls = [];
  final List<TextEditingController> _variantJualCtrls = [];
  final List<TextEditingController> _variantStokCtrls = [];

  bool _isVariantProduct = false;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  String? _selectedCategoryId;
  late Stream<List<Category>> _categoryStream;
  List<Category> _cachedCategories = [];

  @override
  void initState() {
    super.initState();
    _categoryStream = _categoryService.getCategories(widget.storeId);
    _addNewVariantRow();
  }

  @override
  void dispose() {
    nameController.dispose();
    modalController.dispose();
    jualController.dispose();
    stokController.dispose();
    diskonController.dispose();
    skuController.dispose();

    for (var i = 0; i < _variantNameCtrls.length; i++) {
      _variantNameCtrls[i].dispose();
      _variantModalCtrls[i].dispose();
      _variantJualCtrls[i].dispose();
      _variantStokCtrls[i].dispose();
    }
    super.dispose();
  }

  void _addNewVariantRow() {
    setState(() {
      _variantNameCtrls.add(TextEditingController());
      _variantModalCtrls.add(TextEditingController());
      _variantJualCtrls.add(TextEditingController());
      _variantStokCtrls.add(TextEditingController());
    });
  }

  void _removeVariantRow(int index) {
    setState(() {
      _variantNameCtrls[index].dispose();
      _variantModalCtrls[index].dispose();
      _variantJualCtrls[index].dispose();
      _variantStokCtrls[index].dispose();

      _variantNameCtrls.removeAt(index);
      _variantModalCtrls.removeAt(index);
      _variantJualCtrls.removeAt(index);
      _variantStokCtrls.removeAt(index);
    });
  }

  // ✅ PERBAIKAN: Tambah progress indicator yang lebih baik
  Future<void> _saveProduct() async {
    // Validasi dasar
    if (nameController.text.isEmpty || _selectedCategoryId == null) {
      _showError("Nama produk dan Kategori harus diisi");
      return;
    }

    final selectedCategoryObject = _cachedCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => throw Exception("Kategori tidak ditemukan"),
    );

    setState(() {
      _isLoading = true;
    });

    // ✅ Tampilkan progress snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _imageBytes != null
                      ? 'Mengupload gambar ke server...'
                      : 'Menyimpan produk...',
                ),
              ),
            ],
          ),
          duration: const Duration(minutes: 2), // Timeout panjang
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      if (_isVariantProduct) {
        // === LOGIKA SIMPAN PRODUK BERVARIAN ===
        List<ProductVariant> variantsList = [];

        if (_variantNameCtrls.isEmpty) {
          throw Exception("Produk bervarian harus memiliki minimal 1 varian.");
        }

        for (int i = 0; i < _variantNameCtrls.length; i++) {
          final String name = _variantNameCtrls[i].text.trim();
          final double modal = double.tryParse(
                  _variantModalCtrls[i].text.replaceAll(',', '.')) ??
              0;
          final double jual =
              double.tryParse(_variantJualCtrls[i].text.replaceAll(',', '.')) ??
                  0;
          final int stok = int.tryParse(_variantStokCtrls[i].text) ?? 0;

          if (name.isEmpty || jual <= 0) {
            throw Exception(
                "Varian ke-${i + 1}: Nama Varian dan Harga Jual harus diisi.");
          }

          variantsList.add(ProductVariant(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            hargaModal: modal,
            hargaJual: jual,
            stok: stok,
          ));
        }

        print('📦 Menyimpan produk bervarian: ${nameController.text}');
        print('📦 Jumlah varian: ${variantsList.length}');
        print(
            '🖼️ Ada gambar: ${_imageBytes != null ? "Ya (${(_imageBytes!.length / 1024).toStringAsFixed(2)} KB)" : "Tidak"}');

        await _inventoryService.addProduct(
          name: nameController.text.trim(),
          storeId: widget.storeId,
          categoryId: selectedCategoryObject.id!,
          categoryName: selectedCategoryObject.name,
          imageBytes: _imageBytes,
          imageName: _imageName,
          isVariantProduct: true,
          variants: variantsList,
        );
      } else {
        // === LOGIKA SIMPAN PRODUK SIMPEL ===
        if (modalController.text.isEmpty ||
            jualController.text.isEmpty ||
            stokController.text.isEmpty) {
          throw Exception("Harga Modal, Harga Jual, dan Stok harus diisi.");
        }

        final hargaModal =
            double.tryParse(modalController.text.replaceAll(',', '.'));
        final hargaJual =
            double.tryParse(jualController.text.replaceAll(',', '.'));
        final stok = int.tryParse(stokController.text);
        final hargaDiskon = diskonController.text.isEmpty
            ? null
            : double.tryParse(diskonController.text.replaceAll(',', '.'));
        final sku =
            skuController.text.isEmpty ? null : skuController.text.trim();

        if (hargaModal == null || hargaJual == null || stok == null) {
          throw const FormatException("Format angka tidak valid.");
        }

        print('📦 Menyimpan produk simpel: ${nameController.text}');
        print('💰 Harga: Modal=$hargaModal, Jual=$hargaJual');
        print('📊 Stok: $stok');
        print(
            '🖼️ Ada gambar: ${_imageBytes != null ? "Ya (${(_imageBytes!.length / 1024).toStringAsFixed(2)} KB)" : "Tidak"}');

        await _inventoryService.addProduct(
          name: nameController.text.trim(),
          storeId: widget.storeId,
          categoryId: selectedCategoryObject.id!,
          categoryName: selectedCategoryObject.name,
          imageBytes: _imageBytes,
          imageName: _imageName,
          isVariantProduct: false,
          hargaModal: hargaModal,
          hargaJual: hargaJual,
          stok: stok,
          hargaDiskon: hargaDiskon,
          sku: sku,
        );
      }

      if (!mounted) return;

      // ✅ Hapus progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // ✅ Tampilkan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Produk berhasil ditambahkan!"),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print('✅ Produk berhasil disimpan');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error simpan produk: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      _showError("Gagal menyimpan: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: nameController,
                  hintText: "Nama Produk (Cth: Nasi Goreng)",
                ),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 24),
                ImagePickerWidget(
                  onImagePicked: (imageBytes, fileName) {
                    setState(() {
                      _imageBytes = imageBytes;
                      _imageName = fileName;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  "Tipe Produk",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                ToggleButtons(
                  isSelected: [
                    _isVariantProduct == false,
                    _isVariantProduct == true
                  ],
                  onPressed: (index) {
                    setState(() {
                      _isVariantProduct = index == 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  color: primaryColor,
                  constraints: BoxConstraints(
                      minWidth:
                          (MediaQuery.of(context).size.width - 48 - 6) / 2,
                      minHeight: 40),
                  children: const [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Produk Simpel",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Produk Bervarian",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isVariantProduct)
                  _buildVariantForm()
                else
                  _buildSimpleForm(),

                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _saveProduct,
                  text: _isLoading ? "Menyimpan..." : "Simpan Produk",
                ),
                const SizedBox(height: 24), // Extra padding bottom
              ],
            ),
          ),
          // ✅ Loading overlay dengan message
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _imageBytes != null
                          ? 'Mengupload gambar...\nMohon tunggu'
                          : 'Menyimpan produk...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Category>>(
      stream: _categoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          _cachedCategories = [];
          return const Center(
            child: Text(
              "Belum ada kategori. Silakan tambah di menu Inventaris.",
              textAlign: TextAlign.center,
            ),
          );
        }
        _cachedCategories = snapshot.data!;
        if (_selectedCategoryId != null &&
            !_cachedCategories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          hint: const Text("Pilih Kategori"),
          isExpanded: true,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            fillColor: Colors.grey.shade100,
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          ),
          items: _cachedCategories.map((Category category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategoryId = newValue;
            });
          },
          validator: (value) => value == null ? 'Kategori harus diisi' : null,
        );
      },
    );
  }

  Widget _buildSimpleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Harga & Stok (Produk Simpel)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: modalController,
          hintText: "Harga Modal (Beli)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: jualController,
          hintText: "Harga Jual",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: diskonController,
          hintText: "Harga Diskon (Opsional)",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        CustomTextField(
          controller: skuController,
          hintText: "SKU / Barcode (Opsional)",
        ),
      ],
    );
  }

  Widget _buildVariantForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Varian Produk",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "Tambahkan varian seperti Ukuran (S, M, L) atau Rasa (Pedas, Original).",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(
            _variantNameCtrls.length,
            (index) => _buildVariantInputRow(index),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          icon: const Icon(Icons.add, color: primaryColor),
          label: const Text(
            "Tambah Varian",
            style: TextStyle(color: primaryColor),
          ),
          onPressed: _addNewVariantRow,
        ),
      ],
    );
  }

  Widget _buildVariantInputRow(int index) {
    final numberFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
    ];
    final digitsFormatter = [
      FilteringTextInputFormatter.digitsOnly,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _variantNameCtrls[index],
                    decoration: const InputDecoration(
                      labelText: "Nama Varian (Cth: Besar)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                  onPressed: () {
                    if (_variantNameCtrls.length > 1) {
                      _removeVariantRow(index);
                    } else {
                      _showError("Minimal harus ada 1 varian");
                    }
                  },
                  tooltip: "Hapus varian",
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _variantModalCtrls[index],
                    decoration: const InputDecoration(
                      labelText: "H. Modal",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: numberFormatter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _variantJualCtrls[index],
                    decoration: const InputDecoration(
                      labelText: "H. Jual",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: numberFormatter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _variantStokCtrls[index],
                    decoration: const InputDecoration(
                      labelText: "Stok",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsFormatter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
