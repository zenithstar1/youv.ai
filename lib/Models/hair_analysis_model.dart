class HairAnalysisModel {
  final int densityGrade;
  final String label;
  final String description;

  HairAnalysisModel({
    required this.densityGrade,
    required this.label,
    required this.description,
  });

  factory HairAnalysisModel.fromJson(Map<String, dynamic> json) {
    final grading = json['grading'];

    return HairAnalysisModel(
      densityGrade: grading['density_grade'],
      label: grading['label'],
      description: grading['description'],
    );
  }
}
