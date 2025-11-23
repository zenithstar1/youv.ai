import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/skin_analysis_model.dart';

class ApiService {
  static const String baseUrl = 'https://anujakkulkarni-hydration.hf.space';
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Analyzes skin from uploaded image bytes (for web)
  /// Retries up to 3 times on failure
  Future<SkinAnalysisModel> analyzeSkinWithImageBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    int attemptCount = 0;
    Exception? lastException;

    while (attemptCount < maxRetries) {
      attemptCount++;
      print('Attempt $attemptCount of $maxRetries...');

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/analyze'),
        );

        // Add image file from bytes
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: fileName),
        );

        request.headers.addAll({'Accept': 'application/json'});

        print('Sending request to: $baseUrl/analyze');
        print('File name: $fileName');
        print('File size: ${imageBytes.length} bytes');

        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw Exception('Request timeout. Please try again.');
          },
        );

        var response = await http.Response.fromStream(streamedResponse);

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          print('✅ Success on attempt $attemptCount');
          return SkinAnalysisModel.fromJson(jsonData);
        } else if (response.statusCode == 422) {
          // Don't retry on validation errors
          throw Exception(
            'Invalid image format. Please use a clear face photo.',
          );
        } else if (response.statusCode >= 500) {
          // Server error - retry
          lastException = Exception('Server error (${response.statusCode})');
          print(
            '⚠️ Server error on attempt $attemptCount: ${response.statusCode}',
          );
        } else {
          // Client error - don't retry
          throw Exception(
            'Failed to analyze image. Status: ${response.statusCode}',
          );
        }
      } catch (e) {
        print('❌ Error on attempt $attemptCount: $e');

        if (e.toString().contains('SocketException')) {
          lastException = Exception('No internet connection');
        } else if (e.toString().contains('TimeoutException') ||
            e.toString().contains('timeout')) {
          lastException = Exception('Request timeout');
        } else if (e.toString().contains('Invalid image format') ||
            e.toString().contains('422')) {
          // Don't retry validation errors
          rethrow;
        } else {
          lastException = Exception('Error: ${e.toString()}');
        }
      }

      // Wait before retrying (except on last attempt)
      if (attemptCount < maxRetries) {
        print('⏳ Waiting ${retryDelay.inSeconds} seconds before retry...');
        await Future.delayed(retryDelay);
      }
    }

    // All attempts failed
    print('❌ All $maxRetries attempts failed');
    throw Exception(
      'Server is busy. Please try again later.\n\n'
      'We attempted $maxRetries times but couldn\'t process your request.\n'
      'Last error: ${lastException?.toString().replaceAll('Exception: ', '')}',
    );
  }
}
