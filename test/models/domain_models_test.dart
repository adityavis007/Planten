import 'package:flutter_test/flutter_test.dart';
import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/crop.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';

void main() {
  group('ConfidenceCategory (PRD Section 7.6)', () {
    test('categorizes score according to PRD thresholds', () {
      // > 0.85 -> Likely
      expect(ConfidenceCategory.fromScore(0.95), ConfidenceCategory.likely);
      expect(ConfidenceCategory.fromScore(0.8501), ConfidenceCategory.likely);

      // 0.60 .. 0.85 -> Possible
      expect(ConfidenceCategory.fromScore(0.85), ConfidenceCategory.possible);
      expect(ConfidenceCategory.fromScore(0.75), ConfidenceCategory.possible);
      expect(ConfidenceCategory.fromScore(0.60), ConfidenceCategory.possible);

      // < 0.60 -> Uncertain
      expect(ConfidenceCategory.fromScore(0.5999), ConfidenceCategory.uncertain);
      expect(ConfidenceCategory.fromScore(0.30), ConfidenceCategory.uncertain);
      expect(ConfidenceCategory.fromScore(0.0), ConfidenceCategory.uncertain);
    });

    test('serializes and deserializes correctly', () {
      for (final cat in ConfidenceCategory.values) {
        final json = cat.toJson();
        expect(ConfidenceCategory.fromJson(json), cat);
      }

      // Case insensitivity & fallback
      expect(ConfidenceCategory.fromJson('LIKELY'), ConfidenceCategory.likely);
      expect(ConfidenceCategory.fromJson('unknown_value'), ConfidenceCategory.uncertain);
    });

    test('exposes localized labels and helper getters', () {
      expect(ConfidenceCategory.likely.labelEn, 'Likely');
      expect(ConfidenceCategory.likely.labelHi, 'संभावित');
      expect(ConfidenceCategory.likely.isLikely, isTrue);
      expect(ConfidenceCategory.likely.isPossible, isFalse);
      expect(ConfidenceCategory.likely.isUncertain, isFalse);

      expect(ConfidenceCategory.possible.isPossible, isTrue);
      expect(ConfidenceCategory.uncertain.isUncertain, isTrue);
    });
  });

  group('SeverityLevel', () {
    test('serializes and deserializes correctly', () {
      for (final level in SeverityLevel.values) {
        final json = level.toJson();
        expect(SeverityLevel.fromJson(json), level);
      }

      // Case insensitivity & fallback
      expect(SeverityLevel.fromJson('HIGH'), SeverityLevel.high);
      expect(SeverityLevel.fromJson('healthy'), SeverityLevel.healthy);
      expect(SeverityLevel.fromJson('invalid'), SeverityLevel.medium);
    });

    test('exposes localized labels and boolean getters', () {
      expect(SeverityLevel.healthy.isHealthy, isTrue);
      expect(SeverityLevel.healthy.labelEn, 'Healthy');
      expect(SeverityLevel.healthy.labelHi, 'स्वस्थ');

      expect(SeverityLevel.low.isLow, isTrue);
      expect(SeverityLevel.medium.isMedium, isTrue);
      expect(SeverityLevel.high.isHigh, isTrue);
    });
  });

  group('Crop Model', () {
    const testCrop = Crop(
      id: 'tomato',
      nameEn: 'Tomato',
      nameHi: 'टमाटर',
      iconAssetPath: 'assets/icons/crops/tomato.png',
    );

    test('serializes to JSON and deserializes back identically', () {
      final json = testCrop.toJson();
      final fromJson = Crop.fromJson(json);

      expect(fromJson, equals(testCrop));
      expect(fromJson.id, 'tomato');
      expect(fromJson.nameEn, 'Tomato');
      expect(fromJson.nameHi, 'टमाटर');
      expect(fromJson.iconAssetPath, 'assets/icons/crops/tomato.png');
    });

    test('supports localizedName', () {
      expect(testCrop.localizedName('en'), 'Tomato');
      expect(testCrop.localizedName('hi'), 'टमाटर');
    });

    test('copyWith creates modified clone', () {
      final modified = testCrop.copyWith(nameEn: 'Cherry Tomato');
      expect(modified.nameEn, 'Cherry Tomato');
      expect(modified.id, testCrop.id);
      expect(modified.nameHi, testCrop.nameHi);
    });

    test('initialCrops contains all 5 launch crops', () {
      expect(Crop.initialCrops.length, 5);
      final ids = Crop.initialCrops.map((c) => c.id).toSet();
      expect(ids, containsAll(['tomato', 'potato', 'wheat', 'chili', 'cotton']));
    });
  });

  group('TreatmentGuidance Model', () {
    const testGuidance = TreatmentGuidance(
      diseaseId: 'tomato_early_blight',
      crop: 'tomato',
      nameEn: 'Tomato Early Blight',
      nameHi: 'टमाटर का अगेती झुलसा',
      symptomsEn: 'Dark brown spots with rings.',
      symptomsHi: 'गोल भूरे छल्लेदार धब्बे।',
      culturalStepsEn: ['Prune infected leaves.', 'Avoid overhead watering.'],
      culturalStepsHi: ['संक्रमित पत्तियों को नष्ट करें।', 'पौधों के ऊपर से पानी न डालें।'],
      managementCategory: 'fungal',
      severityLevel: 'medium',
      disclaimerEn: 'Consult local KVK.',
      disclaimerHi: 'कृषि अधिकारी से संपर्क करें।',
    );

    test('serializes to JSON and deserializes back identically', () {
      final json = testGuidance.toJson();
      final fromJson = TreatmentGuidance.fromJson(json);

      expect(fromJson, equals(testGuidance));
      expect(fromJson.severity, SeverityLevel.medium);
    });

    test('returns localized fields correctly', () {
      expect(testGuidance.localizedName('hi'), 'टमाटर का अगेती झुलसा');
      expect(testGuidance.localizedName('en'), 'Tomato Early Blight');
      expect(testGuidance.localizedSymptoms('hi'), 'गोल भूरे छल्लेदार धब्बे।');
      expect(testGuidance.localizedCulturalSteps('en').length, 2);
      expect(testGuidance.localizedDisclaimer('hi'), 'कृषि अधिकारी से संपर्क करें।');
    });

    test('copyWith creates modified clone', () {
      final updated = testGuidance.copyWith(severityLevel: 'high');
      expect(updated.severityLevel, 'high');
      expect(updated.severity, SeverityLevel.high);
      expect(updated.diseaseId, testGuidance.diseaseId);
    });

    test('supports nutrition and fertilizer advisory fields and localized getters', () {
      final enriched = testGuidance.copyWith(
        organicNutritionEn: 'Apply neem cake and vermicompost.',
        organicNutritionHi: 'नीम खली व केंचुआ खाद डालें।',
        fertilizerClassEn: 'Balanced NPK and MOP.',
        fertilizerClassHi: 'संतुलित NPK व पोटाश दें।',
        nutritionDisclaimerEn: 'Soil test required.',
        nutritionDisclaimerHi: 'मिट्टी की जांच जरूरी है।',
      );

      expect(enriched.hasNutritionAdvisory, isTrue);
      expect(enriched.localizedOrganicNutrition('en'), 'Apply neem cake and vermicompost.');
      expect(enriched.localizedOrganicNutrition('hi'), 'नीम खली व केंचुआ खाद डालें।');
      expect(enriched.localizedFertilizerClass('en'), 'Balanced NPK and MOP.');
      expect(enriched.localizedFertilizerClass('hi'), 'संतुलित NPK व पोटाश दें।');
      expect(enriched.localizedNutritionDisclaimer('en'), 'Soil test required.');
      expect(enriched.localizedNutritionDisclaimer('hi'), 'मिट्टी की जांच जरूरी है।');

      // Test serialization with nutrition
      final json = enriched.toJson();
      final restored = TreatmentGuidance.fromJson(json);
      expect(restored, equals(enriched));
      expect(restored.organicNutritionEn, 'Apply neem cake and vermicompost.');
    });
  });

  group('DiagnosisResult Model', () {
    final now = DateTime.utc(2026, 9, 9, 12, 0, 0);

    const testGuidance = TreatmentGuidance(
      diseaseId: 'tomato_early_blight',
      crop: 'tomato',
      nameEn: 'Tomato Early Blight',
      nameHi: 'टमाटर का अगेती झुलसा',
      symptomsEn: 'Dark brown spots.',
      symptomsHi: 'गोल भूरे धब्बे।',
      culturalStepsEn: ['Prune leaves.'],
      culturalStepsHi: ['पत्तियों को हटाएं।'],
      managementCategory: 'fungal',
      severityLevel: 'medium',
      disclaimerEn: 'Consult KVK.',
      disclaimerHi: 'कृषि केंद्र से संपर्क करें।',
    );

    final testResult = DiagnosisResult(
      id: 'scan-12345',
      cropId: 'tomato',
      diseaseId: 'tomato_early_blight',
      diseaseNameEn: 'Tomato Early Blight',
      diseaseNameHi: 'टमाटर का अगेती झुलसा',
      confidenceScore: 0.92,
      severity: SeverityLevel.medium,
      timestamp: now,
      localImagePath: '/data/user/0/com.example.planten/app_flutter/scans/leaf_01.jpg',
      remoteImageUrl: 'https://storage.googleapis.com/planten/scans/leaf_01.jpg',
      isSynced: true,
      guidance: testGuidance,
    );

    test('serializes to JSON and deserializes back identically', () {
      final json = testResult.toJson();
      final fromJson = DiagnosisResult.fromJson(json);

      expect(fromJson, equals(testResult));
      expect(fromJson.confidenceCategory, ConfidenceCategory.likely);
      expect(fromJson.confidencePercentage, 92);
      expect(fromJson.isHealthy, isFalse);
      expect(fromJson.isSynced, isTrue);
      expect(fromJson.guidance, isNotNull);
      expect(fromJson.guidance?.diseaseId, 'tomato_early_blight');
    });

    test('correctly identifies healthy results', () {
      final healthyResult = DiagnosisResult(
        id: 'scan-healthy-1',
        cropId: 'wheat',
        diseaseId: 'wheat_healthy',
        diseaseNameEn: 'Healthy Wheat',
        diseaseNameHi: 'स्वस्थ गेहूं',
        confidenceScore: 0.98,
        severity: SeverityLevel.healthy,
        timestamp: now,
        localImagePath: '/data/user/0/leaf.jpg',
      );

      expect(healthyResult.isHealthy, isTrue);
      expect(healthyResult.confidenceCategory, ConfidenceCategory.likely);
    });

    test('localizes disease name correctly', () {
      expect(testResult.localizedDiseaseName('en'), 'Tomato Early Blight');
      expect(testResult.localizedDiseaseName('hi'), 'टमाटर का अगेती झुलसा');
    });

    test('copyWith creates modified clone', () {
      final updated = testResult.copyWith(isSynced: false, clearRemoteImageUrl: true);
      expect(updated.isSynced, isFalse);
      expect(updated.remoteImageUrl, isNull);
      expect(updated.id, testResult.id);
      expect(updated.confidenceScore, 0.92);
    });
  });
}
