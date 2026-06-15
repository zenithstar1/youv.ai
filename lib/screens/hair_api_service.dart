import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';

class HairApiService {

  static Future<Map<String, dynamic>> analyzeHair({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse(ApiService.hairBaseUrl);
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
  throw Exception('Hair API failed: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      return data;
    } catch (e) {
      throw Exception('Hair analysis error: $e');
    }
  }
}
