// lib/features/reports/services/pdf_saver_mobile.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart'; // Tambahkan package ini jika belum ada, atau gunakan logika SDK manual
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> savePdfFile({
  required String fileName,
  required Uint8List bytes,
}) async {
  // 1. Cek Versi Android untuk Menentukan Izin
  if (Platform.isAndroid) {
    // Cek info Android SDK (Alternatif sederhana tanpa package device_info_plus)
    // Namun permission_handler biasanya menangani ini.
    // Kita gunakan pendekatan "Try Best, Then All Access".

    // Coba minta izin standard dulu
    var statusStorage = await Permission.storage.status;

    if (!statusStorage.isGranted) {
      // Minta izin
      statusStorage = await Permission.storage.request();
    }

    // Jika ditolak (biasanya di Android 11+), coba Manage External Storage
    if (!statusStorage.isGranted) {
      var statusManage = await Permission.manageExternalStorage.status;
      if (!statusManage.isGranted) {
        statusManage = await Permission.manageExternalStorage.request();
      }

      // Jika masih ditolak juga, baru lempar error
      if (!statusManage.isGranted) {
        // Cek apakah permission permanently denied, arahkan ke settings
        if (statusManage.isPermanentlyDenied) {
          await openAppSettings();
          throw Exception(
              "Izin ditolak permanen. Silakan aktifkan 'Akses Semua File' di pengaturan.");
        }
        throw Exception("Izin penyimpanan (Manage External Storage) ditolak");
      }
    }
  }
  // 2. iOS Logic
  else if (Platform.isIOS) {
    // iOS biasanya menggunakan ApplicationDocumentsDirectory yang tidak butuh izin eksplisit
    // tapi jika mau save ke Photos/Files public, butuh izin.
    // Kode lama Anda:
    // var status = await Permission.storage.request();
    // if (!status.isGranted) throw Exception("Izin penyimpanan ditolak");
  }

  // 3. Tentukan Folder Penyimpanan
  Directory? dir;
  if (Platform.isAndroid) {
    dir = await getDownloadsDirectory();
    // Fallback jika downloads directory null (di beberapa device android lama)
    dir ??= await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  }

  if (dir == null) {
    throw Exception("Gagal menemukan direktori penyimpanan.");
  }

  // 4. Simpan File
  final String path = '${dir.path}/$fileName';
  final File file = File(path);
  await file.writeAsBytes(bytes, flush: true);

  return path;
}
