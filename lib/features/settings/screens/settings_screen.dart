// lib/features/settings/screens/settings_screen.dart
import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../models/store_model.dart';
import '../services/settings_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
// 1. IMPOR BARU
import '../services/printer_service.dart';

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

  // 2. STATE UNTUK PRINTER
  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  String? _savedPrinterName;
  String? _savedPrinterAddress;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _storeDetailsFuture = _settingsService.getStoreDetails(widget.storeId);
    _storeDetailsFuture.then((store) {
      storeNameController.text = store.name;
    });

    // 3. Muat data printer yang tersimpan saat halaman dibuka
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final printerData = await _printerService.getSavedPrinter();
    setState(() {
      _savedPrinterName = printerData['name'];
      _savedPrinterAddress = printerData['address'];
    });
  }

  void _saveSettings() async {
    // Logika simpan nama toko (tidak berubah)
    if (storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nama toko tidak boleh kosong"),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _isLoading = true;
    });
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
      // ... (error handling tidak berubah)
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 4. FUNGSI UNTUK MENAMPILKAN MODAL PRINTER
  void _showPrinterDialog() {
    List<BluetoothDevice> devices = [];
    BluetoothDevice? selectedDevice;
    bool isScanning = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Fungsi scan
            void startScan() async {
              setModalState(() {
                isScanning = true;
                devices = [];
              });
              try {
                devices = await _printer.getBondedDevices();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Gagal memindai: ${e.toString()}"),
                    backgroundColor: Colors.red));
              } finally {
                setModalState(() {
                  isScanning = false;
                });
              }
            }

            // Fungsi hubungkan & simpan
            void connectAndSave() async {
              if (selectedDevice == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Silakan pilih perangkat terlebih dahulu"),
                    backgroundColor: Colors.orange));
                return;
              }

              setState(() {
                _isConnecting = true;
              }); // Loading di layar utama
              Navigator.pop(context); // Tutup modal

              try {
                bool? isConnected = await _printer.connect(selectedDevice!);
                if (isConnected == true) {
                  await _printerService.savePrinter(selectedDevice!);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text("Printer ${selectedDevice!.name} terhubung!"),
                      backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Gagal terhubung ke printer"),
                      backgroundColor: Colors.red));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error koneksi: ${e.toString()}"),
                    backgroundColor: Colors.red));
              } finally {
                setState(() {
                  _isConnecting = false;
                });
                _loadSavedPrinter(); // Muat ulang data di layar utama
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Pilih Printer",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isScanning ? null : startScan,
                      icon: isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: Text(isScanning
                          ? "Memindai..."
                          : "Scan Perangkat Bluetooth"),
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: devices.isEmpty
                        ? Center(
                            child: Text(isScanning
                                ? "Mencari perangkat..."
                                : "Tekan scan untuk mencari printer"))
                        : ListView.builder(
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              final bool isSelected = selectedDevice == device;
                              return ListTile(
                                leading: Icon(isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                                title: Text(device.name ?? 'Unknown Device'),
                                subtitle: Text(device.address ?? 'No Address'),
                                onTap: () {
                                  setModalState(() {
                                    selectedDevice = device;
                                  });
                                },
                                tileColor: isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : null,
                              );
                            },
                          ),
                  ),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onTap: selectedDevice == null ? null : connectAndSave,
                      text: "Hubungkan & Simpan Printer Ini",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 5. FUNGSI UNTUK PUTUSKAN PRINTER
  void _disconnectPrinter() async {
    try {
      await _printer.disconnect();
      await _printerService.clearPrinter();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Printer terputus"), backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      _loadSavedPrinter();
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
          FutureBuilder<StoreModel>(
            future: _storeDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // ... (error handling tidak berubah) ...

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pengaturan Toko",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: storeNameController,
                      hintText: "Nama Toko",
                    ),
                    const SizedBox(height: 32),
                    const Text("Pengaturan Printer",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // 6. UBAH TAMPILAN LISTTILE PRINTER
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300)),
                      leading: Icon(Icons.print,
                          color: _savedPrinterName != null
                              ? Colors.green
                              : primaryColor,
                          size: 40),
                      title: Text(_savedPrinterName ?? "Hubungkan Printer"),
                      subtitle: Text(_savedPrinterAddress ??
                          "Belum ada printer terhubung"),
                      trailing: _savedPrinterName != null
                          ? TextButton(
                              onPressed: _disconnectPrinter,
                              child: const Text("Putus",
                                  style: TextStyle(color: Colors.red)),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap:
                          _savedPrinterName == null ? _showPrinterDialog : null,
                    ),

                    const Divider(height: 32),
                    CustomButton(
                      onTap: _isLoading ? null : _saveSettings,
                      text: "Simpan Pengaturan",
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isLoading || _isConnecting) // 7. Tampilkan loading
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _isConnecting
                        ? "Menghubungkan ke printer..."
                        : "Menyimpan...",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )
                ],
              )),
            ),
        ],
      ),
    );
  }
}
