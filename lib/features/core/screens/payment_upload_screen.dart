// lib/features/core/screens/payment_upload_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../../inventory/widgets/image_picker_widget.dart';
import '../../auth/widgets/custom_button.dart';
// 1. Impor service untuk upload
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _isLoading = false;

  Future<void> _submitProof() async {
    if (_imageBytes == null || _imageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Harap upload bukti pembayaran terlebih dahulu."),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload Gambar ke Firebase Storage
      final String fileName =
          'payment_proofs/${widget.storeId}/${DateTime.now().millisecondsSinceEpoch}-${_imageName!}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(_imageBytes!, metadata);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Buat Dokumen di 'upgradeRequests' (seperti sebelumnya)
      await FirebaseFirestore.instance.collection('upgradeRequests').add({
        'storeId': widget.storeId,
        'packageName': widget.packageName,
        'price': widget.price,
        'status': 'pending', // Status awal
        'requestedAt': FieldValue.serverTimestamp(),
        'proofOfPaymentURL': downloadUrl, // <-- URL GAMBAR BUKTI
      });

      if (!mounted) return;
      // Tampilkan dialog sukses
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Permintaan Terkirim"),
          content: Text(
              "Bukti pembayaran Anda untuk paket ${widget.packageName} telah dikirim. Super Admin akan segera memverifikasi dan mengaktifkan akun Anda."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke layar expired
                Navigator.pop(context); // Kembali ke layar login (opsional)
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal mengirim permintaan: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Pembayaran Paket ${widget.packageName}"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Silakan lakukan pembayaran ke:",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Tampilkan Gambar QRIS
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/qris_dana.jpg', //
                      width: 250,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text("Total Pembayaran",
                      style: TextStyle(fontSize: 18)),
                  trailing: Text(
                    formatCurrency.format(widget.price),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  "Upload Bukti Pembayaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Gunakan ImagePickerWidget yang sudah ada
                ImagePickerWidget(
                  onImagePicked: (imageBytes, fileName) {
                    setState(() {
                      _imageBytes = imageBytes;
                      _imageName = fileName;
                    });
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _submitProof,
                  text: "Konfirmasi & Kirim Bukti",
                )
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
