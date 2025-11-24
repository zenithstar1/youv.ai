class SkinAnalysisModel {
  final double acneScore;
  final double hydrationScore;
  final double pigmentationScore;
  final int skinAge;
  final int eyeAge;
  final int fitzpatrickType;
  final AcneFactors acneFactors;
  final HydrationFactors hydrationFactors;
  final PigmentationFactors pigmentationFactors;

  SkinAnalysisModel({
    required this.acneScore,
    required this.hydrationScore,
    required this.pigmentationScore,
    required this.skinAge,
    required this.eyeAge,
    required this.fitzpatrickType,
    required this.acneFactors,
    required this.hydrationFactors,
    required this.pigmentationFactors,
  });

  factory SkinAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SkinAnalysisModel(
      acneScore: (json['acne_score'] as num).toDouble(),
      hydrationScore: (json['hydration_score'] as num).toDouble(),
      pigmentationScore: (json['pigmentation_score'] as num).toDouble(),
      skinAge: json['skin_age'] as int,
      eyeAge: json['eye_age'] as int,
      fitzpatrickType: json['fitzpatrick_type'] as int,
      acneFactors: AcneFactors.fromJson(json['acne_factors']),
      hydrationFactors: HydrationFactors.fromJson(json['hydration_factors']),
      pigmentationFactors: PigmentationFactors.fromJson(
        json['pigmentation_factors'],
      ),
    );
  }

  // Get skin type based on Fitzpatrick scale
  String get skinType {
    switch (fitzpatrickType) {
      case 1:
        return 'Very Fair';
      case 2:
        return 'Fair';
      case 3:
        return 'Medium';
      case 4:
        return 'Olive';
      case 5:
        return 'Brown';
      case 6:
        return 'Dark Brown';
      default:
        return 'Normal';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'acne_score': acneScore,
      'hydration_score': hydrationScore,
      'pigmentation_score': pigmentationScore,
      'skin_age': skinAge,
      'eye_age': eyeAge,
      'fitzpatrick_type': fitzpatrickType,
      'acne_factors': acneFactors.toJson(),
      'hydration_factors': hydrationFactors.toJson(),
      'pigmentation_factors': pigmentationFactors.toJson(),
    };
  }
}

class AcneFactors {
  final double activeAcne;
  final double comedones;
  final double congestion;
  final double cysticAcne;
  final double inflammation;
  final double oiliness;
  final double scarring;

  AcneFactors({
    required this.activeAcne,
    required this.comedones,
    required this.congestion,
    required this.cysticAcne,
    required this.inflammation,
    required this.oiliness,
    required this.scarring,
  });

  factory AcneFactors.fromJson(Map<String, dynamic> json) {
    return AcneFactors(
      activeAcne: (json['active_acne'] as num).toDouble(),
      comedones: (json['comedones'] as num).toDouble(),
      congestion: (json['congestion'] as num).toDouble(),
      cysticAcne: (json['cystic_acne'] as num).toDouble(),
      inflammation: (json['inflammation'] as num).toDouble(),
      oiliness: (json['oiliness'] as num).toDouble(),
      scarring: (json['scarring'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_acne': activeAcne,
      'comedones': comedones,
      'congestion': congestion,
      'cystic_acne': cysticAcne,
      'inflammation': inflammation,
      'oiliness': oiliness,
      'scarring': scarring,
    };
  }
}

class HydrationFactors {
  final double fineLines;
  final double flakiness;
  final double oilBalance;
  final double radiance;
  final double texture;

  HydrationFactors({
    required this.fineLines,
    required this.flakiness,
    required this.oilBalance,
    required this.radiance,
    required this.texture,
  });

  factory HydrationFactors.fromJson(Map<String, dynamic> json) {
    return HydrationFactors(
      fineLines: (json['fine_lines'] as num).toDouble(),
      flakiness: (json['flakiness'] as num).toDouble(),
      oilBalance: (json['oil_balance'] as num).toDouble(),
      radiance: (json['radiance'] as num).toDouble(),
      texture: (json['texture'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fine_lines': fineLines,
      'flakiness': flakiness,
      'oil_balance': oilBalance,
      'radiance': radiance,
      'texture': texture,
    };
  }
}

class PigmentationFactors {
  final double darkSpots;
  final double hyperpigmentation;
  final double melaninUnevenness;
  final double overallEvenness;
  final double redness;
  final double underEyePigmentation;
  final double uvDamage;

  PigmentationFactors({
    required this.darkSpots,
    required this.hyperpigmentation,
    required this.melaninUnevenness,
    required this.overallEvenness,
    required this.redness,
    required this.underEyePigmentation,
    required this.uvDamage,
  });

  factory PigmentationFactors.fromJson(Map<String, dynamic> json) {
    return PigmentationFactors(
      darkSpots: (json['dark_spots'] as num).toDouble(),
      hyperpigmentation: (json['hyperpigmentation'] as num).toDouble(),
      melaninUnevenness: (json['melanin_unevenness'] as num).toDouble(),
      overallEvenness: (json['overall_evenness'] as num).toDouble(),
      redness: (json['redness'] as num).toDouble(),
      underEyePigmentation: (json['under_eye_pigmentation'] as num).toDouble(),
      uvDamage: (json['uv_damage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dark_spots': darkSpots,
      'hyperpigmentation': hyperpigmentation,
      'melanin_unevenness': melaninUnevenness,
      'overall_evenness': overallEvenness,
      'redness': redness,
      'under_eye_pigmentation': underEyePigmentation,
      'uv_damage': uvDamage,
    };
  }
}
