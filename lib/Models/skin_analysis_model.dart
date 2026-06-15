class SkinAnalysisModel {
  final double acneScore;
  final double hydrationScore;
  final double pigmentationScore;
  final double poresScore;
  final double wrinklesScore;
  final int skinAge;
  final int eyeAge;
  final int fitzpatrickType;
  final String? analysisId; // Add this field
  final AcneFactors acneFactors;
  final HydrationFactors hydrationFactors;
  final PigmentationFactors pigmentationFactors;
  final PoresFactors poresFactors;
  final WrinklesFactors wrinklesFactors;

  SkinAnalysisModel({
    required this.acneScore,
    required this.hydrationScore,
    required this.pigmentationScore,
    required this.poresScore,
    required this.wrinklesScore,
    required this.skinAge,
    required this.eyeAge,
    required this.fitzpatrickType,
    this.analysisId, // Add this parameter
    required this.acneFactors,
    required this.hydrationFactors,
    required this.pigmentationFactors,
    required this.poresFactors,
    required this.wrinklesFactors,
  });

  factory SkinAnalysisModel.fromJson(Map<String, dynamic> json) {
    // Handle nested 'analysis' wrapper if present
    final analysis = json['analysis'] ?? json;

    // Get analysis_id from root level of JSON
    final analysisId = json['analysis_id']?.toString();

    final scores = analysis['scores'] ?? {};
    // Try both 'raw_factors' and 'raw_data' keys
    final rawFactors = analysis['raw_factors'] ?? analysis['raw_data'] ?? {};
    final ageAnalysis = analysis['age_analysis'] ?? {};

    return SkinAnalysisModel(
      acneScore: (scores['acne'] as num?)?.toDouble() ?? 0.0,
      hydrationScore: (scores['hydration'] as num?)?.toDouble() ?? 0.0,
      pigmentationScore: (scores['pigmentation'] as num?)?.toDouble() ?? 0.0,
      poresScore: (scores['pores'] as num?)?.toDouble() ?? 0.0,
      wrinklesScore: (scores['wrinkles'] as num?)?.toDouble() ?? 0.0,
      skinAge: (ageAnalysis['skin_age'] as num?)?.toInt() ?? 0,
      eyeAge: (ageAnalysis['eye_age'] as num?)?.toInt() ?? 0,
      fitzpatrickType: (ageAnalysis['fitzpatrick_type'] as num?)?.toInt() ?? 1,
      analysisId: analysisId, // Add this
      acneFactors: AcneFactors.fromJson(rawFactors['acne'] ?? {}),
      hydrationFactors: HydrationFactors.fromJson(
        rawFactors['hydration'] ?? {},
      ),
      pigmentationFactors: PigmentationFactors.fromJson(
        rawFactors['pigmentation'] ?? {},
      ),
      poresFactors: PoresFactors.fromJson(rawFactors['pores'] ?? {}),
      wrinklesFactors: WrinklesFactors.fromJson(rawFactors['wrinkles'] ?? {}),
    );
  }

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
      'analysis_id': analysisId, // Add this
      'scores': {
        'acne': acneScore,
        'hydration': hydrationScore,
        'pigmentation': pigmentationScore,
        'pores': poresScore,
        'wrinkles': wrinklesScore,
      },
      'age_analysis': {
        'skin_age': skinAge,
        'eye_age': eyeAge,
        'fitzpatrick_type': fitzpatrickType,
      },
      'raw_data': {
        'acne': acneFactors.toJson(),
        'hydration': hydrationFactors.toJson(),
        'pigmentation': pigmentationFactors.toJson(),
        'pores': poresFactors.toJson(),
        'wrinkles': wrinklesFactors.toJson(),
      },
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
      activeAcne: (json['active_acne'] as num?)?.toDouble() ?? 0.0,
      comedones: (json['comedones'] as num?)?.toDouble() ?? 0.0,
      congestion: (json['congestion'] as num?)?.toDouble() ?? 0.0,
      cysticAcne: (json['cystic_acne'] as num?)?.toDouble() ?? 0.0,
      inflammation: (json['inflammation'] as num?)?.toDouble() ?? 0.0,
      oiliness: (json['oiliness'] as num?)?.toDouble() ?? 0.0,
      scarring: (json['scarring'] as num?)?.toDouble() ?? 0.0,
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
      fineLines: (json['fine_lines'] as num?)?.toDouble() ?? 0.0,
      flakiness: (json['flakiness'] as num?)?.toDouble() ?? 0.0,
      oilBalance: (json['oil_balance'] as num?)?.toDouble() ?? 0.0,
      radiance: (json['radiance'] as num?)?.toDouble() ?? 0.0,
      texture: (json['texture'] as num?)?.toDouble() ?? 0.0,
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
      darkSpots: (json['dark_spots'] as num?)?.toDouble() ?? 0.0,
      hyperpigmentation: (json['hyperpigmentation'] as num?)?.toDouble() ?? 0.0,
      melaninUnevenness:
          (json['melanin_unevenness'] as num?)?.toDouble() ?? 0.0,
      overallEvenness: (json['overall_evenness'] as num?)?.toDouble() ?? 0.0,
      redness: (json['redness'] as num?)?.toDouble() ?? 0.0,
      underEyePigmentation:
          (json['under_eye_pigmentation'] as num?)?.toDouble() ?? 0.0,
      uvDamage: (json['uv_damage'] as num?)?.toDouble() ?? 0.0,
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

class PoresFactors {
  final double cheekProminence;
  final double cloggedPores;
  final double enlargedPores;
  final double size;
  final double tZoneProminence;
  final double textureRoughness;
  final double visibility;

  PoresFactors({
    required this.cheekProminence,
    required this.cloggedPores,
    required this.enlargedPores,
    required this.size,
    required this.tZoneProminence,
    required this.textureRoughness,
    required this.visibility,
  });

  factory PoresFactors.fromJson(Map<String, dynamic> json) {
    return PoresFactors(
      cheekProminence: (json['cheek_prominence'] as num?)?.toDouble() ?? 0.0,
      cloggedPores: (json['clogged_pores'] as num?)?.toDouble() ?? 0.0,
      enlargedPores: (json['enlarged_pores'] as num?)?.toDouble() ?? 0.0,
      size: (json['size'] as num?)?.toDouble() ?? 0.0,
      tZoneProminence: (json['t_zone_prominence'] as num?)?.toDouble() ?? 0.0,
      textureRoughness: (json['texture_roughness'] as num?)?.toDouble() ?? 0.0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cheek_prominence': cheekProminence,
      'clogged_pores': cloggedPores,
      'enlarged_pores': enlargedPores,
      'size': size,
      't_zone_prominence': tZoneProminence,
      'texture_roughness': textureRoughness,
      'visibility': visibility,
    };
  }
}

class WrinklesFactors {
  final double crowsFeet;
  final double depth;
  final double dynamicWrinkles;
  final double foreheadLines;
  final double frownLines;
  final double lipLines;
  final double marionelleLines;
  final double nasolabialFolds;
  final double neckLines;
  final double overallSeverity;
  final double staticWrinkles;
  final double underEyeWrinkles;

  WrinklesFactors({
    required this.crowsFeet,
    required this.depth,
    required this.dynamicWrinkles,
    required this.foreheadLines,
    required this.frownLines,
    required this.lipLines,
    required this.marionelleLines,
    required this.nasolabialFolds,
    required this.neckLines,
    required this.overallSeverity,
    required this.staticWrinkles,
    required this.underEyeWrinkles,
  });

  factory WrinklesFactors.fromJson(Map<String, dynamic> json) {
    return WrinklesFactors(
      crowsFeet: (json['crows_feet'] as num?)?.toDouble() ?? 0.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
      dynamicWrinkles: (json['dynamic_wrinkles'] as num?)?.toDouble() ?? 0.0,
      foreheadLines: (json['forehead_lines'] as num?)?.toDouble() ?? 0.0,
      frownLines: (json['frown_lines'] as num?)?.toDouble() ?? 0.0,
      lipLines: (json['lip_lines'] as num?)?.toDouble() ?? 0.0,
      marionelleLines: (json['marionette_lines'] as num?)?.toDouble() ?? 0.0,
      nasolabialFolds: (json['nasolabial_folds'] as num?)?.toDouble() ?? 0.0,
      neckLines: (json['neck_lines'] as num?)?.toDouble() ?? 0.0,
      overallSeverity: (json['overall_severity'] as num?)?.toDouble() ?? 0.0,
      staticWrinkles: (json['static_wrinkles'] as num?)?.toDouble() ?? 0.0,
      underEyeWrinkles: (json['under_eye_wrinkles'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crows_feet': crowsFeet,
      'depth': depth,
      'dynamic_wrinkles': dynamicWrinkles,
      'forehead_lines': foreheadLines,
      'frown_lines': frownLines,
      'lip_lines': lipLines,
      'marionette_lines': marionelleLines,
      'nasolabial_folds': nasolabialFolds,
      'neck_lines': neckLines,
      'overall_severity': overallSeverity,
      'static_wrinkles': staticWrinkles,
      'under_eye_wrinkles': underEyeWrinkles,
    };
  }
}

// Helper class for displaying factor items in UI
class FactorItem {
  final String name;
  final double value;

  FactorItem({required this.name, required this.value});
}
