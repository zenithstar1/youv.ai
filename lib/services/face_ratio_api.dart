import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:skin_analysis_app/Models/FaceRatioLine.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';

class FaceRatioApi {
  FaceRatioApi({
    String? baseUrl,
    this.hfToken,
  }) : baseUrl = baseUrl ?? ApiService.faceRatioBaseUrl;

  final String baseUrl;
  final String? hfToken;

  Future<FaceRatioData?> analyzeByImageUrl(
    String imageUrl, {
    bool draw = false,
  }) async {
    // Download → reupload as multipart under key "file"
    try {
      final imgRes = await http.get(Uri.parse(imageUrl));
      if (imgRes.statusCode != 200) return null;
      return analyzeByBytes(
        imgRes.bodyBytes,
        filename: 'image.jpg',
        draw: draw,
      );
    } catch (_) {
      return null;
    }
  }

  Future<FaceRatioData?> analyzeByBytes(
    Uint8List bytes, {
    String filename = 'upload.jpg',
    bool draw = false,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze?draw=${draw ? 1 : 0}');
    final req = http.MultipartRequest('POST', uri);

    if (hfToken != null && hfToken!.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $hfToken';
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      return FaceRatioData.fromMap(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    return null;
  }
}
