import 'dart:typed_data'; // PERBAIKAN: Gunakan titik dua (:)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(Uint8List imageBytes, String fileName) onImagePicked;
  final String? existingImageUrl;

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    this.existingImageUrl,
  });

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Uint8List? _imageBytes;
  String? _imageName;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxHeight: 100,
        maxWidth: 100,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
        widget.onImagePicked(_imageBytes!, _imageName!);
      }
    } catch (e) {
      print("Gagal mengambil gambar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImageWidget(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: Text(_imageBytes != null ||
                    (widget.existingImageUrl != null &&
                        widget.existingImageUrl!.isNotEmpty)
                ? "Ganti Gambar"
                : "Pilih Gambar Produk"),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
      );
    }
    if (widget.existingImageUrl != null &&
        widget.existingImageUrl!.isNotEmpty) {
      return Image.network(
        widget.existingImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
          );
        },
      );
    }
    return const Center(
      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
    );
  }
}
