import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/skin_analysis_model.dart';
import '../widgets/analysis_point.dart';
import '../widgets/score_card.dart';
import '../widgets/info_pill.dart';
import '../widgets/color_circle.dart';

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

  final List<Color> fitzpatrickColors = [
    const Color(0xFFFFF5F0),
    const Color(0xFFFFE4D6),
    const Color(0xFFE8B896),
    const Color(0xFFD4A574),
    const Color(0xFFAE7E5C),
    const Color(0xFF6B4423),
  ];

  @override
  void initState() {
    super.initState();
    selectedColorIndex = (widget.analysisData?.fitzpatrickType ?? 1) - 1;
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
      'Acne: ${acneDetailScore.toStringAsFixed(2)} × 25% = ${(acneDetailScore * acneWeight).toStringAsFixed(2)}',
    );
    print(
      'Hydration: ${hydrationDetailScore.toStringAsFixed(2)} × 20% = ${(hydrationDetailScore * hydrationWeight).toStringAsFixed(2)}',
    );
    print(
      'Pigmentation: ${pigmentationDetailScore.toStringAsFixed(2)} × 20% = ${(pigmentationDetailScore * pigmentationWeight).toStringAsFixed(2)}',
    );
    print(
      'Pores: ${poresDetailScore.toStringAsFixed(2)} × 15% = ${(poresDetailScore * poresWeight).toStringAsFixed(2)}',
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

        return Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFFE8B4BA))),
            Column(
              children: [
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
                          'Attractiveness Index Score: ${overallScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        height: screenHeight * 0.42,
                        width: screenWidth,
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
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
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      width: screenWidth,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8B4BA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.04,
                          35,
                          screenWidth * 0.04,
                          0,
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
                                    'Skin Age : ${widget.analysisData!.skinAge}',
                                  ),
                                  _buildLargeInfoPill(
                                    'Eye Age : ${widget.analysisData!.eyeAge}',
                                  ),
                                  _buildLargeInfoPill(
                                    'Skin Type: ${widget.analysisData!.skinType}',
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
                                  () => setState(
                                    () => selectedColorIndex = index,
                                  ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
                'Attractiveness Index Score: ${overallScore.toStringAsFixed(1)}%',
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
                                      'Skin Age : ${widget.analysisData!.skinAge}',
                                ),
                                InfoPill(
                                  text:
                                      'Eye Age : ${widget.analysisData!.eyeAge}',
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
