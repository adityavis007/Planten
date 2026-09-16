import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/services/knowledge_base_service.dart';

void main() {
  late List<TreatmentGuidance> allGuidance;
  late KnowledgeBaseService knowledgeBaseService;

  setUpAll(() {
    final file = File('assets/knowledge_base/treatment_data.json');
    expect(file.existsSync(), isTrue,
        reason: 'assets/knowledge_base/treatment_data.json must exist');

    final jsonString = file.readAsStringSync();
    final List<dynamic> rawList = json.decode(jsonString);
    allGuidance = rawList.map((j) => TreatmentGuidance.fromJson(j)).toList();
    knowledgeBaseService = KnowledgeBaseService(initialGuidance: allGuidance);
  });

  group('Knowledge Base & Safety Guardrails (Task 56)', () {
    test('knowledge base is successfully initialized with all 15 classes', () {
      expect(knowledgeBaseService.isInitialized, isTrue);
      expect(allGuidance.length, equals(15));
    });

    test('retrieves guidance by disease ID for all supported conditions', () {
      final expectedDiseases = [
        'tomato_early_blight',
        'tomato_late_blight',
        'tomato_leaf_curl',
        'tomato_healthy',
        'potato_early_blight',
        'potato_late_blight',
        'potato_healthy',
        'wheat_yellow_rust',
        'wheat_powdery_mildew',
        'wheat_healthy',
        'chili_leaf_curl',
        'chili_bacterial_spot',
        'chili_healthy',
        'cotton_bacterial_blight',
        'cotton_healthy',
      ];

      for (final diseaseId in expectedDiseases) {
        final guidance = knowledgeBaseService.getGuidanceByDiseaseId(diseaseId);
        expect(guidance, isNotNull,
            reason: 'Guidance must exist for disease ID: $diseaseId');
        expect(guidance!.diseaseId, equals(diseaseId));
        expect(guidance.nameEn.trim(), isNotEmpty);
        expect(guidance.nameHi.trim(), isNotEmpty);
        expect(guidance.symptomsEn.trim(), isNotEmpty);
        expect(guidance.symptomsHi.trim(), isNotEmpty);
      }
    });

    test('returns null when querying for unknown disease ID', () {
      final guidance = knowledgeBaseService.getGuidanceByDiseaseId('unknown_crop_disease');
      expect(guidance, isNull);
    });

    test('covers all 5 launch crops with correct crop-specific groupings', () {
      const launchCrops = ['tomato', 'potato', 'wheat', 'chili', 'cotton'];

      for (final cropId in launchCrops) {
        final cropGuidance = knowledgeBaseService.getGuidanceForCrop(cropId);
        expect(cropGuidance, isNotEmpty,
            reason: 'Crop $cropId must have at least one guidance entry');

        for (final item in cropGuidance) {
          expect(item.crop, equals(cropId));
        }
      }
    });

    test('every disease entry provides at least 2 cultural management steps in EN and HI', () {
      for (final item in allGuidance) {
        expect(item.culturalStepsEn.length, greaterThanOrEqualTo(2),
            reason: '${item.diseaseId} must have at least 2 cultural steps in English');
        expect(item.culturalStepsHi.length, greaterThanOrEqualTo(2),
            reason: '${item.diseaseId} must have at least 2 cultural steps in Hindi');

        for (final step in item.culturalStepsEn) {
          expect(step.trim().length, greaterThan(10),
              reason: 'English cultural step should be detailed and actionable');
        }

        for (final step in item.culturalStepsHi) {
          expect(step.trim().length, greaterThan(10),
              reason: 'Hindi cultural step should be detailed and actionable');
        }
      }
    });

    test('strict PRD compliance: never prescribes chemical dosages or commercial brands', () {
      // Forbidden terms that indicate dosage prescriptions or commercial pesticide names
      final forbiddenDosageTerms = [
        'ml/l',
        'g/l',
        'gm/acre',
        'ppm',
        'dosage',
        'dose per',
        'chemical dose',
        'pesticide dose',
        'tablespoon',
        'teaspoon',
      ];

      final forbiddenBrandNames = [
        'bavistin',
        'monocrotophos',
        'chlorpyrifos',
        'carbendazim 50%',
        'confidor',
        'endosulfan',
        'malathion',
      ];

      for (final item in allGuidance) {
        final allText = [
          item.nameEn,
          item.nameHi,
          item.symptomsEn,
          item.symptomsHi,
          ...item.culturalStepsEn,
          ...item.culturalStepsHi,
          item.disclaimerEn,
          item.disclaimerHi,
        ].join(' ').toLowerCase();

        for (final forbidden in forbiddenDosageTerms) {
          expect(allText.contains(forbidden), isFalse,
              reason: 'Disease "${item.diseaseId}" contains prohibited chemical dosage unit "$forbidden"');
        }

        for (final brand in forbiddenBrandNames) {
          expect(allText.contains(brand), isFalse,
              reason: 'Disease "${item.diseaseId}" contains prohibited commercial brand "$brand"');
        }
      }
    });

    test('mandates legal liability disclaimer on every entry in both EN and HI', () {
      for (final item in allGuidance) {
        expect(item.disclaimerEn.trim(), isNotEmpty,
            reason: '${item.diseaseId} must have an English disclaimer');
        expect(item.disclaimerHi.trim(), isNotEmpty,
            reason: '${item.diseaseId} must have a Hindi disclaimer');

        expect(item.disclaimerEn.toLowerCase(), contains('consult'),
            reason: 'Disclaimer must recommend consulting certified agronomists / authorities');
      }
    });

    test('validates management categories and severity levels comply with domain schema', () {
      const allowedCategories = {'fungal', 'viral', 'bacterial', 'pest', 'healthy'};
      const allowedSeverities = {'low', 'medium', 'high'};

      for (final item in allGuidance) {
        expect(allowedCategories.contains(item.managementCategory), isTrue,
            reason: 'Invalid category: ${item.managementCategory} in ${item.diseaseId}');
        expect(allowedSeverities.contains(item.severityLevel), isTrue,
            reason: 'Invalid severity: ${item.severityLevel} in ${item.diseaseId}');
      }
    });
  });
}
