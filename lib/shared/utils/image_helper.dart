import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageHelper {
  /// Compress gambar ke ukuran maksimal (default 800px) dan kualitas 85%
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int quality = 85,
  }) async {
    try {
      print(
          '🖼️ Ukuran asli: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');

      // Decode gambar
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Gagal decode gambar');
      }

      print('📐 Resolusi asli: ${image.width}x${image.height}');

      // Resize jika lebih besar dari maxWidth
      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
        print('📐 Resolusi setelah resize: ${image.width}x${image.height}');
      }

      // Encode ke JPEG dengan kualitas yang ditentukan
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      print(
          '✅ Ukuran setelah compress: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
      print(
          '💾 Penghematan: ${((1 - compressedBytes.length / imageBytes.length) * 100).toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      print('❌ Error compress gambar: $e');
      // Jika gagal compress, kembalikan gambar asli
      return imageBytes;
    }
  }

  /// Compress untuk thumbnail (sangat kecil untuk preview cepat)
  static Future<Uint8List> compressThumbnail(
    Uint8List imageBytes, {
    int maxWidth = 200,
    int quality = 70,
  }) async {
    return compressImage(imageBytes, maxWidth: maxWidth, quality: quality);
  }
}
