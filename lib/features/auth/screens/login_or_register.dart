// lib/features/auth/screens/login_or_register.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginScreen(onRegisterTap: togglePages);
    } else {
      return RegisterScreen(onLoginTap: togglePages);
    }
  }
}