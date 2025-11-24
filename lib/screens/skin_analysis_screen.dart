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

  double _calculateOverallScore() {
    if (widget.analysisData == null) return 0;
    return (widget.analysisData!.acneScore +
            widget.analysisData!.hydrationScore +
            widget.analysisData!.pigmentationScore) /
        3;
  }

  @override
  Widget build(BuildContext context) {
    final overallScore = _calculateOverallScore();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10), // Top padding instead of status bar
            // Score Banner
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 8,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 30 : 20,
                vertical: isDesktop ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD4999F),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                'Attractiveness Index Score: ${overallScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 15 : 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Content area
            Expanded(
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ClipRRect(
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
              ),
              Positioned(
                left: 30,
                top: 30,
                child: AnalysisPoint(
                  label: 'Pigmentation',
                  value: widget.analysisData!.pigmentationScore.toStringAsFixed(
                    0,
                  ),
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              Positioned(
                right: 30,
                top: 80,
                child: AnalysisPoint(
                  label: 'Hydration',
                  value: widget.analysisData!.hydrationScore.toStringAsFixed(0),
                  color: const Color(0xFF9B7653).withOpacity(0.95),
                ),
              ),
            ],
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -30),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE8B4BA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ScoreCard(
                          score: widget.analysisData!.acneScore.toStringAsFixed(
                            0,
                          ),
                          label: 'Acne',
                          factors: _getAcneFactors(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: ScoreCard(
                          score: widget.analysisData!.hydrationScore
                              .toStringAsFixed(0),
                          label: 'Hydration',
                          factors: _getHydrationFactors(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: ScoreCard(
                          score: widget.analysisData!.pigmentationScore
                              .toStringAsFixed(0),
                          label: 'Pigmentation',
                          factors: _getPigmentationFactors(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      InfoPill(
                        text: 'Skin Age : ${widget.analysisData!.skinAge}',
                      ),
                      InfoPill(
                        text: 'Eye Age : ${widget.analysisData!.eyeAge}',
                      ),
                      InfoPill(
                        text: 'Skin Type: ${widget.analysisData!.skinType}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(6, (index) {
                      return ColorCircle(
                        color: fitzpatrickColors[index],
                        isSelected: selectedColorIndex == index,
                        onTap: () => setState(() => selectedColorIndex = index),
                      );
                    }),
                  ),

                  const SizedBox(height: 8),

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
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Center(
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

                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: ScoreCard(
                                score: widget.analysisData!.acneScore
                                    .toStringAsFixed(0),
                                label: 'Acne',
                                factors: _getAcneFactors(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Flexible(
                              child: ScoreCard(
                                score: widget.analysisData!.hydrationScore
                                    .toStringAsFixed(0),
                                label: 'Hydration',
                                factors: _getHydrationFactors(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Flexible(
                              child: ScoreCard(
                                score: widget.analysisData!.pigmentationScore
                                    .toStringAsFixed(0),
                                label: 'Pigmentation',
                                factors: _getPigmentationFactors(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

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
                              text: 'Eye Age : ${widget.analysisData!.eyeAge}',
                            ),
                            InfoPill(
                              text:
                                  'Skin Type: ${widget.analysisData!.skinType}',
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(6, (index) {
                            return ColorCircle(
                              color: fitzpatrickColors[index],
                              isSelected: selectedColorIndex == index,
                              onTap: () =>
                                  setState(() => selectedColorIndex = index),
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
    );
  }
}
