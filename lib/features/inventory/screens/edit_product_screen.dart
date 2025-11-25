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

  final TextEditingController modalController = TextEditingController();
  final TextEditingController jualController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController diskonController = TextEditingController();
  final TextEditingController skuController = TextEditingController();

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
            "Kategori yang dipilih ('$_selectedCategoryId') tidak valid.");
      },
    );

    setState(() => _isLoading = true);

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

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      _showError("Gagal menyimpan: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('✏️ Edit Produk'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✨ Header Card
                _buildHeaderCard(),

                const SizedBox(height: 32),

                // ✨ Product Info Section
                _buildSectionHeader("📝 Informasi Produk"),
                const SizedBox(height: 16),
                _buildProductInfoForm(),

                const SizedBox(height: 32),

                // ✨ Product Type Info (Disabled)
                _buildProductTypeSection(),

                const SizedBox(height: 32),

                // ✨ Dynamic Form (Simple or Variant)
                if (_isVariantProduct)
                  _buildVariantForm()
                else
                  _buildSimpleForm(),

                const SizedBox(height: 40),

                // ✨ Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _isLoading ? "Menyimpan..." : "✅ Update Produk",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ✨ Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 20),
                      Text(
                        _imageBytes != null
                            ? "Mengupload gambar baru...\nMohon tunggu"
                            : "Menyimpan perubahan...",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Edit data produk dengan lengkap",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: nameController,
            hintText: "Nama Produk",
          ),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          ImagePickerWidget(
            onImagePicked: (imageBytes, fileName) {
              setState(() {
                _imageBytes = imageBytes;
                _imageName = fileName;
                _existingImageUrl = null;
              });
            },
            existingImageUrl: _imageBytes == null ? _existingImageUrl : null,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("🎯 Tipe Produk"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tipe produk tidak dapat diubah setelah dibuat",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              ToggleButtons(
                isSelected: [!_isVariantProduct, _isVariantProduct],
                onPressed: null,
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.black,
                fillColor: Colors.grey[300],
                color: Colors.grey[600],
                selectedBorderColor: Colors.grey[400],
                borderColor: Colors.grey[400],
                constraints: BoxConstraints(
                  minWidth: (MediaQuery.of(context).size.width - 88) / 2,
                  minHeight: 48,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_bag_rounded, size: 20),
                        SizedBox(height: 4),
                        Text(
                          "Produk Simpel",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.category_rounded, size: 20),
                        SizedBox(height: 4),
                        Text(
                          "Produk Bervarian",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded,
                        color: Colors.amber[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Ubah kategori tipe produk di halaman tambah produk baru",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              prefixIcon: Icon(Icons.category_rounded, color: primaryColor),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
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
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Belum ada kategori. Silakan tambah di menu Inventaris.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
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
            prefixIcon: Icon(Icons.category_rounded, color: primaryColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: _cachedCategories.map((Category category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() => _selectedCategoryId = newValue);
          },
        );
      },
    );
  }

  Widget _buildSimpleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("💰 Harga & Stok"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildPriceField(
                controller: modalController,
                label: "Harga Modal (Beli)",
                icon: Icons.local_offer_rounded,
              ),
              const SizedBox(height: 16),
              _buildPriceField(
                controller: jualController,
                label: "Harga Jual",
                icon: Icons.sell_rounded,
              ),
              const SizedBox(height: 16),
              _buildPriceField(
                controller: diskonController,
                label: "Harga Diskon (Opsional)",
                icon: Icons.discount_rounded,
              ),
              const SizedBox(height: 16),
              _buildStockField(
                controller: stokController,
                label: "Stok",
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: skuController,
                hintText: "SKU / Barcode (Opsional)",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
          ],
          decoration: InputDecoration(
            hintText: "0",
            prefixIcon: Icon(icon, color: primaryColor),
            prefixText: "Rp ",
            prefixStyle: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: "0",
            prefixIcon: Icon(icon, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("🎨 Varian Produk"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Edit varian sesuai kebutuhan Anda",
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(
            _variantNameCtrls.length,
            (index) => _buildVariantCard(index),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _addNewVariantRow,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Tambah Varian"),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Varian ${index + 1}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (_variantNameCtrls.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                  onPressed: () => _removeVariantRow(index),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _variantNameCtrls[index],
            hintText: "Nama Varian (Cth: Besar, Merah, Pedas)",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPriceField(
                  controller: _variantModalCtrls[index],
                  label: "H. Modal",
                  icon: Icons.local_offer_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceField(
                  controller: _variantJualCtrls[index],
                  label: "H. Jual",
                  icon: Icons.sell_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStockField(
            controller: _variantStokCtrls[index],
            label: "Stok",
            icon: Icons.inventory_2_rounded,
          ),
        ],
      ),
    );
  }
}
