// lib/features/reports/services/pdf_saver_stub.dart
import 'dart:typed_data';

Future<String?> savePdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  // Lemparkan error karena platform ini tidak didukung
  throw UnsupportedError('Cannot save file on this platform');
}