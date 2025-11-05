// lib/features/auth/widgets/custom_textfield.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. IMPOR INI

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType; // <-- 2. TAMBAHKAN INI
  final List<TextInputFormatter>? inputFormatters; // <-- 3. TAMBAHKAN INI

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType, // <-- 4. TAMBAHKAN INI
    this.inputFormatters, // <-- 5. TAMBAHKAN INI
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType, // <-- 6. TAMBAHKAN INI
        inputFormatters: inputFormatters, // <-- 7. TAMBAHKAN INI
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.grey.shade100,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}