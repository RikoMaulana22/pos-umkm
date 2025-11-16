// lib/features/reports/services/pdf_saver_mobile.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> savePdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  // 1. Minta Izin Penyimpanan
  if (Platform.isAndroid) {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception("Izin penyimpanan ditolak");
      }
    }
  } else if (Platform.isIOS) {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception("Izin penyimpanan ditolak");
    }
  }

  // 2. Dapatkan Direktori
  Directory? dir;
  if (Platform.isAndroid) {
    dir = await getDownloadsDirectory();
  } else if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  } else {
    dir = await getDownloadsDirectory();
  }

  if (dir == null) {
    throw Exception("Gagal menemukan direktori penyimpanan.");
  }

  // 3. Simpan File
  final String path = '${dir.path}/$fileName';
  final File file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return path;
}