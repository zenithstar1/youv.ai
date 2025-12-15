import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';
import 'package:skin_analysis_app/Models/FaceRatioLine.dart';
import 'package:skin_analysis_app/screens/LoginPage.dart';
import 'package:skin_analysis_app/widgets/FaceRatioPainter.dart';
import '../models/skin_analysis_model.dart';
import '../widgets/analysis_point.dart';
import '../widgets/score_card.dart' hide FactorItem;
import '../widgets/info_pill.dart';
import '../widgets/color_circle.dart';
import 'package:http/http.dart' as http;

class SkinAnalysisScreen extends StatefulWidget {
  final SkinAnalysisModel? analysisData;
  final Uint8List? imageBytes;
  final Map<String, dynamic>? faceRatioJson; // ← symmetry data from API
  final Map<String, dynamic>? apiResponse; // ← full API response (optional)

  const SkinAnalysisScreen({
    Key? key,
    this.analysisData,
    this.imageBytes,
    this.faceRatioJson,
    this.apiResponse,
  }) : super(key: key);

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
  bool _sendingReport = false;
  String _reportMessage = '';
  bool _reportSent = false;

  // Facial Symmetry PageView
  late PageController _pageController;
  int _currentPage = 0;

  final List<Color> fitzpatrickColors = [
    const Color(0xFFFFF5F0),
    const Color(0xFFFFE4D6),
    const Color(0xFFE8B896),
    const Color(0xFFD4A574),
    const Color(0xFFAE7E5C),
    const Color(0xFF6B4423),
  ];

  // List of all ratio modes for the carousel
  final List<RatioMode> _ratioModes = [
    RatioMode.vertical,
    RatioMode.horizontal,
    RatioMode.eyes,
    RatioMode.faceBox,
    RatioMode.noseLipChin,
    RatioMode.lips,
    RatioMode.jaw,
  ];

  String _labelForMode(RatioMode mode) {
    switch (mode) {
      case RatioMode.vertical:
        return "Vertical Sections";
      case RatioMode.horizontal:
        return "Horizontal Sections";
      case RatioMode.eyes:
        return "Eye Aspect Ratio";
      case RatioMode.faceBox:
        return "Face Aspect Ratio";
      case RatioMode.noseLipChin:
        return "Nose–Lip–Chin";
      case RatioMode.lips:
        return "Lips Ratio";
      case RatioMode.jaw:
        return "Jaw Ratio";
      default:
        return "Facial Ratio";
    }
  }

  Future<void> _sendDetailedReport() async {
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

    setState(() {
      _sendingReport = true;
      _reportMessage = 'Generating PDF report...';
    });

    try {
      final result = await ApiService.sendDetailedReport(analysisId);

      setState(() {
        _sendingReport = false;
        _reportSent = result['success'] == true;
        _reportMessage = result['message'] ?? '';
      });

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Report Sent Successfully!')),
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
                const SizedBox(height: 12),
                if (result['email_sent'] == true)
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.green[700], size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '✓ Email sent',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                if (result['whatsapp_sent'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat, color: Colors.green[700], size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          '✓ WhatsApp sent',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFD4999F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _sendingReport = false;
        _reportMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    selectedColorIndex = (widget.analysisData?.fitzpatrickType ?? 1) - 1;
    _pageController = PageController(viewportFraction: 0.9);
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
          paymentStatus = "Payment Failed:  $paymentId";
        });
        _handlePaymentError(paymentId);
      };
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        content: Text("Payment successful!  Details unlocked."),
        backgroundColor: Colors.green,
      ),
    );

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
        content: Text("Payment failed or cancelled.  Please try again."),
      ),
    );
  }

  void _startPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLogin') ?? false;

    if (!isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

      if (result == true) {
        final updatedPrefs = await SharedPreferences.getInstance();
        final isSubscribed = updatedPrefs.getBool('isSubscribe') ?? false;

        if (!isSubscribed) {
          _proceedWithPayment();
        } else {
          setState(() {
            _hasPaid = true;
          });
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
      _sendDetailedReport();
      return;
    }

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

      _sendDetailedReport();
      return;
    }

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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

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
          _couponError = "Invalid coupon. ";
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

  // ==================== SYMMETRY SCORING ====================

  double _safeDiv(double a, double b) => b == 0 ? 0 : a / b;

  double? _parseRatioToNumber(String? s) {
    if (s == null) return null;
    final parts = s.split(': ').map((e) => e.trim()).toList();
    if (parts.length != 2) return double.tryParse(s);
    final left = double.tryParse(parts[0]);
    final right = double.tryParse(parts[1]);
    if (left == null || right == null || left == 0) return null;
    return right / left;
  }

  double _scoreFromRatio(double? measured, double? ideal) {
    if (measured == null || ideal == null || ideal == 0) return 0;
    final err = (measured - ideal).abs() / ideal;
    final norm = (err > 1.5) ? 1.5 : err;
    final s = 10.0 * (1.0 - norm / 1.5);
    return s.clamp(0.0, 10.0);
  }

  double _scoreFromUniformSections(List<double> vals) {
    if (vals.isEmpty) return 0;
    final n = vals.length;
    final sum = vals.fold(0.0, (a, b) => a + b);
    if (sum <= 0) return 0;

    final perc = (sum - 100).abs() < 2
        ? vals
        : vals.map((v) => v / sum * 100.0).toList();

    final ideal = 100.0 / n;
    final avgAbsDev =
        perc.map((v) => (v - ideal).abs()).fold(0.0, (a, b) => a + b) / n;

    double normalized = 1.0 - _safeDiv(avgAbsDev, ideal);
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;
    return (10.0 * normalized).clamp(0.0, 10.0);
  }

  double calculateSymmetryScoreFromFaceData(FaceRatioData? d) {
    if (d == null) return 7.0;

    final components = <double>[];
    final weights = <double>[];

    if (d.verticalPerc.isNotEmpty) {
      components.add(_scoreFromUniformSections(d.verticalPerc));
      weights.add(30);
    }

    if (d.horizontalPerc.isNotEmpty) {
      components.add(_scoreFromUniformSections(d.horizontalPerc));
      weights.add(30);
    }

    final faceGolden = _parseRatioToNumber(d.faceBox?.golden);
    final faceYours = _parseRatioToNumber(d.faceBox?.yours);
    if (faceGolden != null && faceYours != null) {
      components.add(_scoreFromRatio(faceYours, faceGolden));
      weights.add(10);
    }

    final nlcMeasured = _parseRatioToNumber(d.noseLipChinRatio);
    final nlcIdeal = _parseRatioToNumber(d.noseLipChinIdeal);
    if (nlcMeasured != null && nlcIdeal != null) {
      components.add(_scoreFromRatio(nlcMeasured, nlcIdeal));
      weights.add(10);
    }

    final lipsMeasured = _parseRatioToNumber(d.lipRatio);
    final lipsIdeal = _parseRatioToNumber(d.lipIdeal);
    if (lipsMeasured != null && lipsIdeal != null) {
      components.add(_scoreFromRatio(lipsMeasured, lipsIdeal));
      weights.add(10);
    }

    double? _eyeScore(EyeBox? e) {
      if (e == null) return null;
      final g = _parseRatioToNumber(e.golden);
      final m = _parseRatioToNumber(e.measured);
      if (g == null || m == null) return null;
      return _scoreFromRatio(m, g);
    }

    final lScore = _eyeScore(d.leftEye);
    final rScore = _eyeScore(d.rightEye);
    double? eyeScore;
    if (lScore != null && rScore != null) {
      eyeScore = (lScore + rScore) / 2.0;
    } else {
      eyeScore = lScore ?? rScore;
    }
    if (eyeScore != null) {
      components.add(eyeScore);
      weights.add(5);
    }

    if (d.jaw != null && d.jaw!.ideal > 0 && d.jaw!.ratio > 0) {
      components.add(_scoreFromRatio(d.jaw!.ratio, d.jaw!.ideal));
      weights.add(5);
    }

    if (components.isEmpty) return 7.0;

    final totalW = weights.fold(0.0, (a, b) => a + b);
    final sym = components
        .asMap()
        .entries
        .map((e) => e.value * (weights[e.key] / totalW))
        .fold(0.0, (a, b) => a + b);

    return sym.clamp(3.0, 9.5);
  }

  double calculateSymmetryBasedScore({
    FaceRatioData? symmetryData,
    Map<String, dynamic>? symmetryJson,
  }) {
    FaceRatioData? data = symmetryData;
    if (data == null && symmetryJson != null) {
      try {
        data = FaceRatioData.fromMap(symmetryJson);
      } catch (_) {}
    }

    return calculateSymmetryScoreFromFaceData(data);
  }

  // ==================== SKIN HEALTH SCORING ====================

  double _calculateSkinHealthScore() {
    if (widget.analysisData == null) return 0;

    final acneDetailScore = _calculateAcneDetailScore();
    final hydrationDetailScore = _calculateHydrationDetailScore();
    final pigmentationDetailScore = _calculatePigmentationDetailScore();
    final poresDetailScore = _calculatePoresDetailScore();
    final wrinklesDetailScore = _calculateWrinklesDetailScore();
    final agingScore = _calculateAgingScore(
      (widget.analysisData!.skinAge + widget.analysisData!.eyeAge) / 2,
    );

    const double acneWeight = 0.25;
    const double hydrationWeight = 0.20;
    const double pigmentationWeight = 0.20;
    const double poresWeight = 0.15;
    const double wrinklesWeight = 0.15;
    const double agingWeight = 0.05;

    final totalScore =
        (acneDetailScore * acneWeight) +
        (hydrationDetailScore * hydrationWeight) +
        (pigmentationDetailScore * pigmentationWeight) +
        (poresDetailScore * poresWeight) +
        (wrinklesDetailScore * wrinklesWeight) +
        (agingScore * agingWeight);

    print('=== Skin Health Attractiveness Score ===');
    print(
      'Acne:  ${acneDetailScore.toStringAsFixed(2)} × 25% = ${(acneDetailScore * acneWeight).toStringAsFixed(2)}',
    );
    print(
      'Hydration: ${hydrationDetailScore.toStringAsFixed(2)} × 20% = ${(hydrationDetailScore * hydrationWeight).toStringAsFixed(2)}',
    );
    print(
      'Pigmentation:  ${pigmentationDetailScore.toStringAsFixed(2)} × 20% = ${(pigmentationDetailScore * pigmentationWeight).toStringAsFixed(2)}',
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
    print('Final Skin Health Score: ${totalScore.toStringAsFixed(2)}%');
    print('========================================');

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
    final skinHealthScore = _calculateSkinHealthScore();
    final symmetryScore = calculateSymmetryBasedScore(
      symmetryJson: widget.faceRatioJson,
    );

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE8B4BA),
      appBar: AppBar(
        title: const Text('Complete Beauty Analysis'),
        backgroundColor: const Color(0xFFD4999F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: isDesktop
            ? _buildDesktopLayout(skinHealthScore, symmetryScore)
            : _buildMobileLayout(skinHealthScore, symmetryScore),
      ),
    );
  }

  Widget _buildMobileLayout(double skinHealthScore, double symmetryScore) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        // ADD DEBUG LOGGING
        print('=== FACIAL SYMMETRY DEBUG ===');
        print('faceRatioJson is null: ${widget.faceRatioJson == null}');
        if (widget.faceRatioJson != null) {
          print('faceRatioJson keys: ${widget.faceRatioJson!.keys}');
          print('faceRatioJson content: ${widget.faceRatioJson}');
        }
        print('symmetryScore: $symmetryScore');
        print('============================');

        return Container(
          color: const Color(0xFFE8B4BA),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ==================== SECTION 1: SKIN HEALTH ANALYSIS ====================
                _buildSkinHealthSection(skinHealthScore, screenWidth),

                const SizedBox(height: 30),

                // ==================== SECTION 2: FACIAL SYMMETRY ANALYSIS ====================
                // CHANGED: Show section even if faceRatioJson is null (with fallback UI)
                _buildFacialSymmetrySection(symmetryScore, screenWidth),
                const SizedBox(height: 30),

                // DISCLAIMER SECTION
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: _buildDisclaimerSection(screenWidth),
                ),
                const SizedBox(height: 20),

                // PAYMENT/COUPON SECTION
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: _buildPaymentSection(screenWidth),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // UPDATE:  Facial Symmetry Section with better error handling
  Widget _buildFacialSymmetrySection(double symmetryScore, double screenWidth) {
    FaceRatioData? faceData;
    bool hasValidData = false;

    if (widget.faceRatioJson != null) {
      try {
        print('Attempting to parse faceRatioJson...');
        faceData = FaceRatioData.fromMap(widget.faceRatioJson!);
        hasValidData = true;
        print('Successfully parsed faceRatioJson');
      } catch (e) {
        print('Error parsing face ratio data: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    } else {
      print('widget.faceRatioJson is NULL');
    }

    // Convert symmetry score (0-10) to percentage for Attractiveness Index
    final symmetryPercentage = symmetryScore * 10.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header with Attractiveness Index
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF9B7653), const Color(0xFF7D5E48)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.face, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Facial Symmetry Analysis',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Facial Symmetry Attractiveness Index Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Color(0xFF9B7653),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Symmetry Attractiveness Index',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${symmetryPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B7653),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Symmetry Score Display
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: symmetryScore),
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeOutExpo,
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 120,
                                width: 120,
                                child: CircularProgressIndicator(
                                  value: (value / 10).clamp(0.0, 1.0),
                                  strokeWidth: 12,
                                  backgroundColor: const Color(
                                    0xFF9B7653,
                                  ).withOpacity(0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF9B7653),
                                      ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    value.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Text(
                                    "/ 10",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Symmetry Score",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          symmetryScore >= 8.5
                              ? "Excellent facial symmetry!  You're in the top 20%"
                              : symmetryScore >= 7.0
                              ? "Good facial balance and harmony"
                              : "Room for enhancement",
                          style: TextStyle(
                            fontSize: 14,
                            color: symmetryScore >= 8.5
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Explanation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B7653).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9B7653).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Your symmetry score is calculated using facial proportions based on golden ratio standards, including vertical/horizontal sections, eye ratios, face box, nose-lip-chin proportions, lip ratios, and jaw alignment.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Swipeable Ratio Cards OR Error Message
                if (hasValidData && faceData != null) ...[
                  _buildSwipeableRatioCards(faceData),
                ] else ...[
                  // Show error/loading state
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Detailed facial ratio analysis is being processed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The symmetry score is based on AI analysis.  Detailed measurements will be available shortly.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SKIN HEALTH SECTION ====================
  Widget _buildSkinHealthSection(double skinHealthScore, double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header with Attractiveness Index
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFD4999F), const Color(0xFFB87E84)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.health_and_safety,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Skin Health Analysis',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Skin Health Attractiveness Index Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Color(0xFFD4999F),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skin Attractiveness Index',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${skinHealthScore.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4999F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Image Section
          if (widget.imageBytes != null) ...[
            Container(
              height: 320,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      widget.imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
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
                      color: const Color(0xFF9B7653).withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'The closer you are to 100, the healthier your skin is.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Score Cards Row 1
                Row(
                  children: [
                    Expanded(
                      child: ScoreCard(
                        score: widget.analysisData!.acneScore.toStringAsFixed(
                          0,
                        ),
                        label: 'Acne',
                        factors: _getAcneFactors(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ScoreCard(
                        score: widget.analysisData!.hydrationScore
                            .toStringAsFixed(0),
                        label: 'Hydration',
                        factors: _getHydrationFactors(),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 12),

                // Score Cards Row 2
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
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
                      const SizedBox(width: 12),
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
                Wrap(
                  spacing: 10,
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
                      'Skin Type: ${widget.analysisData!.skinType}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Color Palette
                Wrap(
                  spacing: 12,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeableRatioCards(FaceRatioData data) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF9B7653).withOpacity(0.8),
                const Color(0xFF7D5E48).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.straighten, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _labelForMode(_ratioModes[_currentPage]),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Swipe hint
        AnimatedOpacity(
          opacity: _currentPage == 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "Swipe to explore different facial ratios",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Card carousel
        SizedBox(
          height: 480,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _ratioModes.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                      }
                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 480,
                          width: Curves.easeOut.transform(value) * 360,
                          child: child,
                        ),
                      );
                    },
                    child: _buildRatioCard(data, _ratioModes[index]),
                  );
                },
              ),

              // Navigation arrows
              Positioned(
                left: 0,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: _currentPage < _ratioModes.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _ratioModes.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF9B7653)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioCard(FaceRatioData data, RatioMode mode) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B7653).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _RatioCardContent(data: data, mode: mode),
                ),
              ),

              // Mode badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B7653),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _labelForMode(mode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double skinHealthScore, double symmetryScore) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              // SECTION 1: SKIN HEALTH ANALYSIS
              _buildSkinHealthSection(skinHealthScore, 1200),

              const SizedBox(height: 40),

              // SECTION 2: FACIAL SYMMETRY ANALYSIS
              if (widget.faceRatioJson != null) ...[
                _buildFacialSymmetrySection(symmetryScore, 1200),
                const SizedBox(height: 40),
              ],

              // DISCLAIMER & PAYMENT
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDisclaimerSection(600)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildPaymentSection(600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4999F).withOpacity(0.3)),
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

  Widget _buildDisclaimerSection(double width) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade700, width: 2),
      ),
      padding: const EdgeInsets.all(16),
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
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(double width) {
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
                    ? "Your coupon is applied! Click below to unlock your report."
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onPressed: _startPayment,
              ),
            ],
          ),
        ),
      );
    } else {
      return Column(
        children: [
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
                          'Report Sent Successfully!',
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
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                  const SizedBox(height: 12),
                  Text(
                    "Congratulations! ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You've unlocked your full beauty analysis.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Your image has been sent to our experts.  You will receive a detailed PDF report within 24 hours via email, or you can login to Youvai to view and download your full report.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
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
                        : const Icon(Icons.send),
                    label: Text(
                      _sendingReport ? 'Sending.. .' : 'Send Detailed Report',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4999F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
  }
}

// Helper widget to display ratio card content
class _RatioCardContent extends StatelessWidget {
  final FaceRatioData data;
  final RatioMode mode;

  const _RatioCardContent({Key? key, required this.data, required this.mode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final img = data.imageBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image with overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 350),
            child: AspectRatio(
              aspectRatio: (data.imageW == 0 || data.imageH == 0)
                  ? 3 / 4
                  : data.imageW / data.imageH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img != null)
                    FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: data.imageW,
                        height: data.imageH,
                        child: Image.memory(img, fit: BoxFit.fill),
                      ),
                    ),
                  if (img != null)
                    FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: data.imageW,
                        height: data.imageH,
                        child: CustomPaint(
                          painter: PrettyRatioPainter(data, mode),
                        ),
                      ),
                    ),
                  if (img == null)
                    const Center(
                      child: Text(
                        "No image available",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Ratio information
        _buildRatioInfo(mode),
      ],
    );
  }

  Widget _buildRatioInfo(RatioMode mode) {
    String info = "";

    switch (mode) {
      case RatioMode.vertical:
        if (data.verticalPerc.isNotEmpty) {
          info =
              "Sections: ${data.verticalPerc.map((p) => '${p.toStringAsFixed(1)}%').join(', ')}";
        }
        break;
      case RatioMode.horizontal:
        if (data.horizontalPerc.isNotEmpty) {
          info =
              "Sections: ${data.horizontalPerc.map((p) => '${p.toStringAsFixed(1)}%').join(', ')}";
        }
        break;
      case RatioMode.eyes:
        final left = data.leftEye?.measured ?? "";
        final right = data.rightEye?.measured ?? "";
        if (left.isNotEmpty || right.isNotEmpty) {
          info = "Left: $left | Right: $right";
        }
        break;
      case RatioMode.faceBox:
        if (data.faceBox != null) {
          info =
              "Your ratio:  ${data.faceBox!.yours}\nGolden:  ${data.faceBox!.golden}";
        }
        break;
      case RatioMode.noseLipChin:
        if (data.noseLipChinRatio?.isNotEmpty ?? false) {
          info =
              "Ratio: ${data.noseLipChinRatio}\nIdeal: ${data.noseLipChinIdeal ?? 'N/A'}";
        }
        break;
      case RatioMode.lips:
        if (data.lipRatio?.isNotEmpty ?? false) {
          info = "Ratio: ${data.lipRatio}\nIdeal: ${data.lipIdeal ?? 'N/A'}";
        }
        break;
      case RatioMode.jaw:
        if (data.jaw != null) {
          info =
              "Ratio: ${data.jaw!.ratio.toStringAsFixed(2)}\nIdeal: ${data.jaw!.ideal.toStringAsFixed(2)}";
        }
        break;
    }

    if (info.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        info,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
