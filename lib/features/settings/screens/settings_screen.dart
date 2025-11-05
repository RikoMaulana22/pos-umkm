// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../models/store_model.dart';
import '../services/settings_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';

// 1. Ubah menjadi StatefulWidget
class SettingsScreen extends StatefulWidget {
  final String storeId;
  const SettingsScreen({super.key, required this.storeId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController storeNameController = TextEditingController();
  
  late Future<StoreModel> _storeDetailsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 2. Ambil data toko saat halaman dibuka
    _storeDetailsFuture = _settingsService.getStoreDetails(widget.storeId);
    
    // 3. Isi controller setelah data didapat
    _storeDetailsFuture.then((store) {
      storeNameController.text = store.name;
    });
  }

  void _saveSettings() async {
    if (storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nama toko tidak boleh kosong"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await _settingsService.updateStoreName(
        widget.storeId,
        storeNameController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Pengaturan berhasil disimpan!"),
          backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal menyimpan: ${e.toString()}"),
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
        title: const Text('Pengaturan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 4. Gunakan FutureBuilder untuk menampilkan data
          FutureBuilder<StoreModel>(
            future: _storeDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text("Toko tidak ditemukan."));
              }

              // Jika data berhasil diambil
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Bagian Pengaturan Toko ===
                    const Text(
                      "Pengaturan Toko",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: storeNameController,
                      hintText: "Nama Toko",
                    ),
                    const SizedBox(height: 32),
                    
                    // === Bagian Pengaturan Printer ===
                    const Text(
                      "Pengaturan Printer",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.print, color: primaryColor),
                      title: const Text("Hubungkan Printer"),
                      subtitle: const Text("Belum ada printer terhubung"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implementasi 'blue_thermal_printer'
                        print("Membuka pengaturan printer...");
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 32),

                    // Tombol Simpan
                    CustomButton(
                      onTap: _isLoading ? null : _saveSettings,
                      text: "Simpan Pengaturan",
                    ),
                  ],
                ),
              );
            },
          ),

          // Loading Overlay
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