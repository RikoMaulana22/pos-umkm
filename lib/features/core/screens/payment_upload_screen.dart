// lib/features/core/screens/payment_upload_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../../inventory/widgets/image_picker_widget.dart';
import '../../auth/widgets/custom_button.dart';
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
  double? _uploadProgress; // null = idle, 0-1 = uploading

  Future<void> _submitProof() async {
    if (_imageBytes == null || _imageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Harap upload bukti pembayaran terlebih dahulu."),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _uploadProgress = 0.0;
    });

    try {
      // 1. Upload Gambar ke Firebase Storage
      final String fileName =
          'payment_proofs/${widget.storeId}/${DateTime.now().millisecondsSinceEpoch}-${_imageName!}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      final uploadTask = ref.putData(_imageBytes!, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Buat Dokumen di 'upgradeRequests'
      await FirebaseFirestore.instance.collection('upgradeRequests').add({
        'storeId': widget.storeId,
        'packageName': widget.packageName,
        'price': widget.price,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'proofOfPaymentURL': downloadUrl,
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
                Navigator.pop(context); // Kembali ke layar paket
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      String message = "Upload Gagal: ";
      switch (e.code) {
        case 'storage/unauthorized':
          message += "Anda tidak memiliki izin.";
          break;
        case 'storage/canceled':
          message += "Upload dibatalkan.";
          break;
        case 'storage/retry-limit-exceeded':
          message += "Waktu habis, koneksi buruk. Coba lagi.";
          break;
        default:
          message += "Terjadi error jaringan. Coba lagi nanti.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal mengirim permintaan: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _uploadProgress = null;
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
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/qris_dana.jpg',
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
                ImagePickerWidget(
                  onImagePicked: (imageBytes, fileName) {
                    setState(() {
                      _imageBytes = imageBytes;
                      _imageName = fileName;
                    });
                  },
                ),
                const SizedBox(height: 32),
                if (_uploadProgress != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                CustomButton(
                  onTap: _uploadProgress != null ? null : _submitProof,
                  text: _uploadProgress != null
                      ? "Mengupload... (${(_uploadProgress! * 100).toStringAsFixed(0)}%)"
                      : "Konfirmasi & Kirim Bukti",
                )
              ],
            ),
          ),
          if (_uploadProgress != null &&
              _uploadProgress! < 1) // Tampilkan overlay saat upload
            Container(
              // Perbaikan: withOpacity -> withAlpha
              color: Colors.black.withAlpha(128),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
