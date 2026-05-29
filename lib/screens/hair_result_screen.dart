import 'package:flutter/material.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
import '../Models/hair_analysis_model.dart';

class HairResultScreen extends StatelessWidget {
  final HairAnalysisModel analysis;

  const HairResultScreen({
    super.key,
    required this.analysis,
  });

  Color _gradeColor(int grade) {
    switch (grade) {
      case 1:
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green;
      case 5:
        return Colors.green.shade800;
      default:
        return Colors.grey;
    }
  }

  // ✅ Hair density reference scale
  static final List<Map<String, String>> hairDensityLevels = [
    {
      'title': 'Level 1 · Extremely Low Density',
      'description':
          'Hair appears very sparse with significant scalp visibility. Coverage is minimal and thinning is severe.',
    },
    {
      'title': 'Level 2 · Low Density',
      'description':
          'Noticeable thinning with visible scalp, especially at the crown or part line. Hair lacks volume.',
    },
    {
      'title': 'Level 3 · Medium Density',
      'description':
          'Scalp may be partially visible under strong light. Hair maintains moderate volume and coverage.',
    },
    {
      'title': 'Level 4 · High Density',
      'description':
          'Good overall hair coverage with mild or localized scalp visibility.',
    },
    {
      'title': 'Level 5 · Very High Density',
      'description':
          'Excellent hair coverage with minimal scalp visibility. Hair appears thick and full.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context); // responsive scaling helper
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      appBar: AppBar(
  backgroundColor: const Color(0xFF6B3E3E),
  centerTitle: true,

  // ✅ makes back arrow white
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),

  // ✅ makes title text white
  titleTextStyle: TextStyle(
    color: Colors.white,
    fontSize: r.sp(18), // responsive app bar title
    fontWeight: FontWeight.w600,
  ),

  title: const Text('Hair Analysis Result'),
),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(r.w(24)), // responsive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: r.h(20)),

                    // 🔢 Grade circle — responsive size
                    Container(
                      width: r.w(140),
                      height: r.w(140),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _gradeColor(analysis.densityGrade).withOpacity(0.15),
                        border: Border.all(
                          color: _gradeColor(analysis.densityGrade),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${analysis.densityGrade}',
                          style: TextStyle(
                            fontSize: r.sp(48), // responsive grade number
                            fontWeight: FontWeight.bold,
                            color: _gradeColor(analysis.densityGrade),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: r.h(20)),

                    // 🏷 Label
                    Text(
                      analysis.label,
                      style: TextStyle(
                        fontSize: r.sp(22), // responsive label
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: r.h(12)),

                    // 📝 Description
                    Text(
                      analysis.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.sp(15), // responsive description
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: r.h(32)),
                    const Divider(),
                    SizedBox(height: r.h(20)),

                    // 📊 Density scale title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hair Density Classification',
                        style: TextStyle(
                          fontSize: r.sp(18), // responsive section title
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: r.h(16)),

                    // 📊 Density cards
                    Column(
                      children: List.generate(hairDensityLevels.length, (index) {
                        final level = index + 1;
                        final isUserLevel =
                            level == analysis.densityGrade;

                        return Container(
                          margin: EdgeInsets.only(bottom: r.h(14)),
                          padding: EdgeInsets.all(r.w(16)), // responsive card padding
                          decoration: BoxDecoration(
                            color: isUserLevel
                                ? _gradeColor(level).withOpacity(0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(r.w(14)),
                            border: Border.all(
                              color: isUserLevel
                                  ? _gradeColor(level)
                                  : Colors.grey.shade300,
                              width: isUserLevel ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Level number — responsive circle
                              Container(
                                width: r.w(36),
                                height: r.w(36),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isUserLevel
                                      ? _gradeColor(level)
                                      : Colors.grey.shade300,
                                ),
                                child: Center(
                                  child: Text(
                                    '$level',
                                    style: TextStyle(
                                      color: isUserLevel
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: r.w(14)),

                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hairDensityLevels[index]['title']!,
                                      style: TextStyle(
                                        fontSize: r.sp(15), // responsive
                                        fontWeight: FontWeight.w600,
                                        color: isUserLevel
                                            ? _gradeColor(level)
                                            : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: r.h(6)),
                                    Text(
                                      hairDensityLevels[index]
                                          ['description']!,
                                      style: TextStyle(
                                        fontSize: r.sp(13), // responsive
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // 🔘 Bottom buttons — responsive padding
            Padding(
              padding: EdgeInsets.fromLTRB(r.w(24), r.h(12), r.w(24), r.h(20)),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retake'),
                    ),
                  ),
                  SizedBox(width: r.w(16)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B3E3E),
                        foregroundColor: Colors.white, 

                      ),
                      child: const Text('Done'),
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
