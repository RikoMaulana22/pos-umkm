// lib/features/inventory/screens/edit_product_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart'; // Model utama
import '../services/inventory_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../widgets/image_picker_widget.dart';
import '../../../shared/theme.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../models/product_variant_model.dart'; // 1. IMPOR MODEL VARIAN

class EditProductScreen extends StatefulWidget {
  final Product product; // Produk yang akan diedit
  // ===================================
  // PERBAIKAN ERROR ADA DI SINI (Constructor)
  // ===================================
  final String storeId; // 2. TAMBAHKAN storeId

  const EditProductScreen({
    super.key,
    required this.product,
    required this.storeId, // 3. WAJIBKAN storeId
  });
  // ===================================

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final InventoryService _inventoryService = InventoryService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController nameController = TextEditingController();

  // --- Kontroler Produk Simpel ---
  final TextEditingController modalController = TextEditingController();
  final TextEditingController jualController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController diskonController = TextEditingController();
  final TextEditingController skuController = TextEditingController();

  // --- Kontroler Produk Varian ---
  final List<TextEditingController> _variantNameCtrls = [];
  final List<TextEditingController> _variantModalCtrls = [];
  final List<TextEditingController> _variantJualCtrls = [];
  final List<TextEditingController> _variantStokCtrls = [];

  late bool _isVariantProduct;

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  String? _selectedCategoryId;
  late Stream<List<Category>> _categoryStream;
  List<Category> _cachedCategories = []; // Inisialisasi kosong
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();

    // 4. PERBAIKAN: Gunakan widget.storeId
    _categoryStream = _categoryService.getCategories(widget.storeId);

    // ISI FORM DENGAN DATA PRODUK YANG ADA
    nameController.text = widget.product.name;
    _selectedCategoryId = widget.product.categoryId;
    _isVariantProduct = widget.product.isVariantProduct;
    _existingImageUrl = widget.product.imageUrl;

    if (_isVariantProduct) {
      // Isi form varian
      if (widget.product.variants.isEmpty) {
        _addNewVariantRow();
      } else {
        for (var variant in widget.product.variants) {
          _variantNameCtrls.add(TextEditingController(text: variant.name));
          _variantModalCtrls
              .add(TextEditingController(text: variant.hargaModal.toString()));
          _variantJualCtrls
              .add(TextEditingController(text: variant.hargaJual.toString()));
          _variantStokCtrls
              .add(TextEditingController(text: variant.stok.toString()));
        }
      }
    } else {
      // Isi form simpel
      modalController.text = widget.product.hargaModal.toString();
      jualController.text = widget.product.hargaJual.toString();
      stokController.text = widget.product.stok.toString();
      diskonController.text = widget.product.hargaDiskon?.toString() ?? '';
      skuController.text = widget.product.sku ?? '';
    }
  }

  @override
  void dispose() {
    // ... (Hapus semua controller)
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

  Future<void> _saveProduct() async {
    // Validasi dasar
    if (nameController.text.isEmpty || _selectedCategoryId == null) {
      _showError("Nama produk dan Kategori harus diisi");
      return;
    }

    // 5. PERBAIKAN ERROR "KATEGORI TIDAK DITEMUKAN"
    if (_cachedCategories.isEmpty) {
      _showError("Data kategori belum dimuat. Coba beberapa saat lagi.");
      return;
    }

    final selectedCategoryObject = _cachedCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () {
        throw Exception(
            "Kategori yang dipilih ('$_selectedCategoryId') tidak valid. Muat ulang halaman.");
      },
    );

    setState(() {
      _isLoading = true;
    });

    try {
      Product updatedProduct;

      if (_isVariantProduct) {
        // === LOGIKA UPDATE PRODUK BERVARIAN ===
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
            id: widget.product.variants.length > i
                ? widget.product.variants[i].id
                : DateTime.now().millisecondsSinceEpoch.toString() +
                    i.toString(),
            name: name,
            hargaModal: modal,
            hargaJual: jual,
            stok: stok,
          ));
        }

        updatedProduct = Product(
          id: widget.product.id,
          name: nameController.text.trim(),
          imageUrl: _existingImageUrl,
          createdBy: widget.product.createdBy,
          timestamp: widget.product.timestamp,
          categoryId: selectedCategoryObject.id,
          categoryName: selectedCategoryObject.name,
          isVariantProduct: true,
          variants: variantsList,
        );
      } else {
        // === LOGIKA UPDATE PRODUK SIMPEL ===
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

        updatedProduct = Product(
          id: widget.product.id,
          name: nameController.text.trim(),
          imageUrl: _existingImageUrl,
          createdBy: widget.product.createdBy,
          timestamp: widget.product.timestamp,
          categoryId: selectedCategoryObject.id,
          categoryName: selectedCategoryObject.name,
          isVariantProduct: false,
          hargaModal: hargaModal,
          hargaJual: hargaJual,
          stok: stok,
          hargaDiskon: hargaDiskon,
          sku: sku,
        );
      }

      await _inventoryService.updateProduct(
        product: updatedProduct,
        newImageBytes: _imageBytes,
        newImageName: _imageName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Produk berhasil diperbarui!"),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Produk: ${widget.product.name}"),
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
                // === FORM DETAIL UMUM ===
                CustomTextField(
                  controller: nameController,
                  hintText: "Nama Produk",
                ),
                const SizedBox(height: 16),
                _buildCategoryDropdown(), // Dropdown kategori
                const SizedBox(height: 24),

                ImagePickerWidget(
                  onImagePicked: (imageBytes, fileName) {
                    setState(() {
                      _imageBytes = imageBytes;
                      _imageName = fileName;
                      _existingImageUrl = null;
                    });
                  },
                  existingImageUrl:
                      _imageBytes == null ? _existingImageUrl : null,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // === TIPE PRODUK (DISABLE) ===
                Text("Tipe Produk",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),

                // PERBAIKAN OVERFLOW TOGGLEBUTTONS
                ToggleButtons(
                  isSelected: [
                    _isVariantProduct == false,
                    _isVariantProduct == true
                  ],
                  onPressed: null, // Nonaktifkan tombol
                  borderRadius: BorderRadius.circular(8),
                  fillColor: Colors.grey.shade200,
                  color: Colors.grey.shade600,
                  selectedColor: Colors.black,
                  selectedBorderColor: Colors.grey.shade400,
                  borderColor: Colors.grey.shade400,
                  constraints: BoxConstraints(
                      // Menggunakan padding halaman (24*2=48) dan 6px spasi
                      minWidth:
                          (MediaQuery.of(context).size.width - 48 - 6) / 2,
                      minHeight: 40),
                  children: const [
                    Center(
                      child: Text(
                        "Produk Simpel",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Center(
                      child: Text(
                        "Produk Bervarian",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                Text("Tipe produk tidak dapat diubah setelah dibuat.",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 24),

                // TAMPILKAN FORM SESUAI TIPE
                if (_isVariantProduct)
                  _buildVariantForm() // Form baru untuk varian
                else
                  _buildSimpleForm(), // Form lama untuk produk simpel

                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _saveProduct,
                  text: _isLoading ? "Menyimpan..." : "Update Produk",
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

  // WIDGET KATEGORI (dengan perbaikan loading)
  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Category>>(
      stream: _categoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedCategories.isEmpty) {
          // Tampilkan loading HANYA JIKA cache masih kosong
          return DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            hint: const Text("Memuat kategori..."),
            isExpanded: true,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              fillColor: Colors.grey.shade100,
              filled: true,
            ),
            items: _selectedCategoryId != null
                ? [
                    DropdownMenuItem(
                      value: _selectedCategoryId,
                      child: Text(widget.product.categoryName ?? "Memuat..."),
                    )
                  ]
                : [],
            onChanged: null, // Nonaktifkan saat loading
          );
        }

        if (snapshot.hasData) {
          _cachedCategories = snapshot.data!; // Update cache
        }

        if (_cachedCategories.isEmpty) {
          // Ini terjadi jika stream selesai tapi datanya kosong
          return const Center(
            child: Text(
              "Belum ada kategori. Silakan tambah di menu Inventaris.",
              textAlign: TextAlign.center,
            ),
          );
        }

        // Cek jika _selectedCategoryId masih valid
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

  // WIDGET FORM SIMPEL (tidak berubah)
  Widget _buildSimpleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Harga & Stok (Produk Simpel)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  // WIDGET FORM VARIAN (tidak berubah)
  Widget _buildVariantForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Varian Produk",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
            "Tambahkan varian seperti Ukuran (S, M, L) atau Rasa (Pedas, Original).",
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _variantNameCtrls.length,
          itemBuilder: (context, index) {
            return _buildVariantInputRow(index);
          },
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          icon: const Icon(Icons.add, color: primaryColor),
          label: const Text("Tambah Varian",
              style: TextStyle(color: primaryColor)),
          onPressed: _addNewVariantRow,
        ),
      ],
    );
  }

  // WIDGET BARIS VARIAN (tidak berubah)
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
          side: BorderSide(color: Colors.grey.shade200)),
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
                        labelText: "Nama Varian (Cth: Besar)"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                  onPressed: () {
                    if (_variantNameCtrls.length > 1) {
                      _removeVariantRow(index);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _variantModalCtrls[index],
                    decoration: const InputDecoration(labelText: "H. Modal"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: numberFormatter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _variantJualCtrls[index],
                    decoration: const InputDecoration(labelText: "H. Jual"),
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
                    decoration: const InputDecoration(labelText: "Stok"),
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
