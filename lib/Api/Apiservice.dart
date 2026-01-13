import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skin_analysis_model.dart';

class ApiService {
  static const String baseUrl =
      'https://aestheticai.globalspace.in/youvai/youvai_bodycraft/public/api';
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Analyzes skin from uploaded image bytes (for web)
  /// Retries up to 3 times on failure
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
      print('Attempt $attemptCount of $maxRetries.. .');

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/secondary-analyze-skin'),
        );

        // Add image file from bytes
        request.files.add(
          http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
        );

        request.headers.addAll({'Accept': 'application/json'});

        print('Sending request to: $baseUrl/analyze');
        print('File name: $fileName');
        print('File size: ${imageBytes.length} bytes');

        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw Exception('Request timeout.  Please try again.');
          },
        );

        var response = await http.Response.fromStream(streamedResponse);

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);

          // Parse the model first
          final model = SkinAnalysisModel.fromJson(jsonData);

          // Store analysis_id from model if available
          if (model.analysisId != null && model.analysisId!.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('analysis_id', model.analysisId!);
            print('✅ Stored analysis_id from model: ${model.analysisId}');
          }

          print('✅ Success on attempt $attemptCount');
          return model;
        } else if (response.statusCode == 422) {
          // Don't retry on validation errors
          throw Exception(
            'Invalid image format. Please use a clear face photo.',
          );
        } else if (response.statusCode >= 500) {
          // Server error - retry
          lastException = Exception('Server error (${response.statusCode})');
          print(
            '⚠️ Server error on attempt $attemptCount:  ${response.statusCode}',
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
          lastException = Exception('Error:  ${e.toString()}');
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
      'Last error: ${lastException?.toString().replaceAll('Exception:  ', '')}',
    );
  }

  /// Get PDF download URL for detailed report
  static Future<Map<String, dynamic>> getReportPdfUrl(String analysisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      if (token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/analysis/$analysisId/pdf'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'pdf_url': responseData['pdf_url'] ?? '',
          'data': responseData,
        };
      } else {
        throw Exception('Failed to get PDF URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting PDF URL: $e');
      return {'success': false, 'message': 'Error getting PDF:  $e'};
    }
  }

  /// Download PDF report as bytes (for web download)
  static Future<Uint8List?> downloadReportPdf(String analysisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      if (token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/analysis/$analysisId/download-pdf'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updatePolicyAcceptance(
    bool accepted,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      if (token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/accept-policy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update policy acceptance: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating policy acceptance: $e');
    }
  }

  /// Generate PDF from analysis before sending
  static Future<Map<String, dynamic>> generatePdfFromAnalysis(
    String analysisId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      print('Generating PDF for analysis_id: $analysisId');

      final response = await http.post(
        Uri.parse('$baseUrl/generate-pdf-from-analysis/$analysisId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Generate PDF response status: ${response.statusCode}');
      print('Generate PDF response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'PDF generated successfully',
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ??
              'Failed to generate PDF:  ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error generating PDF: $e');
      return {'success': false, 'message': 'Error generating PDF: $e'};
    }
  }

  /// Send detailed analysis report via email after payment
  /// First generates PDF, then sends it
  static Future<Map<String, dynamic>> sendDetailedReport(
    String analysisId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      if (token.isEmpty) {
        throw Exception('User not authenticated');
      }

      print(
        'Starting report generation and sending process for analysis_id: $analysisId',
      );

      // Step 1: Generate PDF first
      print('Step 1: Generating PDF.. .');
      final generateResult = await generatePdfFromAnalysis(analysisId);

      if (generateResult['success'] != true) {
        print('❌ PDF generation failed: ${generateResult['message']}');
        return {
          'success': false,
          'message': 'Failed to generate report:  ${generateResult['message']}',
        };
      }

      print('✅ PDF generated successfully');

      // Step 2: Send the report via email/WhatsApp
      print('Step 2: Sending report to email/WhatsApp...');
      final response = await http.post(
        Uri.parse('$baseUrl/analysis/$analysisId/send-both'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Send report response status: ${response.statusCode}');
      print('Send report response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract email and WhatsApp results
        final results = responseData['results'];
        final emailSent = results?['email']?['sent'] ?? false;
        final emailMessage = results?['email']?['message'] ?? '';
        final whatsappSent = results?['whatsapp']?['sent'] ?? false;
        final whatsappMessage = results?['whatsapp']?['message'] ?? '';

        // Build user-friendly message
        String userMessage =
            responseData['message'] ?? 'Report sent successfully';

        if (emailSent && whatsappSent) {
          userMessage = 'PDF sent to Email and WhatsApp\n$emailMessage';
        } else if (emailSent) {
          userMessage = 'PDF sent to Email\n$emailMessage';
        } else if (whatsappSent) {
          userMessage = 'PDF sent to WhatsApp\n$whatsappMessage';
        } else {
          userMessage =
              'Report generated but delivery failed.  Please contact support.';
        }

        print('✅ Report sent successfully');

        return {
          'success': true,
          'message': userMessage,
          'email_sent': emailSent,
          'whatsapp_sent': whatsappSent,
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to send report: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error in sendDetailedReport: $e');
      return {'success': false, 'message': 'Error sending report: $e'};
    }
  }
}
