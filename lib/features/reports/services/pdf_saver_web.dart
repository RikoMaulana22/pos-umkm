// lib/features/reports/services/pdf_saver_web.dart
import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> savePdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  // 1. Buat Blob (file di memori browser)
  final blob = html.Blob([bytes], 'application/pdf');

  // 2. Buat URL untuk blob tersebut
  final url = html.Url.createObjectUrlFromBlob(blob);

  // 3. Buat elemen link (<a>) baru
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName) // Beri nama file download
    ..click(); // Klik link-nya secara programatis

  // 4. Hapus URL-nya dari memori
  html.Url.revokeObjectUrl(url);
  
  // Di web, kita tidak mengembalikan path, jadi kembalikan null
  return null; 
}