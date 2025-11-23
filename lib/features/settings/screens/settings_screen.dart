import 'dart:async';
import 'dart:io'; // Masih dibutuhkan untuk Printer (Android/iOS), tapi tidak dipakai untuk QRIS
import 'dart:typed_data'; // PENTING: Untuk Uint8List

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:erp_umkm/features/settings/screens/contact_us_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/theme.dart';
import '../models/store_model.dart';
import '../services/settings_service.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../services/printer_service.dart';
import '../../settings/services/qris_service.dart';

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

  // Printer Variables
  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  String? _savedPrinterName;
  String? _savedPrinterAddress;
  bool _isPrinterBusy = false;
  String _printerStatusMessage = "";

  // QRIS Variables
  String? _qrisUrl;
  final QrisService _qrisService = QrisService();
  Uint8List?
      _qrisImageBytes; // GANTI: Menggunakan bytes untuk preview lintas platform
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadQrisUrl();

    _storeDetailsFuture = _settingsService.getStoreDetails(widget.storeId);
    _storeDetailsFuture.then((store) {
      storeNameController.text = store.name;
    });
    _loadSavedPrinter();
  }

  Future<void> _loadQrisUrl() async {
    final url = await _qrisService.loadQrisUrl();
    if (mounted) {
      setState(() {
        _qrisUrl = url;
      });
    }
  }

  // UPDATE: Logic Picker & Upload Support Web
  Future<void> _pickQrisImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // 1. Baca bytes untuk preview (Mobile & Web aman)
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _qrisImageBytes = bytes;
          _isLoading = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mengupload QRIS ke Cloudinary...')));

        // 2. Upload menggunakan XFile (dikirim ke service baru)
        final url = await _qrisService.uploadQrisToCloudinary(pickedFile);

        setState(() => _isLoading = false);

        if (url != null) {
          setState(() {
            _qrisUrl = url;
            // Kosongkan bytes agar tampilan beralih ke URL (opsional,
            // tapi membiarkan bytes tetap ada sebagai preview instan lebih mulus)
          });
          await _qrisService.saveQrisUrl(url);
          _showSuccessSnackBar("QRIS berhasil diupdate.");
        } else {
          _showErrorSnackBar("Gagal upload QRIS.");
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Error picking image: $e");
    }
  }

  Future<void> _loadSavedPrinter() async {
    final printerData = await _printerService.getSavedPrinter();
    setState(() {
      _savedPrinterName = printerData['name'];
      _savedPrinterAddress = printerData['address'];
    });
  }

  void _showPrinterDialog() {
    _showInfoSnackBar(
        "Fitur scanner perangkat printer belum diimplementasi detail di contoh singkat ini.");
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

  // Helper untuk menampilkan gambar QRIS
  Widget _buildQrisImageWidget() {
    // 1. Prioritas: Gambar yang baru dipilih user (Preview lokal)
    if (_qrisImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _qrisImageBytes!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    // 2. Prioritas Kedua: Gambar URL yang tersimpan di cloud
    if (_qrisUrl != null && _qrisUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _qrisUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              color: Colors.grey[100],
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 120,
              height: 120,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      );
    }

    // 3. Default: Placeholder jika belum ada gambar sama sekali
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.qr_code_2_rounded, size: 44, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildQrisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("💳 QRIS Pembayaran"),
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
              _buildQrisImageWidget(),
              const SizedBox(height: 12),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  onPressed: _pickQrisImage,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text("Upload QRIS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
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
                      Text(
                        _savedPrinterName ?? "Hubungkan Printer",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                    foregroundColor: Colors.white,
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
                      Text('Memuat pengaturan...',
                          style: TextStyle(color: Colors.grey[600])),
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
                    _buildQrisSection(),
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
}
