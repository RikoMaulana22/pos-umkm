import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QrisService {
  final String cloudName =
      "dnw2t61ne"; // <- Ganti dengan cloud name Cloudinary kamu
  final String uploadPreset =
      "pos_umkm_preset"; // <- Ganti dengan upload preset Cloudinary kamu

  Future<String?> uploadQrisToCloudinary(File imageFile) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);
      return data['secure_url'] as String?;
    }
    return null;
  }

  Future<void> saveQrisUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('qris_image_url', url);
  }

  Future<String?> loadQrisUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('qris_image_url');
  }
}
