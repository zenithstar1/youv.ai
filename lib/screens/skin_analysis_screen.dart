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

  // Fitzpatrick Scale Colors (Type 1 to Type 6)
  final List<Color> fitzpatrickColors = [
    const Color(0xFFFFF5F0), // Type 1: Very Fair (Pale white)
    const Color(0xFFFFE4D6), // Type 2: Fair (White to light beige)
    const Color(0xFFE8B896), // Type 3: Medium (Beige)
    const Color(0xFFD4A574), // Type 4: Olive (Light brown)
    const Color(0xFFAE7E5C), // Type 5: Brown (Dark brown)
    const Color(0xFF6B4423), // Type 6: Dark Brown (Very dark brown to black)
  ];

  @override
  void initState() {
    super.initState();
    // Set selected index based on fitzpatrick_type from API (1-6)
    // Convert to 0-based index
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Status Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TimeOfDay.now().format(context),
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_4_bar,
                            size: isDesktop ? 18 : 16,
                          ),
                          SizedBox(width: isDesktop ? 8 : 5),
                          Icon(Icons.wifi, size: isDesktop ? 18 : 16),
                          SizedBox(width: isDesktop ? 8 : 5),
                          Icon(Icons.battery_full, size: isDesktop ? 18 : 16),
                        ],
                      ),
                    ],
                  ),
                ),

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

                // Flexible content area
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Mobile Layout (Portrait)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Image with Analysis Points
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

        // Bottom Section (Overlapping the image)
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
                  // Header Text
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

                  // Score Cards - Centered with equal margins
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

                  // Info Pills - Using dynamic data from API
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

                  // Fitzpatrick Color Palette (6 colors)
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

                  // Fitzpatrick type indicator
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

  // Desktop Layout (Landscape)
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Image
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

              // Right side - Analysis
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

                        // Score Cards in Grid
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

                        // Info Pills - Using dynamic data
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

                        // Fitzpatrick Color Palette (6 colors)
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

                        // Fitzpatrick type indicator
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
