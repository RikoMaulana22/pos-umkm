// lib/shared/widgets/curved_header_clipper.dart
import 'package:flutter/material.dart';

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    
    // Mulai dari kiri atas
    path.lineTo(0, size.height - 40); // Turun di sisi kiri

    // Ini adalah lekukan cekung di tengah
    path.quadraticBezierTo(
      size.width / 2, // Titik kontrol di tengah
      size.height + 40, // Titik kontrol di bawah (membuatnya cekung)
      size.width,     // Titik akhir di kanan
      size.height - 40  // Titik akhir di sisi kanan
    );

    // Naik ke kanan atas
    path.lineTo(size.width, 0);
    path.close(); // Tutup path
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}