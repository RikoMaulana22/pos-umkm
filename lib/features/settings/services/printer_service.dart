// lib/features/settings/services/printer_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  static const String _nameKey = 'printer_name';
  static const String _addressKey = 'printer_address';

  // Menyimpan detail printer
  Future<void> savePrinter(BluetoothDevice device) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_nameKey, device.name ?? 'Unknown Device');
    await prefs.setString(_addressKey, device.address ?? '');
  }

  // Mengambil detail printer yang tersimpan
  Future<Map<String, String?>> getSavedPrinter() async {
    final SharedPreferences prefs = await _prefs;
    final String? name = prefs.getString(_nameKey);
    final String? address = prefs.getString(_addressKey);
    return {'name': name, 'address': address};
  }

  // Menghapus printer
  Future<void> clearPrinter() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_nameKey);
    await prefs.remove(_addressKey);
  }
}
