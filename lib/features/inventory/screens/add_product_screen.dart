// lib/features/inventory/screens/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/inventory_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../widgets/image_picker_widget.dart';
import '../../../shared/theme.dart';

class AddProductScreen extends StatefulWidget {
  final String storeId;
  const AddProductScreen({super.key, required this.storeId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final InventoryService _inventoryService = InventoryService();
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController modalController = TextEditingController();
  final TextEditingController jualController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  
  Uint8List? _imageBytes; 
  String? _imageName;
  bool _isLoading = false;

  void _saveProduct() async {
    if (nameController.text.isEmpty ||
        modalController.text.isEmpty ||
        jualController.text.isEmpty ||
        stokController.text.isEmpty ||
        _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Semua field dan gambar harus diisi"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    double? hargaModal;
    double? hargaJual;
    int? stok;

    try {
      hargaModal = double.tryParse(modalController.text.replaceAll(',', '.'));
      hargaJual = double.tryParse(jualController.text.replaceAll(',', '.'));
      stok = int.tryParse(stokController.text);

      if (hargaModal == null || hargaJual == null || stok == null) {
        throw const FormatException("Format angka tidak valid. Gunakan angka saja.");
      }
      
      await _inventoryService.addProduct(
        name: nameController.text,
        hargaModal: hargaModal,
        hargaJual: hargaJual,
        stok: stok,
        imageBytes: _imageBytes!, 
        imageName: _imageName!,
        storeId: widget.storeId,
      );

      if (!mounted) return; 

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Produk berhasil ditambahkan!"),
          backgroundColor: Colors.green));
      Navigator.pop(context);

    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.message}"),
          backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal menambah produk: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
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
                  controller: stokController,
                  hintText: "Stok Awal",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 24),
                
                ImagePickerWidget(
                  onImagePicked: (imageBytes, fileName) {
                    _imageBytes = imageBytes;
                    _imageName = fileName;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _saveProduct,
                  text: "Simpan Produk",
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}