// lib/features/core/subscription_expired_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/widgets/custom_button.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_off_outlined,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                "Langganan Habis",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Masa berlaku langganan Anda telah habis. Silakan hubungi Super Admin untuk memperpanjang.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              CustomButton(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                },
                text: "Logout",
              ),
            ],
          ),
        ),
      ),
    );
  }
}