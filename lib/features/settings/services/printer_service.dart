// lib/features/settings/services/printer_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static const String _nameKey = 'printer_name';
  static const String _addressKey = 'printer_address';

  // Menyimpan detail printer
  Future<void> savePrinter(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_name', name);
    await prefs.setString('printer_address', address);
  }

  // Update fungsi getSavedPrinter Anda agar mengembalikan Map:
  Future<Map<String, String?>> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('printer_name'),
      'address': prefs.getString('printer_address'),
    };
  }

  // Fungsi hapus
  Future<void> clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('printer_name');
    await prefs.remove('printer_address');
  }

  // Menghapus printer
}
