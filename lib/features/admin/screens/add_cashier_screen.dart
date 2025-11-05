// lib/features/admin/screens/add_cashier_screen.dart
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import '../../../shared/theme.dart';

class AddCashierScreen extends StatefulWidget {
  final String storeId;
  const AddCashierScreen({super.key, required this.storeId});

  @override
  State<AddCashierScreen> createState() => _AddCashierScreenState();
}

class _AddCashierScreenState extends State<AddCashierScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void createCashier() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Semua field harus diisi"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await _authService.createCashier(
        email: emailController.text,
        password: passwordController.text,
        username: usernameController.text,
        storeId: widget.storeId,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Kasir baru berhasil dibuat!"),
          backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal membuat kasir: ${e.toString()}"),
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
        title: const Text('Tambah Akun Kasir'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CustomTextField(
                    controller: usernameController, hintText: "Nama Kasir"),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: emailController, hintText: "Email Kasir"),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: passwordController,
                    hintText: "Password Baru",
                    obscureText: true),
                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : createCashier,
                  text: "Simpan Kasir",
                ),
              ],
            ),
          ),
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