import 'package:flutter_test/flutter_test.dart';
import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/crop.dart';
import 'package:planten/models/raw_inference_output.dart';
import 'package:planten/services/confidence_evaluation_engine.dart';

void main() {
  const engine = ConfidenceEvaluationEngine();

  final allLabels = [
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

  RawInferenceOutput createMockOutput({
    required Map<String, double> scores,
    int latencyMs = 25,
  }) {
    final probs = <double>[];
    for (final label in allLabels) {
      probs.add(scores[label] ?? 0.0);
    }
    return RawInferenceOutput.fromProbabilities(
      probabilities: probs,
      labels: allLabels,
      inferenceTimeMs: latencyMs,
    );
  }

  group('ConfidenceEvaluationEngine PRD Section 7.6 Thresholds', () {
    test('> 85% confidence -> Likely with full guidance, no retake prompt', () {
      final raw = createMockOutput(scores: {
        'tomato_early_blight': 0.89,
        'tomato_late_blight': 0.06,
        'tomato_healthy': 0.05,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: const Crop(
          id: 'tomato',
          nameEn: 'Tomato',
          nameHi: 'टमाटर',
          iconAssetPath: 'assets/icons/crops/tomato.png',
        ),
      );

      expect(result.category, ConfidenceCategory.likely);
      expect(result.confidenceScore, 0.89);
      expect(result.predictedDiseaseId, 'tomato_early_blight');
      expect(result.isHealthy, isFalse);
      expect(result.unlockFullGuidance, isTrue);
      expect(result.promptRetake, isFalse);
      expect(result.routeToExpert, isFalse);
      expect(result.isCropMismatch, isFalse);
      expect(result.userMessageEn, contains('High confidence'));
      expect(result.userMessageHi, contains('सटीक निदान'));
    });

    test('60% – 85% confidence -> Possible with partial guidance & retake prompt', () {
      final raw = createMockOutput(scores: {
        'potato_late_blight': 0.74,
        'potato_early_blight': 0.16,
        'potato_healthy': 0.10,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: const Crop(
          id: 'potato',
          nameEn: 'Potato',
          nameHi: 'आलू',
          iconAssetPath: 'assets/icons/crops/potato.png',
        ),
      );

      expect(result.category, ConfidenceCategory.possible);
      expect(result.confidenceScore, 0.74);
      expect(result.predictedDiseaseId, 'potato_late_blight');
      expect(result.unlockFullGuidance, isFalse);
      expect(result.promptRetake, isTrue);
      expect(result.routeToExpert, isFalse);
      expect(result.isCropMismatch, isFalse);
      expect(result.userMessageEn, contains('Possible disease detected'));
      expect(result.userMessageHi, contains('संभावित रोग'));
    });

    test('< 60% confidence -> Uncertain, NO disease name asserted, route to expert', () {
      final raw = createMockOutput(scores: {
        'wheat_yellow_rust': 0.45,
        'wheat_powdery_mildew': 0.35,
        'wheat_healthy': 0.20,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: const Crop(
          id: 'wheat',
          nameEn: 'Wheat',
          nameHi: 'गेहूं',
          iconAssetPath: 'assets/icons/crops/wheat.png',
        ),
      );

      expect(result.category, ConfidenceCategory.uncertain);
      expect(result.confidenceScore, 0.45);
      // Strictly verify PRD 7.6 requirement: "no disease name asserted"
      expect(result.predictedDiseaseId, isNull);
      expect(result.unlockFullGuidance, isFalse);
      expect(result.promptRetake, isTrue);
      expect(result.routeToExpert, isTrue);
      expect(result.isCropMismatch, isFalse);
      expect(result.userMessageEn, contains('Diagnosis uncertain'));
      expect(result.userMessageHi, contains('निदान अनिश्चित'));
    });
  });

  group('ConfidenceEvaluationEngine Boundary Value Testing', () {
    test('score exactly 0.85 is Possible (not Likely)', () {
      expect(engine.categorizeScore(0.85), ConfidenceCategory.possible);
    });

    test('score 0.85001 is Likely', () {
      expect(engine.categorizeScore(0.85001), ConfidenceCategory.likely);
    });

    test('score exactly 0.60 is Possible (not Uncertain)', () {
      expect(engine.categorizeScore(0.60), ConfidenceCategory.possible);
    });

    test('score 0.5999 is Uncertain', () {
      expect(engine.categorizeScore(0.5999), ConfidenceCategory.uncertain);
    });

    test('score 0.0 is Uncertain and 1.0 is Likely', () {
      expect(engine.categorizeScore(0.0), ConfidenceCategory.uncertain);
      expect(engine.categorizeScore(1.0), ConfidenceCategory.likely);
    });
  });

  group('ConfidenceEvaluationEngine Crop Context Filtering & Mismatch', () {
    test('filters candidates strictly to selected crop', () {
      final raw = createMockOutput(scores: {
        'chili_leaf_curl': 0.88,
        'chili_bacterial_spot': 0.07,
        'chili_healthy': 0.05,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        cropId: 'chili',
      );

      expect(result.category, ConfidenceCategory.likely);
      expect(result.cropId, 'chili');
      expect(result.predictedDiseaseId, 'chili_leaf_curl');
      expect(result.candidateRankings.length, 3);
      expect(result.candidateRankings.every((e) => e.key.startsWith('chili_')), isTrue);
    });

    test('detects severe crop mismatch and suppresses disease name', () {
      // User selected wheat, but photo strongly shows tomato blight (92%)
      final raw = createMockOutput(scores: {
        'tomato_early_blight': 0.92,
        'tomato_late_blight': 0.04,
        'wheat_yellow_rust': 0.02,
        'wheat_healthy': 0.02,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: const Crop(
          id: 'wheat',
          nameEn: 'Wheat',
          nameHi: 'गेहूं',
          iconAssetPath: 'assets/icons/crops/wheat.png',
        ),
      );

      expect(result.isCropMismatch, isTrue);
      expect(result.detectedCropId, 'tomato');
      expect(result.category, ConfidenceCategory.uncertain);
      expect(result.predictedDiseaseId, isNull);
      expect(result.promptRetake, isTrue);
      expect(result.routeToExpert, isTrue);
      expect(result.userMessageEn, contains('Leaf does not match the selected crop'));
      expect(result.userMessageHi, contains('पत्ती चुनी गई फसल'));
    });
  });

  group('ConfidenceEvaluationEngine Healthy Crop Classification', () {
    test('accurately identifies healthy tomato leaf', () {
      final raw = createMockOutput(scores: {
        'tomato_healthy': 0.94,
        'tomato_early_blight': 0.04,
        'tomato_late_blight': 0.02,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        cropId: 'tomato',
      );

      expect(result.category, ConfidenceCategory.likely);
      expect(result.isHealthy, isTrue);
      expect(result.predictedDiseaseId, 'tomato_healthy');
      expect(result.userMessageEn, contains('Plant appears healthy'));
      expect(result.userMessageHi, contains('पौधा स्वस्थ प्रतीत होता है'));
    });

    test('accurately identifies healthy cotton leaf with possible confidence', () {
      final raw = createMockOutput(scores: {
        'cotton_healthy': 0.70,
        'cotton_bacterial_blight': 0.30,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        cropId: 'cotton',
      );

      expect(result.category, ConfidenceCategory.possible);
      expect(result.isHealthy, isTrue);
      expect(result.predictedDiseaseId, 'cotton_healthy');
      expect(result.promptRetake, isTrue);
    });
  });

  group('ConfidenceEvaluationEngine Unrestricted Evaluation', () {
    test('evaluates overall top class when no crop is selected', () {
      final raw = createMockOutput(scores: {
        'potato_early_blight': 0.91,
        'potato_healthy': 0.05,
        'tomato_early_blight': 0.04,
      });

      final result = engine.evaluate(rawOutput: raw);

      expect(result.category, ConfidenceCategory.likely);
      expect(result.cropId, 'potato');
      expect(result.predictedDiseaseId, 'potato_early_blight');
      expect(result.isCropMismatch, isFalse);
    });

    test('extractCropId and extractConditionId work as expected', () {
      expect(ConfidenceEvaluationEngine.extractCropId('tomato_early_blight'), 'tomato');
      expect(ConfidenceEvaluationEngine.extractConditionId('tomato_early_blight'), 'early_blight');
      expect(ConfidenceEvaluationEngine.extractCropId('cotton_healthy'), 'cotton');
      expect(ConfidenceEvaluationEngine.extractConditionId('cotton_healthy'), 'healthy');
      expect(ConfidenceEvaluationEngine.extractCropId('simple'), 'simple');
      expect(ConfidenceEvaluationEngine.extractConditionId('simple'), 'simple');
    });
  });
}
