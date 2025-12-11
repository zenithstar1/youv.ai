import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';
import 'package:skin_analysis_app/screens/LoginPage.dart';
import '../models/skin_analysis_model.dart';
import '../widgets/analysis_point.dart';
import '../widgets/score_card.dart' hide FactorItem;
import '../widgets/info_pill.dart';
import '../widgets/color_circle.dart';
import 'package:http/http.dart' as http;

class SkinAnalysisScreen extends StatefulWidget {
  final SkinAnalysisModel? analysisData;
  final Uint8List? imageBytes;

  const SkinAnalysisScreen({Key? key, this.analysisData, this.imageBytes})
    : super(key: key);

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen> {
  late int selectedColorIndex;

  // Payment & Coupon variables
  bool _hasPaid = false;
  String paymentStatus = "";
  TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;
  bool _couponChecking = false;
  String _couponError = "";
  String _appliedCoupon = "";
  // Remove:  bool _reportSent = false;
  // Keep only:
  bool _sendingReport = false;
  String _reportMessage = '';
  bool _reportSent = false;

  final List<Color> fitzpatrickColors = [
    const Color(0xFFFFF5F0),
    const Color(0xFFFFE4D6),
    const Color(0xFFE8B896),
    const Color(0xFFD4A574),
    const Color(0xFFAE7E5C),
    const Color(0xFF6B4423),
  ];

  Future<void> _sendDetailedReport() async {
    final prefs = await SharedPreferences.getInstance();
    final analysisId = prefs.getString('analysis_id');

    if (analysisId == null || analysisId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No analysis found.  Please analyze your skin first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _sendingReport = true;
      _reportMessage = '';
    });

    try {
      final result = await ApiService.sendDetailedReport(analysisId);

      setState(() {
        _sendingReport = false;
        _reportSent = result['success'] == true;
        _reportMessage = result['message'] ?? '';
      });

      if (result['success'] == true) {
        // Show success with detailed message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Text('Report Sent! '),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['message'] ?? 'PDF sent successfully',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Check your email for the detailed PDF report.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _sendingReport = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error:  ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPdfReport() async {
    final prefs = await SharedPreferences.getInstance();
    final analysisId = prefs.getString('analysis_id');

    if (analysisId == null || analysisId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No analysis found. Please analyze your skin first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading PDF report...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final pdfBytes = await ApiService.downloadReportPdf(analysisId);

      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        // For web:  Create download link
        if (kIsWeb) {
          final blob = html.Blob([pdfBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = 'skin_analysis_report_$analysisId.pdf';
          html.document.body?.children.add(anchor);
          anchor.click();
          html.document.body?.children.remove(anchor);
          html.Url.revokeObjectUrl(url);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    selectedColorIndex = (widget.analysisData?.fitzpatrickType ?? 1) - 1;
    checkSubscriptionStatus();

    if (kIsWeb) {
      js.context['flutterPaymentSuccess'] = (String paymentId) {
        setState(() {
          paymentStatus = "Payment Successful:  $paymentId";
          _hasPaid = true;
        });
        _handlePaymentSuccess(paymentId);
      };
      js.context['flutterPaymentError'] = (String paymentId) {
        setState(() {
          paymentStatus = "Payment Failed: $paymentId";
        });
        _handlePaymentError(paymentId);
      };
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('isSubscribe') ?? false;
    setState(() {
      _hasPaid = isSubscribed;
    });
  }

  void _handlePaymentSuccess(String paymentId) async {
    final paymentData = {
      "payment_id": paymentId,
      "amount": 499.00,
      "currency": "INR",
      "status": "completed",
      "payment_method": "razorpay",
      "description": "Unlock Full Report",
      "metadata": {"order_id": paymentId, "customer_id": ""},
      "transaction_reference": paymentId,
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      prefs.setBool('isSubscribe', true);
      final uri = Uri.parse(
        'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/payment/store',
      );
      await http.post(
        uri,
        body: jsonEncode(paymentData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print("Error storing payment data: $e");
    }

    setState(() {
      _hasPaid = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment successful! Details unlocked."),
        backgroundColor: Colors.green,
      ),
    );

    // Automatically send detailed report after successful payment
    _sendDetailedReport();
  }

  void _handlePaymentError(paymentId) async {
    final paymentData = {
      "payment_id": paymentId ?? "",
      "amount": 499.00,
      "currency": "INR",
      "status": "Failed",
      "payment_method": "razorpay",
      "description": "Unlock Full Report",
      "metadata": {"order_id": paymentId ?? "", "customer_id": ""},
      "transaction_reference": paymentId ?? "",
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      final uri = Uri.parse(
        'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/payment/store',
      );
      await http.post(
        uri,
        body: jsonEncode(paymentData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print("Error storing payment data: $e");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment failed or cancelled. Please try again."),
      ),
    );
  }

  void _startPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLogin') ?? false;

    if (!isLoggedIn) {
      // Navigate to login page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      // If login was successful, check subscription and send report
      if (result == true) {
        final updatedPrefs = await SharedPreferences.getInstance();
        final isSubscribed = updatedPrefs.getBool('isSubscribe') ?? false;

        if (!isSubscribed) {
          // Proceed with payment after successful login
          _proceedWithPayment();
        } else {
          setState(() {
            _hasPaid = true;
          });
          // Auto-send report after login if already subscribed
          _sendDetailedReport();
        }
      }
      return;
    }

    final isSubscribed = prefs.getBool('isSubscribe') ?? false;
    if (isSubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already have access to the report.")),
      );
      setState(() {
        _hasPaid = true;
      });
      // Auto-send report if already subscribed
      _sendDetailedReport();
      return;
    }

    // If coupon is applied, unlock and send report
    if (_couponApplied) {
      prefs.setBool('isSubscribe', true);
      setState(() {
        _hasPaid = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Coupon applied!  Details unlocked."),
          backgroundColor: Colors.green,
        ),
      );

      // Automatically send detailed report after coupon unlock
      _sendDetailedReport();
      return;
    }

    // Otherwise proceed with payment
    _proceedWithPayment();
  }

  void _proceedWithPayment() async {
    final prefs = await SharedPreferences.getInstance();

    String name = '';
    String email = '';
    String number = '';

    final userInfoJson = prefs.getString('userInfo');
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      final userInfo = json.decode(userInfoJson);
      name = userInfo['name'] ?? '';
      email = userInfo['email'] ?? '';
      number = userInfo['phone'] ?? '';
    } else {
      name = prefs.getString('name') ?? '';
      email = prefs.getString('email') ?? '';
      number = prefs.getString('number') ?? '';
    }

    js.context.callMethod('openRazorpayCheckout', [
      "order_id_placeholder",
      "rzp_live_jBXpBOtKrydrbs",
      "49900",
      name,
      email,
      number,
    ]);
  }

  Future<void> _applyCoupon() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLogin') ?? false;

    if (!isLoggedIn) {
      // Navigate to login page
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      // If login was successful, try applying coupon again
      if (result == true) {
        _applyCoupon();
      }
      return;
    }

    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponError = "Please enter a coupon code. ";
      });
      return;
    }

    setState(() {
      _couponChecking = true;
      _couponError = "";
    });

    try {
      // final token = prefs.getString('_token') ?? '';
      // final response = await http.post(
      //   Uri.parse(
      //     'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/coupon/verify',
      //   ),
      //   body: jsonEncode({"coupon_code": code}),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      // );

      // final body = jsonDecode(response.body);

      if (code == "YOUV2025") {
        setState(() {
          _couponApplied = true;
          _appliedCoupon = code;
          _couponError = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coupon applied!  Payment skipped.")),
        );
      } else {
        setState(() {
          _couponError = code.isEmpty ? "Invalid coupon. " : code;
          _couponApplied = false;
          _appliedCoupon = "";
        });
      }
    } catch (e) {
      setState(() {
        _couponError = "Error validating coupon. ";
        _couponApplied = false;
        _appliedCoupon = "";
      });
    } finally {
      setState(() {
        _couponChecking = false;
      });
    }
  }

  List<FactorItem> _getAcneFactors() {
    if (widget.analysisData == null) return [];
    return [
      FactorItem(
        name: 'Active Acne',
        value: widget.analysisData!.acneFactors.activeAcne,
      ),
      FactorItem(
        name: 'Comedones',
        value: widget.analysisData!.acneFactors.comedones,
      ),
      FactorItem(
        name: 'Congestion',
        value: widget.analysisData!.acneFactors.congestion,
      ),
      FactorItem(
        name: 'Cystic Acne',
        value: widget.analysisData!.acneFactors.cysticAcne,
      ),
      FactorItem(
        name: 'Inflammation',
        value: widget.analysisData!.acneFactors.inflammation,
      ),
      FactorItem(
        name: 'Oiliness',
        value: widget.analysisData!.acneFactors.oiliness,
      ),
      FactorItem(
        name: 'Scarring',
        value: widget.analysisData!.acneFactors.scarring,
      ),
    ];
  }

  List<FactorItem> _getHydrationFactors() {
    if (widget.analysisData == null) return [];
    return [
      FactorItem(
        name: 'Fine Lines',
        value: widget.analysisData!.hydrationFactors.fineLines,
      ),
      FactorItem(
        name: 'Flakiness',
        value: widget.analysisData!.hydrationFactors.flakiness,
      ),
      FactorItem(
        name: 'Oil Balance',
        value: widget.analysisData!.hydrationFactors.oilBalance,
      ),
      FactorItem(
        name: 'Radiance',
        value: widget.analysisData!.hydrationFactors.radiance,
      ),
      FactorItem(
        name: 'Texture',
        value: widget.analysisData!.hydrationFactors.texture,
      ),
    ];
  }

  List<FactorItem> _getPigmentationFactors() {
    if (widget.analysisData == null) return [];
    return [
      FactorItem(
        name: 'Dark Spots',
        value: widget.analysisData!.pigmentationFactors.darkSpots,
      ),
      FactorItem(
        name: 'Hyperpigmentation',
        value: widget.analysisData!.pigmentationFactors.hyperpigmentation,
      ),
      FactorItem(
        name: 'Melanin Unevenness',
        value: widget.analysisData!.pigmentationFactors.melaninUnevenness,
      ),
      FactorItem(
        name: 'Overall Evenness',
        value: widget.analysisData!.pigmentationFactors.overallEvenness,
      ),
      FactorItem(
        name: 'Redness',
        value: widget.analysisData!.pigmentationFactors.redness,
      ),
      FactorItem(
        name: 'Under Eye Pigmentation',
        value: widget.analysisData!.pigmentationFactors.underEyePigmentation,
      ),
      FactorItem(
        name: 'UV Damage',
        value: widget.analysisData!.pigmentationFactors.uvDamage,
      ),
    ];
  }

  List<FactorItem> _getPoresFactors() {
    if (widget.analysisData == null) return [];
    return [
      FactorItem(
        name: 'Visibility',
        value: widget.analysisData!.poresFactors.visibility,
      ),
      FactorItem(name: 'Size', value: widget.analysisData!.poresFactors.size),
      FactorItem(
        name: 'Enlarged Pores',
        value: widget.analysisData!.poresFactors.enlargedPores,
      ),
      FactorItem(
        name: 'Clogged Pores',
        value: widget.analysisData!.poresFactors.cloggedPores,
      ),
      FactorItem(
        name: 'T-Zone Prominence',
        value: widget.analysisData!.poresFactors.tZoneProminence,
      ),
      FactorItem(
        name: 'Cheek Prominence',
        value: widget.analysisData!.poresFactors.cheekProminence,
      ),
      FactorItem(
        name: 'Texture Roughness',
        value: widget.analysisData!.poresFactors.textureRoughness,
      ),
    ];
  }

  List<FactorItem> _getWrinklesFactors() {
    if (widget.analysisData == null) return [];
    return [
      FactorItem(
        name: 'Overall Severity',
        value: widget.analysisData!.wrinklesFactors.overallSeverity,
      ),
      FactorItem(
        name: 'Depth',
        value: widget.analysisData!.wrinklesFactors.depth,
      ),
      FactorItem(
        name: 'Forehead Lines',
        value: widget.analysisData!.wrinklesFactors.foreheadLines,
      ),
      FactorItem(
        name: 'Crows Feet',
        value: widget.analysisData!.wrinklesFactors.crowsFeet,
      ),
      FactorItem(
        name: 'Frown Lines',
        value: widget.analysisData!.wrinklesFactors.frownLines,
      ),
      FactorItem(
        name: 'Nasolabial Folds',
        value: widget.analysisData!.wrinklesFactors.nasolabialFolds,
      ),
      FactorItem(
        name: 'Under Eye Wrinkles',
        value: widget.analysisData!.wrinklesFactors.underEyeWrinkles,
      ),
      FactorItem(
        name: 'Lip Lines',
        value: widget.analysisData!.wrinklesFactors.lipLines,
      ),
      FactorItem(
        name: 'Marionette Lines',
        value: widget.analysisData!.wrinklesFactors.marionelleLines,
      ),
      FactorItem(
        name: 'Neck Lines',
        value: widget.analysisData!.wrinklesFactors.neckLines,
      ),
      FactorItem(
        name: 'Static Wrinkles',
        value: widget.analysisData!.wrinklesFactors.staticWrinkles,
      ),
      FactorItem(
        name: 'Dynamic Wrinkles',
        value: widget.analysisData!.wrinklesFactors.dynamicWrinkles,
      ),
    ];
  }

  // Enhanced calculation with 5 factors
  double _calculateOverallScore() {
    if (widget.analysisData == null) return 0;

    final acneDetailScore = _calculateAcneDetailScore();
    final hydrationDetailScore = _calculateHydrationDetailScore();
    final pigmentationDetailScore = _calculatePigmentationDetailScore();
    final poresDetailScore = _calculatePoresDetailScore();
    final wrinklesDetailScore = _calculateWrinklesDetailScore();
    final agingScore = _calculateAgingScore(
      (widget.analysisData!.skinAge + widget.analysisData!.eyeAge) / 2,
    );

    // Updated weights (total = 100%)
    const double acneWeight = 0.25; // 25%
    const double hydrationWeight = 0.20; // 20%
    const double pigmentationWeight = 0.20; // 20%
    const double poresWeight = 0.15; // 15%
    const double wrinklesWeight = 0.15; // 15%
    const double agingWeight = 0.05; // 5%

    final totalScore =
        (acneDetailScore * acneWeight) +
        (hydrationDetailScore * hydrationWeight) +
        (pigmentationDetailScore * pigmentationWeight) +
        (poresDetailScore * poresWeight) +
        (wrinklesDetailScore * wrinklesWeight) +
        (agingScore * agingWeight);

    print('=== Attractiveness Score Breakdown ===');
    print(
      'Acne:  ${acneDetailScore.toStringAsFixed(2)} × 25% = ${(acneDetailScore * acneWeight).toStringAsFixed(2)}',
    );
    print(
      'Hydration: ${hydrationDetailScore.toStringAsFixed(2)} × 20% = ${(hydrationDetailScore * hydrationWeight).toStringAsFixed(2)}',
    );
    print(
      'Pigmentation: ${pigmentationDetailScore.toStringAsFixed(2)} × 20% = ${(pigmentationDetailScore * pigmentationWeight).toStringAsFixed(2)}',
    );
    print(
      'Pores:  ${poresDetailScore.toStringAsFixed(2)} × 15% = ${(poresDetailScore * poresWeight).toStringAsFixed(2)}',
    );
    print(
      'Wrinkles: ${wrinklesDetailScore.toStringAsFixed(2)} × 15% = ${(wrinklesDetailScore * wrinklesWeight).toStringAsFixed(2)}',
    );
    print(
      'Aging: ${agingScore.toStringAsFixed(2)} × 5% = ${(agingScore * agingWeight).toStringAsFixed(2)}',
    );
    print('Final Score: ${totalScore.toStringAsFixed(2)}%');
    print('=====================================');

    return totalScore.clamp(0.0, 100.0);
  }

  double _calculateAcneDetailScore() {
    final factors = widget.analysisData!.acneFactors;

    final activeAcneScore = (1 - factors.activeAcne) * 100;
    final comedonesScore = (1 - factors.comedones) * 100;
    final congestionScore = (1 - factors.congestion) * 100;
    final cysticScore = (1 - factors.cysticAcne) * 100;
    final inflammationScore = (1 - factors.inflammation) * 100;
    final oilinessScore = (1 - factors.oiliness) * 100;
    final scarringScore = (1 - factors.scarring) * 100;

    const weights = {
      'activeAcne': 0.25,
      'cysticAcne': 0.20,
      'inflammation': 0.15,
      'scarring': 0.15,
      'comedones': 0.10,
      'congestion': 0.10,
      'oiliness': 0.05,
    };

    return (activeAcneScore * weights['activeAcne']!) +
        (comedonesScore * weights['comedones']!) +
        (congestionScore * weights['congestion']!) +
        (cysticScore * weights['cysticAcne']!) +
        (inflammationScore * weights['inflammation']!) +
        (oilinessScore * weights['oiliness']!) +
        (scarringScore * weights['scarring']!);
  }

  double _calculateHydrationDetailScore() {
    final factors = widget.analysisData!.hydrationFactors;

    final fineLinesScore = (1 - factors.fineLines) * 100;
    final flakinessScore = (1 - factors.flakiness) * 100;
    final oilBalanceScore = (1 - factors.oilBalance) * 100;
    final radianceScore = (1 - factors.radiance) * 100;
    final textureScore = (1 - factors.texture) * 100;

    const weights = {
      'radiance': 0.30,
      'texture': 0.25,
      'fineLines': 0.20,
      'oilBalance': 0.15,
      'flakiness': 0.10,
    };

    return (fineLinesScore * weights['fineLines']!) +
        (flakinessScore * weights['flakiness']!) +
        (oilBalanceScore * weights['oilBalance']!) +
        (radianceScore * weights['radiance']!) +
        (textureScore * weights['texture']!);
  }

  double _calculatePigmentationDetailScore() {
    final factors = widget.analysisData!.pigmentationFactors;

    final darkSpotsScore = (1 - factors.darkSpots) * 100;
    final hyperpigmentationScore = (1 - factors.hyperpigmentation) * 100;
    final melaninScore = (1 - factors.melaninUnevenness) * 100;
    final evennessScore = (1 - factors.overallEvenness) * 100;
    final rednessScore = (1 - factors.redness) * 100;
    final underEyeScore = (1 - factors.underEyePigmentation) * 100;
    final uvDamageScore = (1 - factors.uvDamage) * 100;

    const weights = {
      'overallEvenness': 0.25,
      'hyperpigmentation': 0.20,
      'darkSpots': 0.15,
      'melaninUnevenness': 0.15,
      'uvDamage': 0.10,
      'underEyePigmentation': 0.10,
      'redness': 0.05,
    };

    return (darkSpotsScore * weights['darkSpots']!) +
        (hyperpigmentationScore * weights['hyperpigmentation']!) +
        (melaninScore * weights['melaninUnevenness']!) +
        (evennessScore * weights['overallEvenness']!) +
        (rednessScore * weights['redness']!) +
        (underEyeScore * weights['underEyePigmentation']!) +
        (uvDamageScore * weights['uvDamage']!);
  }

  double _calculatePoresDetailScore() {
    final factors = widget.analysisData!.poresFactors;

    final visibilityScore = (1 - factors.visibility) * 100;
    final sizeScore = (1 - factors.size) * 100;
    final enlargedScore = (1 - factors.enlargedPores) * 100;
    final cloggedScore = (1 - factors.cloggedPores) * 100;
    final tZoneScore = (1 - factors.tZoneProminence) * 100;
    final cheekScore = (1 - factors.cheekProminence) * 100;
    final textureScore = (1 - factors.textureRoughness) * 100;

    const weights = {
      'visibility': 0.25,
      'size': 0.20,
      'enlargedPores': 0.20,
      'cloggedPores': 0.15,
      'textureRoughness': 0.10,
      'tZoneProminence': 0.05,
      'cheekProminence': 0.05,
    };

    return (visibilityScore * weights['visibility']!) +
        (sizeScore * weights['size']!) +
        (enlargedScore * weights['enlargedPores']!) +
        (cloggedScore * weights['cloggedPores']!) +
        (tZoneScore * weights['tZoneProminence']!) +
        (cheekScore * weights['cheekProminence']!) +
        (textureScore * weights['textureRoughness']!);
  }

  double _calculateWrinklesDetailScore() {
    final factors = widget.analysisData!.wrinklesFactors;

    final overallScore = (1 - factors.overallSeverity) * 100;
    final depthScore = (1 - factors.depth) * 100;
    final foreheadScore = (1 - factors.foreheadLines) * 100;
    final crowsFeetScore = (1 - factors.crowsFeet) * 100;
    final frownScore = (1 - factors.frownLines) * 100;
    final nasolabialScore = (1 - factors.nasolabialFolds) * 100;
    final underEyeScore = (1 - factors.underEyeWrinkles) * 100;
    final lipScore = (1 - factors.lipLines) * 100;
    final marionetteScore = (1 - factors.marionelleLines) * 100;
    final neckScore = (1 - factors.neckLines) * 100;
    final staticScore = (1 - factors.staticWrinkles) * 100;
    final dynamicScore = (1 - factors.dynamicWrinkles) * 100;

    const weights = {
      'overallSeverity': 0.20,
      'depth': 0.15,
      'nasolabialFolds': 0.12,
      'crowsFeet': 0.10,
      'foreheadLines': 0.10,
      'frownLines': 0.08,
      'underEyeWrinkles': 0.08,
      'lipLines': 0.05,
      'marionetteLines': 0.04,
      'staticWrinkles': 0.04,
      'dynamicWrinkles': 0.02,
      'neckLines': 0.02,
    };

    return (overallScore * weights['overallSeverity']!) +
        (depthScore * weights['depth']!) +
        (foreheadScore * weights['foreheadLines']!) +
        (crowsFeetScore * weights['crowsFeet']!) +
        (frownScore * weights['frownLines']!) +
        (nasolabialScore * weights['nasolabialFolds']!) +
        (underEyeScore * weights['underEyeWrinkles']!) +
        (lipScore * weights['lipLines']!) +
        (marionetteScore * weights['marionetteLines']!) +
        (neckScore * weights['neckLines']!) +
        (staticScore * weights['staticWrinkles']!) +
        (dynamicScore * weights['dynamicWrinkles']!);
  }

  double _calculateAgingScore(double avgAge) {
    if (avgAge >= 20 && avgAge <= 25) {
      return 100.0;
    } else if (avgAge > 25) {
      final penalty = (avgAge - 25) * 2;
      return (100 - penalty).clamp(0.0, 100.0);
    } else {
      final penalty = (20 - avgAge) * 1;
      return (100 - penalty).clamp(0.0, 100.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallScore = _calculateOverallScore();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE8B4BA),
      body: SafeArea(
        bottom: false,
        child: isDesktop
            ? _buildDesktopLayout()
            : _buildMobileLayout(overallScore),
      ),
    );
  }

  Widget _buildMobileLayout(double overallScore) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = constraints.maxHeight;

        return Container(
          color: const Color(0xFFE8B4BA),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with score banner
                Container(
                  color: const Color(0xFFF5E6E8),
                  child: Column(
                    children: [
                      Container(
                        width: screenWidth,
                        margin: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4999F),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Attractiveness Index Score:  ${overallScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Image section (now scrollable)
                      Container(
                        height: screenHeight * 0.42,
                        width: screenWidth,
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              child: widget.imageBytes != null
                                  ? Image.memory(
                                      widget.imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(30),
                                          bottomRight: Radius.circular(30),
                                        ),
                                      ),
                                      child: const Icon(Icons.person, size: 80),
                                    ),
                            ),
                            Positioned(
                              left: 15,
                              top: 20,
                              child: AnalysisPoint(
                                label: 'Pigmentation',
                                value: widget.analysisData!.pigmentationScore
                                    .toStringAsFixed(0),
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                            Positioned(
                              right: 15,
                              top: 60,
                              child: AnalysisPoint(
                                label: 'Hydration',
                                value: widget.analysisData!.hydrationScore
                                    .toStringAsFixed(0),
                                color: const Color(
                                  0xFF9B7653,
                                ).withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section (now part of the scroll)
                Container(
                  width: screenWidth,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8B4BA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -30, 0),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.04,
                      35,
                      screenWidth * 0.04,
                      30,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                          ),
                          child: const Text(
                            'The closer you are to 100, the healthier your skin is.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // First Row - 3 Cards
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.01,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ScoreCard(
                                  score: widget.analysisData!.acneScore
                                      .toStringAsFixed(0),
                                  label: 'Acne',
                                  factors: _getAcneFactors(),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.025),
                              Expanded(
                                child: ScoreCard(
                                  score: widget.analysisData!.hydrationScore
                                      .toStringAsFixed(0),
                                  label: 'Hydration',
                                  factors: _getHydrationFactors(),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.025),
                              Expanded(
                                child: ScoreCard(
                                  score: widget.analysisData!.pigmentationScore
                                      .toStringAsFixed(0),
                                  label: 'Pigmentation',
                                  factors: _getPigmentationFactors(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Second Row - 2 Cards (Centered)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.15,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ScoreCard(
                                  score: widget.analysisData!.poresScore
                                      .toStringAsFixed(0),
                                  label: 'Pores',
                                  factors: _getPoresFactors(),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Expanded(
                                child: ScoreCard(
                                  score: widget.analysisData!.wrinklesScore
                                      .toStringAsFixed(0),
                                  label: 'Wrinkles',
                                  factors: _getWrinklesFactors(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Info Pills
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                          ),
                          child: Wrap(
                            spacing: screenWidth * 0.025,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildLargeInfoPill(
                                'Skin Age:  ${widget.analysisData!.skinAge}',
                              ),
                              _buildLargeInfoPill(
                                'Eye Age: ${widget.analysisData!.eyeAge}',
                              ),
                              _buildLargeInfoPill(
                                'Skin Type:  ${widget.analysisData!.skinType}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Color Palette
                        Wrap(
                          spacing: screenWidth * 0.03,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(6, (index) {
                            return _buildLargeColorCircle(
                              fitzpatrickColors[index],
                              selectedColorIndex == index,
                              () => setState(() => selectedColorIndex = index),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fitzpatrick Type ${selectedColorIndex + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // DISCLAIMER SECTION
                        _buildDisclaimerSection(screenWidth),
                        const SizedBox(height: 20),

                        // PAYMENT/COUPON SECTION
                        _buildPaymentSection(screenWidth),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLargeInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLargeColorCircle(
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isLightColor = color.computeLuminance() > 0.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.black
                : (isLightColor ? Colors.grey[400]! : Colors.white),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: isLightColor ? Colors.black : Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }

  Widget _buildDisclaimerSection(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.yellow.shade700, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Disclaimer",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "• The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and entertainment purposes only.\n\n"
              "• Results do not represent a medical diagnosis, dermatological assessment, or professional beauty advice.\n\n"
              "• Factors such as lighting, camera quality, and environmental conditions may influence the outcome.\n\n"
              "• Users should not rely solely on this analysis for making decisions regarding skincare, medical treatments, or personal wellbeing.\n\n"
              "• For any medical or cosmetic concerns, please consult a qualified healthcare or skincare professional.\n\n"
              "• The Service Provider makes no guarantees regarding accuracy, completeness, or suitability of the AI analysis.",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(double screenWidth) {
    if (!_hasPaid) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text(
                "Unlock Full Details",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Have a coupon? ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD4999F),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      enabled: !_couponApplied,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter coupon code",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4999F),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4999F),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _couponApplied || _couponChecking
                        ? null
                        : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _couponApplied
                          ? Colors.green
                          : const Color(0xFFD4999F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(90, 48),
                    ),
                    child: _couponChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_couponApplied ? "Applied" : "Apply"),
                  ),
                ],
              ),
              if (_couponError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    _couponError,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              if (_couponApplied && _appliedCoupon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "Coupon \"$_appliedCoupon\" applied! ",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _couponApplied
                    ? "Your coupon is applied!  Click below to unlock your report."
                    : "Reveal your skin's secrets with our in-depth analysis — just ₹499",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(_couponApplied ? Icons.check : Icons.lock_open),
                label: Text(
                  _couponApplied
                      ? "Unlock with Coupon"
                      : "Unlock Full Details (₹499)",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4999F),
                  foregroundColor: Colors.white,
                ),
                onPressed: _startPayment,
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4999F), width: 2),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4999F).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
              const SizedBox(height: 12),
              const Text(
                "Congratulations!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4999F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You've unlocked your full skin analysis.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Send Report Button (only if not sent yet)
              if (!_reportSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendingReport ? null : _sendDetailedReport,
                    icon: _sendingReport
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(
                      _sendingReport
                          ? 'Sending.. .'
                          : 'Send Detailed Report to Email',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4999F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

              // Success message if report was sent
              if (_reportSent) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PDF Sent to Email',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_reportMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _reportMessage,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Option to resend
                TextButton.icon(
                  onPressed: _sendingReport ? null : _sendDetailedReport,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Resend Report'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD4999F),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reportSent
                            ? 'Check your email inbox for the detailed PDF report.'
                            : 'Click the button above to receive a detailed PDF report via email within a few minutes.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDesktopLayout() {
    final overallScore = _calculateOverallScore();

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF5E6E8),
            width: double.infinity,
            child: Container(
              margin: const EdgeInsets.fromLTRB(40, 15, 40, 5),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD4999F),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                'Attractiveness Index Score:  ${overallScore.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 600,
                      margin: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: widget.imageBytes != null
                                ? Image.memory(
                                    widget.imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person, size: 120),
                                  ),
                          ),
                          Positioned(
                            left: 30,
                            top: 50,
                            child: AnalysisPoint(
                              label: 'Pigmentation',
                              value: widget.analysisData!.pigmentationScore
                                  .toStringAsFixed(0),
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            top: 150,
                            child: AnalysisPoint(
                              label: 'Hydration',
                              value: widget.analysisData!.hydrationScore
                                  .toStringAsFixed(0),
                              color: const Color(0xFF9B7653).withOpacity(0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 600,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B4BA),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const Text(
                              'The closer you are to 100, the healthier your skin is.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 25),

                            // First Row - 3 cards
                            Row(
                              children: [
                                Expanded(
                                  child: ScoreCard(
                                    score: widget.analysisData!.acneScore
                                        .toStringAsFixed(0),
                                    label: 'Acne',
                                    factors: _getAcneFactors(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ScoreCard(
                                    score: widget.analysisData!.hydrationScore
                                        .toStringAsFixed(0),
                                    label: 'Hydration',
                                    factors: _getHydrationFactors(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ScoreCard(
                                    score: widget
                                        .analysisData!
                                        .pigmentationScore
                                        .toStringAsFixed(0),
                                    label: 'Pigmentation',
                                    factors: _getPigmentationFactors(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Second Row - 2 cards centered
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ScoreCard(
                                      score: widget.analysisData!.poresScore
                                          .toStringAsFixed(0),
                                      label: 'Pores',
                                      factors: _getPoresFactors(),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ScoreCard(
                                      score: widget.analysisData!.wrinklesScore
                                          .toStringAsFixed(0),
                                      label: 'Wrinkles',
                                      factors: _getWrinklesFactors(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),

                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                InfoPill(
                                  text:
                                      'Skin Age: ${widget.analysisData!.skinAge}',
                                ),
                                InfoPill(
                                  text:
                                      'Eye Age: ${widget.analysisData!.eyeAge}',
                                ),
                                InfoPill(
                                  text:
                                      'Skin Type: ${widget.analysisData!.skinType}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: List.generate(6, (index) {
                                return ColorCircle(
                                  color: fitzpatrickColors[index],
                                  isSelected: selectedColorIndex == index,
                                  onTap: () => setState(
                                    () => selectedColorIndex = index,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Fitzpatrick Type ${selectedColorIndex + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // DISCLAIMER SECTION (Desktop)
                            _buildDisclaimerSection(600),
                            const SizedBox(height: 20),

                            // PAYMENT/COUPON SECTION (Desktop)
                            _buildPaymentSection(600),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
