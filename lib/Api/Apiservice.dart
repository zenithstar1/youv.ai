import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skin_analysis_model.dart';

class SkinAnalyzeResponse {
  final SkinAnalysisModel analysis;
  final Map<String, dynamic> rawJson;
  final Map<String, dynamic>? symmetryData;

  const SkinAnalyzeResponse({
    required this.analysis,
    required this.rawJson,
    required this.symmetryData,
  });
}

class ApiService {
  // Use live backend endpoints.
  static const String baseUrl = 'https://demo.youv.ai/skinanalysisdashboard/api';
  static const String localBaseUrl = baseUrl;
  static const String liveReportBaseUrl = 'https://demo.youv.ai/skinanalysisdashboard/api';
  static const String skinAnalyzeEndpoint =
      'https://demo.youv.ai/skinanalysisdashboard/api/secondary-analyze-skin';
  static const int maxRetries = 1;
  static const Duration retryDelay = Duration(milliseconds: 500);
  static const Duration requestTimeout = Duration(seconds: 120);
  static const int preferredUploadBytes = 700 * 1024;
  static const int minimumUploadBytes = 250 * 1024;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String> _getBearerToken() async {
    final prefs = await SharedPreferences.getInstance();

    final direct = prefs.getString('_token') ?? '';
    if (direct.trim().isNotEmpty) return direct.trim();

    final userInfoStr = prefs.getString('userInfo') ?? '{}';
    try {
      final userInfo = json.decode(userInfoStr);
      final token = (userInfo is Map) ? (userInfo['token']?.toString() ?? '') : '';
      return token.trim();
    } catch (_) {
      return '';
    }
  }

  /// Analyzes skin from uploaded image bytes (for web)
  /// Retries up to 3 times on failure
  /// Analyzes skin from uploaded image bytes (for web)
  /// Retries up to 3 times on failure
  Future<SkinAnalyzeResponse> analyzeSkinWithImageBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    int attemptCount = 0;
    Exception? lastException;
    Duration nextRetryDelay = retryDelay;
    Uint8List uploadBytes = _optimizeInitialUpload(imageBytes);
    // const List<String> multipartFieldCandidates = ['file[]', 'file', 'file[0]'];
    const String currentFieldName = 'file';

    final effectiveFileName = fileName.trim().isEmpty
        ? 'capture.jpg'
        : fileName.trim();

    while (attemptCount < maxRetries) {
      attemptCount++;
      print('Attempt $attemptCount of $maxRetries.. .');

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(skinAnalyzeEndpoint),
        );

        // final currentFieldName = multipartFieldCandidates[
        //   (attemptCount - 1).clamp(0, multipartFieldCandidates.length - 1)
        // ];

        // Add image file from bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            currentFieldName,
            uploadBytes,
            filename: effectiveFileName,
            contentType: http_parser.MediaType('image', 'jpeg'),
          ),
        );

        final token = await _getBearerToken();
        request.headers.addAll({
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        });
        print('Auth header attached to analyze request: ${token.isNotEmpty}');

        print('Sending request to: $skinAnalyzeEndpoint');
        print('Multipart field: $currentFieldName');
        print('File name: $effectiveFileName');
        print('File size: ${uploadBytes.length} bytes');

        var streamedResponse = await request.send().timeout(
          requestTimeout,
          onTimeout: () {
            throw Exception('Request timeout.  Please try again.');
          },
        );

        var response = await http.Response.fromStream(streamedResponse);

        print('Response status: ${response.statusCode}');
        final responsePreview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        print('Response body: $responsePreview');

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          final analysisPayload = (jsonData['analysis'] is Map<String, dynamic>)
              ? (jsonData['analysis'] as Map<String, dynamic>)
              : jsonData;
          Map<String, dynamic>? symmetryData =
              (analysisPayload['symmetry_data'] is Map)
              ? Map<String, dynamic>.from(
                  (analysisPayload['symmetry_data'] as Map)
                      .cast<String, dynamic>(),
                )
              : null;

          // New backend returns `image_blob_url` instead of embedding base64.
          // Fetch and inject as `image_base64` so existing FaceRatioData parsing works.
          if (symmetryData != null) {
            final existingBase64 =
                symmetryData['image_base64']?.toString() ?? '';
            final blobUrl = symmetryData['image_blob_url']?.toString() ?? '';
            if (existingBase64.isEmpty && blobUrl.isNotEmpty) {
              try {
                final blobRes = await http
                    .get(Uri.parse(blobUrl), headers: {'Accept': '*/*'})
                    .timeout(const Duration(seconds: 30));
                if (blobRes.statusCode == 200) {
                  final raw = blobRes.body.trim();
                  // Blob may contain either a raw data-url/base64 string or JSON.
                  String? extracted;
                  if (raw.startsWith('{')) {
                    try {
                      final parsed = json.decode(raw);
                      if (parsed is Map) {
                        extracted = parsed['image_base64']?.toString();
                      }
                    } catch (_) {}
                  }
                  extracted ??= raw;
                  if (extracted.isNotEmpty) {
                    symmetryData['image_base64'] = extracted;
                  }
                }
              } catch (e) {
                print('⚠️ Failed to fetch symmetry image_blob_url: $e');
              }
            }
          }

          // Parse the model first
          final model = SkinAnalysisModel.fromJson(jsonData);

          // Store analysis_id from model if available
          if (model.analysisId != null && model.analysisId!.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('analysis_id', model.analysisId!);
            print('✅ Stored analysis_id from model: ${model.analysisId}');
          }

          print('✅ Success on attempt $attemptCount');
          return SkinAnalyzeResponse(
            analysis: model,
            rawJson: jsonData,
            symmetryData: symmetryData,
          );
        } else if (response.statusCode == 422) {
          // Don't retry on validation errors
          throw Exception(
            'Invalid image format. Please use a clear face photo.',
          );
        } else if (response.statusCode >= 500) {
          // Server error - retry
          final responseBodyLower = response.body.toLowerCase();
          final isUploadFailure =
              responseBodyLower.contains('failed to upload') ||
              responseBodyLower.contains('file failed to upload');

          if (isUploadFailure) {
            uploadBytes = _compressForRetry(uploadBytes);
            nextRetryDelay = const Duration(milliseconds: 600);
            lastException = Exception(
              'Server upload failed (payload adjusted)',
            );
            print(
              '⚠️ Upload failed on server, retrying with smaller image (${uploadBytes.length} bytes)',
            );
          } else {
            nextRetryDelay = retryDelay;
            lastException = Exception('Server error (${response.statusCode})');
          }

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
          nextRetryDelay = const Duration(milliseconds: 800);
          lastException = Exception('No internet connection');
        } else if (e.toString().contains('TimeoutException') ||
            e.toString().contains('timeout')) {
          nextRetryDelay = const Duration(seconds: 1);
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
        print(
          '⏳ Waiting ${(nextRetryDelay.inMilliseconds / 1000).toStringAsFixed(1)} seconds before retry...',
        );
        await Future.delayed(nextRetryDelay);
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

  Uint8List _optimizeInitialUpload(Uint8List originalBytes) {
    final normalizedBytes = _normalizeToJpeg(originalBytes);
    if (normalizedBytes.length <= preferredUploadBytes) {
      return normalizedBytes;
    }
    return _compressJpegToTarget(
      normalizedBytes,
      targetBytes: preferredUploadBytes,
      maxWidth: 1280,
      startQuality: 85,
      minQuality: 55,
    );
  }

  Uint8List _normalizeToJpeg(Uint8List sourceBytes) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      return sourceBytes;
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
  }

  Uint8List _compressForRetry(Uint8List currentBytes) {
    final nextTarget = (currentBytes.length * 0.7).round().clamp(
      minimumUploadBytes,
      preferredUploadBytes,
    );
    return _compressJpegToTarget(
      currentBytes,
      targetBytes: nextTarget,
      maxWidth: 1080,
      startQuality: 78,
      minQuality: 45,
    );
  }

  Uint8List _compressJpegToTarget(
    Uint8List sourceBytes, {
    required int targetBytes,
    required int maxWidth,
    required int startQuality,
    required int minQuality,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      return sourceBytes;
    }

    img.Image working = decoded;
    if (working.width > maxWidth) {
      working = img.copyResize(working, width: maxWidth);
    }

    Uint8List best = Uint8List.fromList(
      img.encodeJpg(working, quality: startQuality),
    );
    if (best.length <= targetBytes) {
      return best;
    }

    for (int quality = startQuality - 5; quality >= minQuality; quality -= 5) {
      final candidate = Uint8List.fromList(
        img.encodeJpg(working, quality: quality),
      );
      if (candidate.length < best.length) {
        best = candidate;
      }
      if (candidate.length <= targetBytes) {
        return candidate;
      }
    }

    while (working.width > 720) {
      final newWidth = (working.width * 0.85).round();
      working = img.copyResize(working, width: newWidth);
      final candidate = Uint8List.fromList(
        img.encodeJpg(working, quality: minQuality),
      );
      if (candidate.length < best.length) {
        best = candidate;
      }
      if (candidate.length <= targetBytes) {
        return candidate;
      }
    }

    return best;
  }

  /// Get PDF download URL for detailed report
  static Future<Map<String, dynamic>> getReportPdfUrl(String analysisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString('userInfo') ?? '{}';
      final userInfo = json.decode(userInfoStr);
      final token = userInfo['token'] ?? '';

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
      final userInfoStr = prefs.getString('userInfo') ?? '{}';
      final userInfo = json.decode(userInfoStr);
      final token = userInfo['token'] ?? '';

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
      final userInfoStr = prefs.getString('userInfo') ?? '{}';
      final userInfo = json.decode(userInfoStr);
      final token = userInfo['token'] ?? '';

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
      final userInfoStr = prefs.getString('userInfo') ?? '{}';
      final userInfo = json.decode(userInfoStr);
      final token = userInfo['token'] ?? '';

      print('Generating PDF for analysis_id: $analysisId');

      final response = await http.post(
        Uri.parse('$liveReportBaseUrl/generate-pdf-from-analysis/$analysisId'),
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

  /// Send detailed analysis report (WhatsApp + email) after payment.
  /// Uses no-auth endpoints: generate-pdf-from-analysis + send-template-report.
  static Future<Map<String, dynamic>> sendDetailedReport(
    String analysisId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoStr = prefs.getString('userInfo') ?? '{}';
      final userInfo = json.decode(userInfoStr);
      final token = userInfo['token'] ?? '';

      final userName = userInfo['user']?['name'] ?? userInfo['name'] ?? 'User';
      final userPhone = userInfo['user']?['phone'] ?? userInfo['phone'] ?? '';
      final userEmail = userInfo['user']?['email'] ?? userInfo['email'] ?? '';

      print('DEBUG userInfo: $userInfoStr');
      print('DEBUG phone=$userPhone, name=$userName, email=$userEmail');
      print('Starting report send process for analysis_id: $analysisId');

      // Step 1: Generate PDF (no auth required)
      final pdfGenUrl =
          '$liveReportBaseUrl/generate-pdf-from-analysis/$analysisId';
      print('Generate PDF URL: $pdfGenUrl');

      final pdfResponse = await http.post(
        Uri.parse(pdfGenUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Generate PDF response status: ${pdfResponse.statusCode}');
      print('Generate PDF response body: ${pdfResponse.body}');

       if (pdfResponse.statusCode != 200) {
        throw Exception('Failed to generate PDF: ${pdfResponse.statusCode}');
      }

      final pdfData = json.decode(pdfResponse.body);
      final pdfUrl = pdfData['pdf_url'] ?? '';

      if (pdfUrl.isEmpty) {
        throw Exception('PDF URL not returned from server');
      }

      print('✅ PDF generated: $pdfUrl');

      bool whatsappSent = false;
      bool emailSent = false;
      String message = '';

      // Step 2: Send WhatsApp via send-template-report (no auth required)
      if (userPhone.isNotEmpty) {
        try {
          final whatsappUrl =
              //'http://127.0.0.1:8000/api/send-template-report';
              'https://demo.youv.ai/skinanalysisdashboard/api/send-template-report';
          print('WhatsApp send URL: $whatsappUrl');

          final waPayload = {
            'to': userPhone,
            'pdf_url': pdfUrl, // ✅ IMPORTANT
            'value1': userName,
            'value2': 'YouV.ai Team',
          };
          print('DEBUG WhatsApp payload: ${jsonEncode(waPayload)}');

          final waResponse = await http.post(
            Uri.parse(whatsappUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token', // ✅ THIS IS THE FIX
            },
            body: jsonEncode(waPayload),
          );

          print('WhatsApp response status: ${waResponse.statusCode}');
          print('WhatsApp response body: ${waResponse.body}');

          if (waResponse.statusCode == 200) {
            whatsappSent = true;
            print('✅ WhatsApp sent successfully');
          }
        } catch (e) {
          print('WhatsApp send error: $e');
        }
      } else {
        print('⚠️ No phone number found, skipping WhatsApp');
      }

      // Step 3: Send email via send-both (best-effort, may fail if auth expired)
      if (userEmail.isNotEmpty && token.isNotEmpty) {
        try {
          final emailUrl = '$liveReportBaseUrl/analysis/$analysisId/send-both';
          final emailResponse = await http.post(
            Uri.parse(emailUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'analysis_id': analysisId}),
          );

          if (emailResponse.statusCode == 200) {
            final emailData = json.decode(emailResponse.body);
            emailSent = emailData['results']?['email']?['sent'] ?? false;
            print('✅ Email sent: $emailSent');
          } else {
            print('Email send returned ${emailResponse.statusCode} — skipping');
          }
        } catch (e) {
          print('Email send error (non-critical): $e');
        }
      }

      if (whatsappSent || emailSent) {
        message = 'Report sent successfully';
        if (whatsappSent && emailSent) {
          message = 'Report sent to WhatsApp and Email';
        } else if (whatsappSent) {
          message = 'Report sent to WhatsApp';
        } else {
          message = 'Report sent to Email';
        }
      } else {
        message = 'PDF generated but could not send via WhatsApp or Email';
      }

      return {
        'success': whatsappSent || emailSent,
        'message': message,
        'email_sent': emailSent,
        'whatsapp_sent': whatsappSent,
        'data': {'pdf_url': pdfUrl},
      };
    } catch (e) {
      print('❌ Error in sendDetailedReport: $e');
      return {'success': false, 'message': 'Error sending report: $e'};
    }
  }
}
