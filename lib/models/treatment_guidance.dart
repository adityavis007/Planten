import 'package:flutter/foundation.dart';
import 'severity_level.dart';

/// Immutable domain model representing verified disease treatment and management guidance,
/// enriched with generic, scientific fertilizer and crop nutrition advisories.
@immutable
class TreatmentGuidance {
  final String diseaseId;
  final String crop;
  final String nameEn;
  final String nameHi;
  final String symptomsEn;
  final String symptomsHi;
  final List<String> culturalStepsEn;
  final List<String> culturalStepsHi;
  final String managementCategory;
  final String severityLevel;
  final String disclaimerEn;
  final String disclaimerHi;

  /// Optional generic bio & organic nutrition recommendations.
  final String? organicNutritionEn;
  final String? organicNutritionHi;

  /// Optional generic chemical class, NPK balance, and micronutrient recommendations.
  final String? fertilizerClassEn;
  final String? fertilizerClassHi;

  /// Optional safety disclaimer regarding fertilizer dosage and local agricultural consultation.
  final String? nutritionDisclaimerEn;
  final String? nutritionDisclaimerHi;

  const TreatmentGuidance({
    required this.diseaseId,
    required this.crop,
    required this.nameEn,
    required this.nameHi,
    required this.symptomsEn,
    required this.symptomsHi,
    required this.culturalStepsEn,
    required this.culturalStepsHi,
    required this.managementCategory,
    required this.severityLevel,
    required this.disclaimerEn,
    required this.disclaimerHi,
    this.organicNutritionEn,
    this.organicNutritionHi,
    this.fertilizerClassEn,
    this.fertilizerClassHi,
    this.nutritionDisclaimerEn,
    this.nutritionDisclaimerHi,
  });

  /// Factory constructor to deserialize [TreatmentGuidance] from a JSON map.
  factory TreatmentGuidance.fromJson(Map<String, dynamic> json) {
    return TreatmentGuidance(
      diseaseId: (json['disease_id'] ?? json['diseaseId']) as String,
      crop: json['crop'] as String,
      nameEn: (json['name_en'] ?? json['nameEn']) as String,
      nameHi: (json['name_hi'] ?? json['nameHi']) as String,
      symptomsEn: (json['symptoms_en'] ?? json['symptomsEn']) as String,
      symptomsHi: (json['symptoms_hi'] ?? json['symptomsHi']) as String,
      culturalStepsEn: List<String>.from(
        (json['cultural_steps_en'] ?? json['culturalStepsEn']) as Iterable,
      ),
      culturalStepsHi: List<String>.from(
        (json['cultural_steps_hi'] ?? json['culturalStepsHi']) as Iterable,
      ),
      managementCategory:
          (json['management_category'] ?? json['managementCategory']) as String,
      severityLevel:
          (json['severity_level'] ?? json['severityLevel']) as String,
      disclaimerEn: (json['disclaimer_en'] ?? json['disclaimerEn']) as String,
      disclaimerHi: (json['disclaimer_hi'] ?? json['disclaimerHi']) as String,
      organicNutritionEn: (json['organic_nutrition_en'] ??
          json['organicNutritionEn'] ??
          json['organicNutrition']) as String?,
      organicNutritionHi: (json['organic_nutrition_hi'] ??
          json['organicNutritionHi']) as String?,
      fertilizerClassEn: (json['fertilizer_class_en'] ??
          json['fertilizerClassEn'] ??
          json['fertilizerClass']) as String?,
      fertilizerClassHi: (json['fertilizer_class_hi'] ??
          json['fertilizerClassHi']) as String?,
      nutritionDisclaimerEn: (json['nutrition_disclaimer_en'] ??
          json['nutritionDisclaimerEn'] ??
          json['nutritionDisclaimer']) as String?,
      nutritionDisclaimerHi: (json['nutrition_disclaimer_hi'] ??
          json['nutritionDisclaimerHi']) as String?,
    );
  }

  /// Deserialization alias matching standard repository conventions.
  factory TreatmentGuidance.fromMap(Map<String, dynamic> map) =>
      TreatmentGuidance.fromJson(map);

  /// Serializes [TreatmentGuidance] to a JSON map matching `treatment_data.json` schema.
  Map<String, dynamic> toJson() {
    return {
      'disease_id': diseaseId,
      'crop': crop,
      'name_en': nameEn,
      'name_hi': nameHi,
      'symptoms_en': symptomsEn,
      'symptoms_hi': symptomsHi,
      'cultural_steps_en': culturalStepsEn,
      'cultural_steps_hi': culturalStepsHi,
      'management_category': managementCategory,
      'severity_level': severityLevel,
      'disclaimer_en': disclaimerEn,
      'disclaimer_hi': disclaimerHi,
      if (organicNutritionEn != null) 'organic_nutrition_en': organicNutritionEn,
      if (organicNutritionHi != null) 'organic_nutrition_hi': organicNutritionHi,
      if (fertilizerClassEn != null) 'fertilizer_class_en': fertilizerClassEn,
      if (fertilizerClassHi != null) 'fertilizer_class_hi': fertilizerClassHi,
      if (nutritionDisclaimerEn != null)
        'nutrition_disclaimer_en': nutritionDisclaimerEn,
      if (nutritionDisclaimerHi != null)
        'nutrition_disclaimer_hi': nutritionDisclaimerHi,
    };
  }

  /// Strongly-typed severity level enum parsed from [severityLevel].
  SeverityLevel get severity => SeverityLevel.fromJson(severityLevel);

  /// Convenient fallback getters for default English access.
  String? get organicNutrition => organicNutritionEn ?? organicNutritionHi;
  String? get fertilizerClass => fertilizerClassEn ?? fertilizerClassHi;
  String? get nutritionDisclaimer => nutritionDisclaimerEn ?? nutritionDisclaimerHi;

  /// Whether this guidance item contains non-empty nutrition and fertilizer advice.
  bool get hasNutritionAdvisory =>
      (organicNutritionEn?.trim().isNotEmpty ?? false) ||
      (organicNutritionHi?.trim().isNotEmpty ?? false) ||
      (fertilizerClassEn?.trim().isNotEmpty ?? false) ||
      (fertilizerClassHi?.trim().isNotEmpty ?? false);

  /// Localized disease name based on language code (`'hi'` or `'en'`).
  String localizedName(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? nameHi : nameEn;
  }

  /// Localized symptoms based on language code (`'hi'` or `'en'`).
  String localizedSymptoms(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? symptomsHi : symptomsEn;
  }

  /// Localized cultural steps based on language code (`'hi'` or `'en'`).
  List<String> localizedCulturalSteps(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? culturalStepsHi : culturalStepsEn;
  }

  /// Localized disclaimer based on language code (`'hi'` or `'en'`).
  String localizedDisclaimer(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? disclaimerHi : disclaimerEn;
  }

  /// Localized bio/organic nutrition advisory based on language code.
  String? localizedOrganicNutrition(String languageCode) {
    return languageCode.toLowerCase() == 'hi'
        ? (organicNutritionHi ?? organicNutritionEn)
        : (organicNutritionEn ?? organicNutritionHi);
  }

  /// Localized generic fertilizer class based on language code.
  String? localizedFertilizerClass(String languageCode) {
    return languageCode.toLowerCase() == 'hi'
        ? (fertilizerClassHi ?? fertilizerClassEn)
        : (fertilizerClassEn ?? fertilizerClassHi);
  }

  /// Localized nutrition disclaimer based on language code.
  String? localizedNutritionDisclaimer(String languageCode) {
    return languageCode.toLowerCase() == 'hi'
        ? (nutritionDisclaimerHi ?? nutritionDisclaimerEn)
        : (nutritionDisclaimerEn ?? nutritionDisclaimerHi);
  }

  /// Creates a copy of this [TreatmentGuidance] with specified fields replaced.
  TreatmentGuidance copyWith({
    String? diseaseId,
    String? crop,
    String? nameEn,
    String? nameHi,
    String? symptomsEn,
    String? symptomsHi,
    List<String>? culturalStepsEn,
    List<String>? culturalStepsHi,
    String? managementCategory,
    String? severityLevel,
    String? disclaimerEn,
    String? disclaimerHi,
    String? organicNutritionEn,
    String? organicNutritionHi,
    String? fertilizerClassEn,
    String? fertilizerClassHi,
    String? nutritionDisclaimerEn,
    String? nutritionDisclaimerHi,
  }) {
    return TreatmentGuidance(
      diseaseId: diseaseId ?? this.diseaseId,
      crop: crop ?? this.crop,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      symptomsEn: symptomsEn ?? this.symptomsEn,
      symptomsHi: symptomsHi ?? this.symptomsHi,
      culturalStepsEn: culturalStepsEn ?? this.culturalStepsEn,
      culturalStepsHi: culturalStepsHi ?? this.culturalStepsHi,
      managementCategory: managementCategory ?? this.managementCategory,
      severityLevel: severityLevel ?? this.severityLevel,
      disclaimerEn: disclaimerEn ?? this.disclaimerEn,
      disclaimerHi: disclaimerHi ?? this.disclaimerHi,
      organicNutritionEn: organicNutritionEn ?? this.organicNutritionEn,
      organicNutritionHi: organicNutritionHi ?? this.organicNutritionHi,
      fertilizerClassEn: fertilizerClassEn ?? this.fertilizerClassEn,
      fertilizerClassHi: fertilizerClassHi ?? this.fertilizerClassHi,
      nutritionDisclaimerEn:
          nutritionDisclaimerEn ?? this.nutritionDisclaimerEn,
      nutritionDisclaimerHi:
          nutritionDisclaimerHi ?? this.nutritionDisclaimerHi,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreatmentGuidance &&
        other.diseaseId == diseaseId &&
        other.crop == crop &&
        other.nameEn == nameEn &&
        other.nameHi == nameHi &&
        other.symptomsEn == symptomsEn &&
        other.symptomsHi == symptomsHi &&
        listEquals(other.culturalStepsEn, culturalStepsEn) &&
        listEquals(other.culturalStepsHi, culturalStepsHi) &&
        other.managementCategory == managementCategory &&
        other.severityLevel == severityLevel &&
        other.disclaimerEn == disclaimerEn &&
        other.disclaimerHi == disclaimerHi &&
        other.organicNutritionEn == organicNutritionEn &&
        other.organicNutritionHi == organicNutritionHi &&
        other.fertilizerClassEn == fertilizerClassEn &&
        other.fertilizerClassHi == fertilizerClassHi &&
        other.nutritionDisclaimerEn == nutritionDisclaimerEn &&
        other.nutritionDisclaimerHi == nutritionDisclaimerHi;
  }

  @override
  int get hashCode {
    return Object.hash(
      diseaseId,
      crop,
      nameEn,
      nameHi,
      symptomsEn,
      symptomsHi,
      Object.hashAll(culturalStepsEn),
      Object.hashAll(culturalStepsHi),
      managementCategory,
      severityLevel,
      disclaimerEn,
      disclaimerHi,
      organicNutritionEn,
      organicNutritionHi,
      fertilizerClassEn,
      fertilizerClassHi,
      nutritionDisclaimerEn,
      nutritionDisclaimerHi,
    );
  }
}
