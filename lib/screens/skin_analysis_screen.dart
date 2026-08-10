import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skin_analysis_app/Models/FaceRatioLine.dart';
import 'package:skin_analysis_app/widgets/FaceRatioPainter.dart';
import 'package:skin_analysis_app/widgets/analysis_point.dart';
import '../models/skin_analysis_model.dart';
import '../widgets/score_card.dart';

class SkinAnalysisScreen extends StatefulWidget {
  final SkinAnalysisModel? analysisData;
  final Uint8List? imageBytes;
  final Map<String, dynamic>? faceRatioJson; // ← symmetry data from API
  final Map<String, dynamic>? apiResponse; // ← full API response (optional)

  const SkinAnalysisScreen({
    super.key,
    this.analysisData,
    this.imageBytes,
    this.faceRatioJson,
    this.apiResponse,
  });

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen> {
  late int selectedColorIndex;

  // Payment & Coupon variables - COMMENTED OUT
  // bool _hasPaid = false;
  // String paymentStatus = "";
  // TextEditingController _couponController = TextEditingController();
  // bool _couponApplied = false;
  // bool _couponChecking = false;
  // String _couponError = "";
  // String _appliedCoupon = "";

  bool _sendingReport = false;
  String _reportMessage = '';
  bool _reportSent = false;

  // Facial Symmetry PageView
  late PageController _pageController;
  int _currentPage = 0;
  late ScrollController _scrollController;
  bool _disclaimerExpanded = false;

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
    }
  }

  /*
  Future<void> _sendDetailedReport() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
      _reportMessage = 'Generating PDF report...';
    });

    try {
      final result = await ApiService.sendDetailedReport(analysisId);
      if (!mounted) return;

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
      if (!mounted) return;
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
  */

  // NEW: Function to handle send report with login check
  // Future<void> _handleSendReport() async {
  //   await _sendDetailedReport();
  // }

  @override
  void initState() {
    super.initState();
    selectedColorIndex = (widget.analysisData?.fitzpatrickType ?? 1) - 1;
    _pageController = PageController(
    viewportFraction: 0.9,
    initialPage: 0,
    keepPage: true,
   );
    _scrollController = ScrollController();


    // COMMENTED OUT: Payment initialization
    // checkSubscriptionStatus();
    // if (kIsWeb) {
    //   js.context['flutterPaymentSuccess'] = (String paymentId) {
    //     setState(() {
    //       paymentStatus = "Payment Successful:  $paymentId";
    //       _hasPaid = true;
    //     });
    //     _handlePaymentSuccess(paymentId);
    //   };
    //   js.context['flutterPaymentError'] = (String paymentId) {
    //     setState(() {
    //       paymentStatus = "Payment Failed: $paymentId";
    //     });
    //     _handlePaymentError(paymentId);
    //   };
    // }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    // _couponController.dispose(); // COMMENTED OUT
    super.dispose();
  }

  // COMMENTED OUT: Payment and coupon functions
  /*
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
        'http://127.0.0.1:8000/api/payment/store',
      );
      await http.post(
        uri,
        body: jsonEncode(paymentData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}

    setState(() {
      _hasPaid = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment successful! Details unlocked."),
        backgroundColor: Colors.green,
      ),
    );

    _sendDetailedReport();
  }

  void _handlePaymentError(paymentId) async {
    final paymentData = {
      "payment_id": paymentId ??  "",
      "amount": 499.00,
      "currency":  "INR",
      "status": "Failed",
      "payment_method":  "razorpay",
      "description": "Unlock Full Report",
      "metadata": {"order_id": paymentId ?? "", "customer_id": ""},
      "transaction_reference": paymentId ?? "",
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      final uri = Uri.parse(
        'http://127.0.0.1:8000/api/payment/store',
      );
      await http.post(
        uri,
        body:  jsonEncode(paymentData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
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
        final isSubscribed = updatedPrefs. getBool('isSubscribe') ?? false;

        if (! isSubscribed) {
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
          content: Text("Coupon applied! Details unlocked."),
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

    js.context. callMethod('openRazorpayCheckout', [
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
        MaterialPageRoute(builder:  (context) => const LoginPage()),
      );

      if (result == true) {
        _applyCoupon();
      }
      return;
    }

    final code = _couponController.text. trim();
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
        _couponError = "Error validating coupon.";
        _couponApplied = false;
        _appliedCoupon = "";
      });
    } finally {
      setState(() {
        _couponChecking = false;
      });
    }
  }
  */

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
    final parts = s.split(':  ').map((e) => e.trim()).toList();
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

    double? eyeScore0(EyeBox? e) {
      if (e == null) return null;
      final g = _parseRatioToNumber(e.golden);
      final m = _parseRatioToNumber(e.measured);
      if (g == null || m == null) return null;
      return _scoreFromRatio(m, g);
    }

    final lScore = eyeScore0(d.leftEye);
    final rScore = eyeScore0(d.rightEye);
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

  @override
  Widget build(BuildContext context) {
    final skinHealthScore = widget.analysisData?.skinHealthIndex ?? 0;
    final symmetryScore = calculateSymmetryBasedScore(
      symmetryJson: widget.faceRatioJson,
    );

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE8B4BA),
      appBar: AppBar(
        title: const Text('Complete Skin Analysis'),
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
            return Container(
              color: const Color(0xFFE8B4BA),
              child: CustomScrollView(
            controller: _scrollController,
            cacheExtent: 2000,   // increased for smoother scrolling on iPhone
            slivers: [
             SliverToBoxAdapter(
              child: Column(
                children: [
                // ==================== SECTION 1: SKIN HEALTH ANALYSIS ====================
                _buildSkinHealthSection(skinHealthScore, screenWidth),

                const SizedBox(height: 30),

                // ==================== SECTION 2: FACIAL SYMMETRY ANALYSIS ====================
                _buildFacialSymmetrySection(symmetryScore, screenWidth),
                const SizedBox(height: 20),
                
                // Arrow to detailed report
                Center(
                  child: GestureDetector(
                    onTap: _scrollToBottom,
                    child: Column(
                      children: const [
                        Icon(Icons.keyboard_arrow_down, size: 28, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('Get detailed report', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // DISCLAIMER SECTION
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: _buildDisclaimerSection(screenWidth),
                ),
                const SizedBox(height: 20),

                // REPORT SECTION (REPLACED PAYMENT SECTION)
                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                //   child: _buildReportSection(screenWidth),
                // ),
               const SizedBox(height: 30),
             ],
            ),
           ),
          ],
         ),
        );
      },
    );
  }

  Widget _buildFacialSymmetrySection(double symmetryScore, double screenWidth) {
    FaceRatioData? faceData;
    bool hasValidData = false;

    if (widget.faceRatioJson != null) {
      try {
        faceData = FaceRatioData.fromMap(widget.faceRatioJson!);
        hasValidData = true;
      } catch (_) {}
    }

    final symmetryPercentage = symmetryScore * 10.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
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
            child: Row(
              children: const [
                Icon(Icons.face, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Facial Symmetry Analysis',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                      'Symmetry Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      symmetryPercentage.toStringAsFixed(1),
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

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                                  ).withValues(alpha: 0.2),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B7653).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9B7653).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Your symmetry score is calculated using facial proportions observed in this image based on golden ratio standards, including vertical/horizontal sections, eye ratios, face box, nose–lip–chin proportions, lip ratios, and jaw alignment.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                if (hasValidData && faceData != null) ...[
                  _buildSwipeableRatioCards(faceData),
                ] else ...[
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

  Widget _buildSkinHealthSection(double skinHealthScore, double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
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
                                  'Skin Health Score',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                                Text(
                                  skinHealthScore.toStringAsFixed(1),
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
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _scrollToBottom,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_down, size: 28, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Get detailed report', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

          if (widget.imageBytes != null) ...[
            Container(
              height: 260,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.imageBytes == null) return;
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            insetPadding: const EdgeInsets.all(12),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.memory(
                                widget.imageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Image.memory(
                        widget.imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    top: 20,
                    child: AnalysisPoint(
                      label: 'Pigmentation',
                      color: _colorForScore(widget.analysisData!.pigmentationScore),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    top: 60,
                    child: AnalysisPoint(
                      label: 'Hydration',
                      color: _colorForScore(widget.analysisData!.hydrationScore),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                          const Text(
                            'This score reflects visible characteristics captured in this scan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                const SizedBox(height: 16),

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

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildLargeInfoPill(
                      'Skin Age: ${_ageLabel(widget.analysisData!.skinAge)}',
                    ),
                    _buildLargeInfoPill(
                      'Eye Age: ${_ageLabel(widget.analysisData!.eyeAge)}',
                    ),
                    _buildLargeInfoPill(
                      'Skin Type: ${widget.analysisData!.skinType}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Text(
                    'Based on visual features in this image only',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
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
                const Color(0xFF9B7653).withValues(alpha: 0.8),
                const Color(0xFF7D5E48).withValues(alpha: 0.8),
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
                physics: const BouncingScrollPhysics(),
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
                      color: Colors.black.withValues(alpha: 0.5),
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
                      color: Colors.black.withValues(alpha: 0.5),
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
              color: const Color(0xFF9B7653).withValues(alpha: 0.2),
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
                        color: Colors.black.withValues(alpha: 0.2),
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
    return Container(
      color: const Color(0xFFE8B4BA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                // SECTION 1: SKIN HEALTH ANALYSIS
                _buildSkinHealthSection(skinHealthScore, 1200),

                const SizedBox(height: 40),

                // SECTION 2: FACIAL SYMMETRY ANALYSIS
                if (widget.faceRatioJson != null) ...[
                  _buildFacialSymmetrySection(symmetryScore, 1200),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Column(
                        children: const [
                          Icon(Icons.keyboard_arrow_down, size: 28, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Get detailed report', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // DISCLAIMER & REPORT
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Stack vertically on smaller laptop screens
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          _buildDisclaimerSection(constraints.maxWidth),
                          // const SizedBox(height: 20),
                          // _buildReportSection(constraints.maxWidth),
                        ],
                      );
                    }

                    // Side by side on larger screens
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildDisclaimerSection(
                              constraints.maxWidth / 2 - 10,
                            ),
                          ),
                          // const SizedBox(width: 20),
                          // Expanded(
                          //   child: _buildReportSection(
                          //     constraints.maxWidth / 2 - 10,
                          //   ),
                          // ),
                        ],
                      ),
                    );
                  },
                ),

                // Add bottom padding to prevent overflow
                const SizedBox(height: 40),
              ],
            ),
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
        border: Border.all(color: const Color(0xFFD4999F).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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

  Color _colorForScore(double score) {
    final t = (score.clamp(0.0, 100.0) / 100.0);
    return Color.lerp(const Color(0xFFFF6B6B), const Color(0xFF6BCB77), t) ?? const Color(0xFF9B7653);
  }

  String _ageLabel(int age) {
    if (age <= 0) return 'Unknown';
    final decade = (age ~/ 10) * 10;
    final within = age % 10;
    String part;
    if (within <= 3) {
      part = 'Early';
    } else if (within <= 6) {
      part = 'Mid';
    } else {
      part = 'Late';
    }
    return '$part ${decade}s';
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
              color: Colors.black.withValues(alpha: 0.15),
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
        children: [
          const Text(
            "Disclaimer",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "• The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and educational purposes only.",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "• The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and educational purposes only.\n\n"
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
            crossFadeState: _disclaimerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _disclaimerExpanded = !_disclaimerExpanded),
            child: Text(
              _disclaimerExpanded ? 'Read less' : 'Read more',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (!mounted) return;
    try {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // ignore
    }
  }

  // NEW: Report Section (replaces payment section)
  // Widget _buildReportSection(double width) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       gradient: _reportSent
  //           ? LinearGradient(
  //               colors: [Colors.green.shade50, Colors.green.shade100],
  //             )
  //           : LinearGradient(
  //               colors: [
  //                 const Color(0xFFD4999F).withValues(alpha: 0.1),
  //                 Colors.white,
  //               ],
  //             ),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: _reportSent ? Colors.green.shade300 : const Color(0xFFD4999F),
  //         width: 2,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.1),
  //           blurRadius: 8,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         if (_reportSent) ...[
  //           Icon(Icons.check_circle, color: Colors.green.shade700, size: 60),
  //           const SizedBox(height: 12),
  //           Text(
  //             "Report Sent Successfully! ",
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.green.shade800,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 8),
  //           if (_reportMessage.isNotEmpty)
  //             Text(
  //               _reportMessage,
  //               style: TextStyle(fontSize: 14, color: Colors.green.shade700),
  //               textAlign: TextAlign.center,
  //             ),
  //           const SizedBox(height: 12),
  //           const Text(
  //             "Check your email for the detailed PDF report.",
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: Colors.black87,
  //               height: 1.5,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 16),
  //           TextButton.icon(
  //             onPressed: _sendingReport ? null : _handleSendReport,
  //             icon: const Icon(Icons.refresh, size: 18),
  //             label: const Text('Resend Report'),
  //             style: TextButton.styleFrom(
  //               foregroundColor: const Color(0xFFD4999F),
  //             ),
  //           ),
  //         ] else ...[
  //           Icon(
  //             Icons.picture_as_pdf,
  //             color: const Color(0xFFD4999F),
  //             size: 60,
  //           ),
  //           const SizedBox(height: 12),
  //           const Text(
  //             "Get Your Detailed Report",
  //             style: TextStyle(
  //               color: Colors.black87,
  //               fontWeight: FontWeight.bold,
  //               fontSize: 18,
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           const Text(
  //             "Receive a comprehensive PDF analysis report with detailed insights about your skin health and facial symmetry.",
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: Colors.black87,
  //               height: 1.5,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 20),
  //           if (_sendingReport) ...[
  //             const CircularProgressIndicator(
  //               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4999F)),
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               _reportMessage.isNotEmpty ? _reportMessage : 'Processing.. .',
  //               style: const TextStyle(fontSize: 14, color: Colors.black54),
  //               textAlign: TextAlign.center,
  //             ),
  //           ] else ...[
  //             ElevatedButton.icon(
  //               icon: const Icon(Icons.send),
  //               label: const Text(
  //                 'Send Detailed Report',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  //               ),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: const Color(0xFFD4999F),
  //                 foregroundColor: Colors.white,
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 32,
  //                   vertical: 16,
  //                 ),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 elevation: 4,
  //               ),
  //               onPressed: _handleSendReport,
  //             ),
  //             const SizedBox(height: 12),
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue.shade50,
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.blue.shade200),
  //               ),
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(
  //                     Icons.info_outline,
  //                     color: Colors.blue.shade700,
  //                     size: 20,
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       'Login required to receive your report',
  //                       style: TextStyle(
  //                         color: Colors.blue.shade900,
  //                         fontSize: 12,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ],
  //       ],
  //     ),
  //   );
  // }
}

// Helper widget to display ratio card content
class _RatioCardContent extends StatelessWidget {
  final FaceRatioData data;
  final RatioMode mode;

  const _RatioCardContent({required this.data, required this.mode});

  @override
  Widget build(BuildContext context) {
    final img = data.imageBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image with overlay (tap to enlarge)
        GestureDetector(
          onTap: () {
            if (img == null) return;
            showDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(img, fit: BoxFit.contain),
                ),
              ),
            );
          },
          child: ClipRRect(
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
              "Observed: ${data.faceBox!.yours}\nGolden ratio: ${data.faceBox!.golden}";
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
        color: Colors.black.withValues(alpha: 0.7),
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
