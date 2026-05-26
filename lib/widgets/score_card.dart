import 'package:flutter/material.dart';
import '../models/skin_analysis_model.dart'; // Import FactorItem from model

// REMOVE the FactorItem class definition from here since it's already in skin_analysis_model.dart

class ScoreCard extends StatelessWidget {
  final String score;
  final String label;
  final List<FactorItem> factors;

  const ScoreCard({
    super.key,
    required this.score,
    required this.label,
    required this.factors,
  });

  @override
  Widget build(BuildContext context) {
    final scoreValue = double.tryParse(score) ?? 0;

    return GestureDetector(
      onTap: () {
        if (factors.isNotEmpty) {
          _showFactorDetails(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: scoreValue / 100,
                    strokeWidth: 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(scoreValue),
                    ),
                  ),
                  Text(
                    score,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(scoreValue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Health score color (0-100, higher is better)
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green[600]!; // Excellent
    if (score >= 60) return Colors.lightGreen[600]!; // Good
    if (score >= 40) return Colors.orange[600]!; // Fair
    if (score >= 20) return Colors.deepOrange[600]!; // Poor
    return Colors.red[600]!; // Very Poor
  }

  // Convert problem severity (0-1) to health score (0-100)
  // INVERTED: Low problem = High health
  double _getHealthScore(double problemValue) {
    return (1 - problemValue) * 100;
  }

  // Health score color based on inverted problem value
  Color _getHealthColor(double healthScore) {
    if (healthScore >= 80) return Colors.green[600]!; // Excellent health
    if (healthScore >= 60) return Colors.lightGreen[600]!; // Good health
    if (healthScore >= 40) return Colors.orange[600]!; // Fair health
    if (healthScore >= 20) return Colors.deepOrange[600]!; // Poor health
    return Colors.red[600]!; // Very poor health
  }

  Color _getHealthBgColor(double healthScore) {
    if (healthScore >= 80) return Colors.green[50]!;
    if (healthScore >= 60) return Colors.lightGreen[50]!;
    if (healthScore >= 40) return Colors.orange[50]!;
    if (healthScore >= 20) return Colors.deepOrange[50]!;
    return Colors.red[50]!;
  }

  void _showFactorDetails(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: screenHeight * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.analytics,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$label Analysis',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Higher percentages = Better skin health = Closer to 100%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Factor List
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: factors.map((factor) {
                      // CONVERT problem severity to health score
                      final healthScore = _getHealthScore(factor.value);
                      final healthPercentage = healthScore.toStringAsFixed(0);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    factor.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getHealthBgColor(healthScore),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$healthPercentage%',
                                    style: TextStyle(
                                      color: _getHealthColor(healthScore),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:
                                    healthScore /
                                    100, // Show health score progress
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getHealthColor(healthScore),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Fixed Close Button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8B4BA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
