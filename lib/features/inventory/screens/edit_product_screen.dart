// lib/features/inventory/screens/edit_product_screen.dart
import 'dart:typed_data'; // <-- 1. PERBAIKI IMPOR
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 2. IMPOR INI
import '../models/product_model.dart';
import '../services/inventory_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../widgets/image_picker_widget.dart';
import '../../../shared/theme.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final InventoryService _inventoryService = InventoryService();

  late TextEditingController nameController;
  late TextEditingController modalController;
  late TextEditingController jualController;
  late TextEditingController stokController;

  Uint8List? _imageBytes; // <-- 3. Gunakan Uint8List
  String? _imageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    modalController = TextEditingController(
        text: widget.product.hargaModal.toStringAsFixed(0));
    jualController = TextEditingController(
        text: widget.product.hargaJual.toStringAsFixed(0));
    stokController =
        TextEditingController(text: widget.product.stok.toString());
  }

  void _updateProduct() async {
    setState(() {
      _isLoading = true;
    });

    double? hargaModal;
    double? hargaJual;
    int? stok;

    try {
      hargaModal = double.tryParse(modalController.text.replaceAll(',', '.'));
      hargaJual = double.tryParse(jualController.text.replaceAll(',', '.'));
      stok = int.tryParse(stokController.text);

      if (hargaModal == null || hargaJual == null || stok == null) {
        throw const FormatException("Format angka tidak valid.");
      }

      Product updatedProduct = Product(
        id: widget.product.id,
        name: nameController.text,
        hargaModal: hargaModal,
        hargaJual: hargaJual,
        stok: stok,
        imageUrl: _imageBytes == null ? widget.product.imageUrl : null,
        createdBy: widget.product.createdBy,
      );

      await _inventoryService.updateProduct(
        product: updatedProduct,
        newImageBytes: _imageBytes, // <-- 4. Kirim bytes
        newImageName: _imageName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Produk berhasil diperbarui!"),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.message}"), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal update produk: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteProduct() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk?"),
        content: Text("Anda yakin ingin menghapus '${widget.product.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == null || !confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _inventoryService.deleteProduct(widget.product.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Produk berhasil dihapus!"),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal menghapus produk: ${e.toString()}"),
          backgroundColor: Colors.red));
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
        title: const Text("Edit Produk"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _deleteProduct,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Produk",
          ),
        ],
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
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal:
                          true), // 5. Tambahkan keyboardType & inputFormatters
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
                  hintText: "Stok",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 24),
                ImagePickerWidget(
                  existingImageUrl: widget.product.imageUrl,
                  onImagePicked: (imageBytes, fileName) {
                    // <-- 6. Terima 2 parameter
                    _imageBytes = imageBytes;
                    _imageName = fileName;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _updateProduct,
                  text: "Update Produk",
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
