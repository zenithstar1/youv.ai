import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String score;
  final String label;
  final List<FactorItem>? factors;

  const ScoreCard({
    Key? key,
    required this.score,
    required this.label,
    this.factors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 150 : 110,
        minWidth: isDesktop ? 130 : 95,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 18 : 10,
        vertical: isDesktop ? 22 : 16, // Increased vertical padding
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Progress Indicator - Larger
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 75 : 58, // Increased size
                height: isDesktop ? 75 : 58,
                child: CircularProgressIndicator(
                  value: double.parse(score) / 100,
                  strokeWidth: isDesktop ? 6.5 : 5, // Thicker stroke
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForScore(double.parse(score)),
                  ),
                ),
              ),
              Text(
                score,
                style: TextStyle(
                  fontSize: isDesktop ? 26 : 21, // Larger text
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 14 : 10), // More space
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 15 : 13, // Larger text
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (factors != null && factors!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 10 : 7),
            GestureDetector(
              onTap: () => _showFactorsDialog(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 14 : 10,
                  vertical: isDesktop ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 0.5),
                ),
                child: Text(
                  'Details',
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForScore(double score) {
    if (score < 40) {
      return const Color(0xFFE74C3C);
    } else if (score < 70) {
      return const Color(0xFFF39C12);
    } else {
      return const Color(0xFF27AE60);
    }
  }

  void _showFactorsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: _getColorForScore(double.parse(score)),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$label Analysis',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      children: factors!.map((factor) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      factor.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getColorForScore(
                                        factor.value * 100,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(factor.value * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getColorForScore(
                                          factor.value * 100,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: factor.value,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getColorForScore(factor.value * 100),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4999F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class FactorItem {
  final String name;
  final double value;

  FactorItem({required this.name, required this.value});
}
