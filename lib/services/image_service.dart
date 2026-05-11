import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageService {
  static const String imgbbApiKey = 'e514c3db94fa820ebef86564d6bdba80';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = jsonDecode(responseData);
        return jsonResult['data']['url'];
      }
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
    }
    return null;
  }
}
