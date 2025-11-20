// lib/features/settings/screens/settings_screen.dart
import 'dart:async';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:erp_umkm/features/settings/screens/contact_us_screen.dart';
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../models/store_model.dart';
import '../services/settings_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
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

  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  String? _savedPrinterName;
  String? _savedPrinterAddress;
  bool _isPrinterBusy = false;
  String _printerStatusMessage = "";

  @override
  void initState() {
    super.initState();
    _storeDetailsFuture = _settingsService.getStoreDetails(widget.storeId);
    _storeDetailsFuture.then((store) {
      storeNameController.text = store.name;
    });
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
    if (storeNameController.text.isEmpty) {
      _showErrorSnackBar("Nama toko tidak boleh kosong");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _settingsService.updateStoreName(
        widget.storeId,
        storeNameController.text,
      );
      if (!mounted) return;
      _showSuccessSnackBar("Pengaturan berhasil disimpan!");
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar("Gagal simpan: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPrinterDialog() {
    List<BluetoothDevice> devices = [];
    BluetoothDevice? selectedDevice;
    bool isScanning = false;

    _showInfoSnackBar(
      "Pastikan printer sudah di-pairing di Pengaturan Bluetooth HP Anda.",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void startScan() async {
              setModalState(() {
                isScanning = true;
                devices = [];
              });
              try {
                bool? isEnabled = await _printer.isOn;
                if (isEnabled != true) {
                  throw Exception("Bluetooth tidak menyala.");
                }
                devices = await _printer.getBondedDevices();
              } catch (e) {
                if (!mounted) return;
                _showErrorSnackBar("Gagal memindai: ${e.toString()}");
              } finally {
                setModalState(() => isScanning = false);
              }
            }

            void connectAndSave() async {
              if (selectedDevice == null) {
                _showErrorSnackBar("Silakan pilih perangkat terlebih dahulu");
                return;
              }

              setState(() {
                _isPrinterBusy = true;
                _printerStatusMessage = "Menghubungkan...";
              });
              Navigator.pop(context);

              try {
                bool? isConnected = await _printer.connect(selectedDevice!);
                if (isConnected == true) {
                  await _printerService.savePrinter(selectedDevice!);
                  if (!mounted) return;
                  _showSuccessSnackBar(
                    "Printer ${selectedDevice!.name} terhubung!",
                  );
                } else {
                  _showErrorSnackBar("Gagal terhubung ke printer");
                }
              } catch (e) {
                _showErrorSnackBar("Error koneksi: ${e.toString()}");
              } finally {
                if (mounted) {
                  setState(() {
                    _isPrinterBusy = false;
                    _printerStatusMessage = "";
                  });
                  _loadSavedPrinter();
                }
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pilih Printer",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isScanning ? null : startScan,
                        icon: isScanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded,
                                color: Colors.white), // ✅ Icon putih
                        label: Text(
                          isScanning
                              ? "Memindai..."
                              : "Scan Perangkat (Paired)",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // ✅ Text putih
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors
                              .white, // ✅ Foreground color putih (untuk icon default & text)
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 0),

                  Expanded(
                    child: devices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isScanning
                                      ? Icons.hourglass_bottom
                                      : Icons.print_disabled,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isScanning
                                      ? "Mencari perangkat..."
                                      : "Tidak ada printer ditemukan",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tekan scan untuk mencari printer",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: devices.length,
                            separatorBuilder: (_, __) => const SizedBox(
                              height: 8,
                            ),
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              final bool isSelected = selectedDevice == device;
                              return _buildPrinterDeviceCard(
                                device: device,
                                isSelected: isSelected,
                                onTap: () {
                                  setModalState(() {
                                    selectedDevice = device;
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  const Divider(height: 0),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                selectedDevice == null ? null : connectAndSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Hubungkan & Simpan",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPrinterDeviceCard({
    required BluetoothDevice device,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.print,
                  color: isSelected ? primaryColor : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name ?? 'Unknown Device',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.address ?? 'No Address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _disconnectPrinter() async {
    setState(() {
      _isPrinterBusy = true;
      _printerStatusMessage = "Memutus koneksi...";
    });
    try {
      await _printer.disconnect();
      await _printerService.clearPrinter();
      if (!mounted) return;
      _showInfoSnackBar("Printer terputus");
    } catch (e) {
      _showErrorSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isPrinterBusy = false;
          _printerStatusMessage = "";
        });
        _loadSavedPrinter();
      }
    }
  }

  Future<void> _runTestPrint() async {
    if (_savedPrinterAddress == null || _savedPrinterAddress!.isEmpty) {
      _showErrorSnackBar("Tidak ada printer tersimpan");
      return;
    }

    setState(() {
      _isPrinterBusy = true;
      _printerStatusMessage = "Mencetak tes...";
    });

    try {
      bool? isConnected = await _printer.isConnected;
      if (isConnected != true) {
        final device = BluetoothDevice(_savedPrinterName, _savedPrinterAddress);
        await _printer.connect(device);
      }

      _printer.printCustom("Test Print Berhasil!", 1, 1);
      _printer.printNewLine();
      _printer.printCustom("POS UMKM Siap Digunakan", 0, 1);
      _printer.printNewLine();
      _printer.printNewLine();
      _printer.paperCut();

      if (!mounted) return;
      _showSuccessSnackBar("Test print terkirim!");
    } catch (e) {
      _showErrorSnackBar("Gagal test print: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isPrinterBusy = false;
          _printerStatusMessage = "";
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('⚙️ Pengaturan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<StoreModel>(
            future: _storeDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat pengaturan...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text("Error: ${snapshot.error}"),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Text("Gagal memuat data toko."),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✨ Store Settings Section
                    _buildSectionHeader("📦 Pengaturan Toko"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nama Toko",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: storeNameController,
                            hintText: "Masukkan nama toko",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ✨ Printer Settings Section
                    _buildSectionHeader("🖨️ Pengaturan Printer"),
                    const SizedBox(height: 16),
                    _buildPrinterSettingsCard(),

                    const SizedBox(height: 40),
                    ListTile(
                      leading: Icon(Icons.support_agent_rounded,
                          color: Colors.blue[700]),
                      title: const Text('Hubungi Kami'),
                      trailing:
                          Icon(Icons.navigate_next, color: Colors.grey[600]),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // ✨ Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _isLoading ? "Menyimpan..." : "💾 Simpan Pengaturan",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),

          // ✨ Loading Overlay
          if (_isLoading || _isPrinterBusy)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 20),
                      Text(
                        _isLoading
                            ? "Menyimpan pengaturan..."
                            : _printerStatusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _savedPrinterName != null
              ? Colors.green[300]!
              : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_savedPrinterName != null ? Colors.green : Colors.black)
                .withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _savedPrinterName != null
                        ? Colors.green[100]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    color:
                        _savedPrinterName != null ? Colors.green : primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ PERBAIKAN: Warna teks diubah agar terlihat
                      Text(
                        _savedPrinterName ?? "Hubungkan Printer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _savedPrinterName != null
                              ? Colors.black87 // Hitam jika terhubung
                              : Colors
                                  .black87, // << PERBAIKAN DI SINI (sebelumnya Colors.white)
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _savedPrinterAddress ?? "Belum ada printer terhubung",
                        style: TextStyle(
                          fontSize: 12,
                          color: _savedPrinterName != null
                              ? Colors.grey[600]
                              : Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_savedPrinterName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Terhubung",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_savedPrinterName != null)
            Column(
              children: [
                const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: _isPrinterBusy ? null : _runTestPrint,
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: const Text("Test Print"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isPrinterBusy ? null : _disconnectPrinter,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text("Putus"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isPrinterBusy ? null : _showPrinterDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    "Hubungkan Printer",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor:
                        Colors.white, // ✅ Foreground color putih (icon & text)
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
