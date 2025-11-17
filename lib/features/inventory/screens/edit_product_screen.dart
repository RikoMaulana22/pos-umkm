// lib/features/inventory/screens/edit_product_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/inventory_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../widgets/image_picker_widget.dart';
import '../../../shared/theme.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../models/product_variant_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  final String storeId;

  const EditProductScreen({
    super.key,
    required this.product,
    required this.storeId,
  });

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
  List<Category> _cachedCategories = [];
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();

    _categoryStream = _categoryService.getCategories(widget.storeId);

    // ISI FORM DENGAN DATA PRODUK YANG ADA
    nameController.text = widget.product.name;
    _selectedCategoryId = widget.product.categoryId;
    _isVariantProduct = widget.product.isVariantProduct;
    _existingImageUrl = widget.product.imageUrl;

    if (_isVariantProduct) {
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
      modalController.text = widget.product.hargaModal.toString();
      jualController.text = widget.product.hargaJual.toString();
      stokController.text = widget.product.stok.toString();
      diskonController.text = widget.product.hargaDiskon?.toString() ?? '';
      skuController.text = widget.product.sku ?? '';
    }
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

  // ✅ PERBAIKAN: Tambah progress indicator
  Future<void> _saveProduct() async {
    if (nameController.text.isEmpty || _selectedCategoryId == null) {
      _showError("Nama produk dan Kategori harus diisi");
      return;
    }

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
                      ? 'Mengupload gambar baru...'
                      : 'Menyimpan perubahan...',
                ),
              ),
            ],
          ),
          duration: const Duration(minutes: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }

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

        print('📝 Update produk varian: ${nameController.text}');
        print('📦 Jumlah varian: ${variantsList.length}');
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

        print('📝 Update produk simpel: ${nameController.text}');
        print('💰 Harga: Modal=$hargaModal, Jual=$hargaJual');
      }

      print(
          '🖼️ Ganti gambar: ${_imageBytes != null ? "Ya (${(_imageBytes!.length / 1024).toStringAsFixed(2)} KB)" : "Tidak"}');

      await _inventoryService.updateProduct(
        product: updatedProduct,
        newImageBytes: _imageBytes,
        newImageName: _imageName,
      );

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
              Text("Produk berhasil diperbarui!"),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      print('✅ Produk berhasil diupdate');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error update produk: $e');
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
        title: Text("Edit: ${widget.product.name}"),
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
                  hintText: "Nama Produk",
                ),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
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
                  onPressed: null, // Nonaktifkan
                  borderRadius: BorderRadius.circular(8),
                  fillColor: Colors.grey.shade200,
                  color: Colors.grey.shade600,
                  selectedColor: Colors.black,
                  selectedBorderColor: Colors.grey.shade400,
                  borderColor: Colors.grey.shade400,
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

                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Tipe produk tidak dapat diubah setelah dibuat.",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isVariantProduct)
                  _buildVariantForm()
                else
                  _buildSimpleForm(),

                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _saveProduct,
                  text: _isLoading ? "Menyimpan..." : "Update Produk",
                ),
                const SizedBox(height: 24),
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
                          ? 'Mengupload gambar baru...\nMohon tunggu'
                          : 'Menyimpan perubahan...',
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

  // ✅ PERBAIKAN: Dropdown kategori dengan loading state yang lebih baik
  Widget _buildCategoryDropdown() {
    return StreamBuilder<List<Category>>(
      stream: _categoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedCategories.isEmpty) {
          return DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            hint: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text("Memuat kategori..."),
              ],
            ),
            isExpanded: true,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              fillColor: Colors.grey.shade100,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            ),
            items: _selectedCategoryId != null
                ? [
                    DropdownMenuItem(
                      value: _selectedCategoryId,
                      child: Text(widget.product.categoryName ?? "Memuat..."),
                    )
                  ]
                : [],
            onChanged: null,
          );
        }

        if (snapshot.hasData) {
          _cachedCategories = snapshot.data!;
        }

        if (_cachedCategories.isEmpty) {
          return Center(
            child: Column(
              children: [
                Text(
                  "Belum ada kategori.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Refresh stream
                    setState(() {
                      _categoryStream =
                          _categoryService.getCategories(widget.storeId);
                    });
                  },
                  child: const Text("Muat Ulang"),
                ),
              ],
            ),
          );
        }

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
          hintText: "Stok",
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
