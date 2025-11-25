import 'dart:convert'; // Tambahan untuk JSON decode
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // Tambahan untuk HTTP Request
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy Clipboard

import '../../../shared/theme.dart';
import '../../inventory/widgets/image_picker_widget.dart';

class PaymentUploadScreen extends StatefulWidget {
  final String storeId;
  final String packageName;
  final double price;

  const PaymentUploadScreen({
    super.key,
    required this.storeId,
    required this.packageName,
    required this.price,
  });

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  Uint8List? _imageBytes;
  String? _imageName;

  // Progress indicator: null = idle, 0.0-1.0 = progress
  double? _uploadProgress;

  // =======================================================================
  // ⚙️ KONFIGURASI CLOUDINARY
  // =======================================================================
  final String _cloudName = "dnw2t61ne";
  final String _uploadPreset = "pos_umkm_preset";

  // =======================================================================
  // ☁️ FUNGSI UPLOAD KE CLOUDINARY
  // =======================================================================
  Future<String?> _uploadToCloudinary(Uint8List imageBytes) async {
    try {
      var uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
            filename: 'payment_proof.jpg'));

      // Kirim request
      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonMap = jsonDecode(respStr);
        return jsonMap['secure_url']; // URL HTTPS aman
      } else {
        debugPrint(
            '⚠️ Gagal Upload ke Cloudinary. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Error Koneksi Cloudinary: $e');
      return null;
    }
  }

  Future<void> _submitProof() async {
    if (_imageBytes == null || _imageName == null) {
      _showErrorSnackBar("Harap upload bukti pembayaran terlebih dahulu.");
      return;
    }

    setState(() {
      _uploadProgress = 0.2; // Set progress awal (simulasi loading)
    });

    try {
      // 1. Upload Gambar ke Cloudinary
      // Note: HTTP request standar tidak memiliki stream progress yang mudah seperti Firebase SDK,
      // jadi kita gunakan indikator loading indeterminate atau simulasi.

      final downloadUrl = await _uploadToCloudinary(_imageBytes!);

      if (downloadUrl == null) {
        throw Exception("Gagal mengupload gambar ke server.");
      }

      setState(() {
        _uploadProgress = 0.8; // Update progress setelah gambar terupload
      });

      // 2. Buat Dokumen di 'upgradeRequests' (Firestore)
      // Perhatikan nama collection ini harus sama dengan yang dibaca di Admin
      await FirebaseFirestore.instance.collection('upgradeRequests').add({
        'storeId': widget.storeId,
        'packageName': widget.packageName,
        'price': widget.price,
        'status': 'pending',
        'paymentMethod': 'Transfer Manual', // Default value
        'requestedAt': FieldValue.serverTimestamp(),
        // Tambahkan field createdAt untuk konsistensi jika perlu
        'createdAt': FieldValue.serverTimestamp(),
        'proofOfPaymentURL': downloadUrl, // URL dari Cloudinary
      });

      setState(() {
        _uploadProgress = 1.0; // Selesai
      });

      if (!mounted) return;

      // Tampilkan dialog sukses
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar("Gagal mengirim permintaan: ${e.toString()}");
    } finally {
      if (mounted) {
        // Delay sedikit agar user melihat progress 100% sebelum tertutup
        if (_uploadProgress == 1.0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        setState(() {
          _uploadProgress = null;
        });
      }
    }
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Permintaan Terkirim!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                'Bukti pembayaran untuk paket ${widget.packageName.toUpperCase()} telah dikirim.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 16),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Super Admin akan segera memverifikasi\ndan mengaktifkan akun Anda',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup Dialog
                    Navigator.pop(context); // Kembali dari Upload Screen
                    // Jika perlu kembali lebih jauh, sesuaikan di sini
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('💳 Konfirmasi Pembayaran'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ✨ Payment Info Card
                _buildPaymentInfoCard(formatCurrency),

                const SizedBox(height: 32),

                // ✨ Payment Method Section
                _buildPaymentMethodSection(),

                const SizedBox(height: 32),

                // ✨ Upload Proof Section
                _buildUploadProofSection(),

                const SizedBox(height: 32),

                // ✨ Submit Button
                if (_uploadProgress == null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submitProof,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Konfirmasi & Kirim Bukti',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ] else ...[
                  // Upload Progress
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value:
                              _uploadProgress, // Bisa null untuk indeterminate jika diinginkan
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (_uploadProgress ?? 0) < 1
                                ? const Color(0xFF1B5E20)
                                : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mengupload... ${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // ✨ Help Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.amber[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jangan refresh halaman saat upload sedang berlangsung',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // ✨ Upload Loading Overlay (Optional, jika ingin memblokir layar)
          if (_uploadProgress != null && _uploadProgress! < 1)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          // Jika HTTP request tidak support stream progress,
                          // gunakan null agar loading berputar terus
                          value: null,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF1B5E20),
                          ),
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Memproses...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mengupload ke server',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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

  Widget _buildPaymentInfoCard(NumberFormat formatCurrency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.1),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paket',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.packageName.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatCurrency.format(widget.price),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20), // Sesuaikan primaryColor
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- STREAM BUILDER FIRESTORE ---
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('payment_methods')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Gagal memuat metode pembayaran');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final methods = snapshot.data!.docs;

            if (methods.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Belum ada metode pembayaran tersedia.'),
              );
            }

            return Column(
              children: methods.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String name = data['name'] ?? '';
                final String holder = data['holder'] ?? '';
                final String number = data['number'] ?? '';
                final String type = data['type'] ?? 'BANK';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon & Nama Bank
                      Row(
                        children: [
                          Icon(
                            type == 'QRIS'
                                ? Icons.qr_code_scanner
                                : Icons.account_balance,
                            color: const Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (type == 'QRIS') ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'QRIS / E-Wallet',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ]
                        ],
                      ),
                      const Divider(height: 24),

                      // Detail Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  holder.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  // Agar bisa dicopy manual user
                                  number,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tombol Copy
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: number));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Nomor $name disalin!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, color: Colors.grey),
                            tooltip: 'Salin Nomor',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUploadProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            const Text(
              'Upload Bukti Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_imageBytes != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_imageBytes == null)
                Icon(
                  Icons.image_not_supported_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
              const SizedBox(height: 16),
              ImagePickerWidget(
                onImagePicked: (imageBytes, fileName) {
                  setState(() {
                    _imageBytes = imageBytes;
                    _imageName = fileName;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
