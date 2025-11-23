import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // Pastikan import ini ada

class QrisService {
  final String cloudName = "dnw2t61ne";
  final String uploadPreset = "pos_umkm_preset";

  // UBAH parameter dari File menjadi XFile
  Future<String?> uploadQrisToCloudinary(XFile imageFile) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;

    // PERBAIKAN: Gunakan fromBytes agar kompatibel dengan Web & Mobile
    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name,
    ));

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
