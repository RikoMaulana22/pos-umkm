import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/utils/image_helper.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(Uint8List, String) onImagePicked;
  final String? existingImageUrl; // ✅ TAMBAHKAN PARAMETER INI

  const ImagePickerWidget({
    super.key,
    required this.onImagePicked,
    this.existingImageUrl, // ✅ TAMBAHKAN INI
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isCompressing = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _isCompressing = true;
        });

        final originalBytes = await pickedFile.readAsBytes();

        // ✅ COMPRESS GAMBAR
        final compressedBytes = await ImageHelper.compressImage(
          originalBytes,
          maxWidth: 800,
          quality: 85,
        );

        setState(() {
          _imageBytes = compressedBytes;
          _isCompressing = false;
        });

        widget.onImagePicked(compressedBytes, pickedFile.name);
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ TAMPILKAN GAMBAR BARU ATAU GAMBAR EXISTING
        if (_imageBytes != null)
          // Gambar baru yang baru dipilih
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _imageBytes = null;
                    });
                    widget.onImagePicked(Uint8List(0), '');
                  },
                ),
              ),
              // ✅ Label "Gambar Baru"
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Gambar Baru",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
        else if (widget.existingImageUrl != null &&
            widget.existingImageUrl!.isNotEmpty)
          // Gambar existing dari server
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.existingImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            "Gagal memuat gambar",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withValues(alpha: 0.8),
                  ),
                  onPressed: _pickImage,
                  tooltip: "Ganti gambar",
                ),
              ),
              // ✅ Label "Gambar Saat Ini"
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Gambar Saat Ini",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // Belum ada gambar sama sekali
          _isCompressing
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Mengoptimalkan gambar...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey[400]!,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk pilih gambar (opsional)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
        if (!_isCompressing &&
            _imageBytes == null &&
            widget.existingImageUrl == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Gambar akan di-compress otomatis untuk mempercepat upload',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
