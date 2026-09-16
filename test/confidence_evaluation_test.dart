import 'package:flutter_test/flutter_test.dart';
import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/crop.dart';
import 'package:planten/models/raw_inference_output.dart';
import 'package:planten/services/confidence_evaluation_engine.dart';

void main() {
  const engine = ConfidenceEvaluationEngine();

  const tomatoCrop = Crop(
    id: 'tomato',
    nameEn: 'Tomato',
    nameHi: 'टमाटर',
    iconAssetPath: 'assets/icons/crops/tomato.png',
  );

  const wheatCrop = Crop(
    id: 'wheat',
    nameEn: 'Wheat',
    nameHi: 'गेहूं',
    iconAssetPath: 'assets/icons/crops/wheat.png',
  );

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
    int latencyMs = 28,
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

  group('Confidence Evaluation Logic (Task 56)', () {
    test('>85% confidence returns Likely and assigns disease name', () {
      final raw = createMockOutput(scores: {
        'tomato_early_blight': 0.92,
        'tomato_late_blight': 0.05,
        'tomato_healthy': 0.03,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: tomatoCrop,
      );

      // Core Acceptance Criteria
      expect(result.category, equals(ConfidenceCategory.likely));
      expect(result.predictedDiseaseId, equals('tomato_early_blight'));
      expect(result.confidenceScore, equals(0.92));

      // Associated PRD 7.6 State Assertions
      expect(result.unlockFullGuidance, isTrue);
      expect(result.promptRetake, isFalse);
      expect(result.routeToExpert, isFalse);
      expect(result.isHealthy, isFalse);
      expect(result.isCropMismatch, isFalse);
      expect(result.userMessageEn, contains('High confidence diagnosis'));
      expect(result.userMessageHi, contains('सटीक निदान'));
    });

    test('60%–85% confidence returns Possible and warns user to retake photo', () {
      final raw = createMockOutput(scores: {
        'tomato_late_blight': 0.74,
        'tomato_early_blight': 0.16,
        'tomato_healthy': 0.10,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: tomatoCrop,
      );

      // Core Acceptance Criteria
      expect(result.category, equals(ConfidenceCategory.possible));
      expect(result.predictedDiseaseId, equals('tomato_late_blight'));
      expect(result.confidenceScore, equals(0.74));

      // Associated PRD 7.6 State Assertions: warns user, prompts retake, partial guidance
      expect(result.unlockFullGuidance, isFalse);
      expect(result.promptRetake, isTrue);
      expect(result.routeToExpert, isFalse);
      expect(result.isHealthy, isFalse);
      expect(result.isCropMismatch, isFalse);
      expect(result.userMessageEn, contains('Possible disease detected'));
      expect(result.userMessageEn, contains('Retake photo'));
      expect(result.userMessageHi, contains('संभावित रोग'));
      expect(result.userMessageHi, contains('दोबारा फोटो लें'));
    });

    test('<60% confidence returns Uncertain and withholds disease name', () {
      final raw = createMockOutput(scores: {
        'tomato_early_blight': 0.45,
        'tomato_late_blight': 0.35,
        'tomato_leaf_curl': 0.20,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: tomatoCrop,
      );

      // Core Acceptance Criteria: strictly null disease identifier
      expect(result.category, equals(ConfidenceCategory.uncertain));
      expect(result.predictedDiseaseId, isNull);
      expect(result.confidenceScore, equals(0.45));

      // Associated PRD 7.6 State Assertions: route to expert, prompts retake, no treatment
      expect(result.unlockFullGuidance, isFalse);
      expect(result.promptRetake, isTrue);
      expect(result.routeToExpert, isTrue);
      expect(result.userMessageEn, contains('Diagnosis uncertain'));
      expect(result.userMessageEn, contains('KVK'));
      expect(result.userMessageHi, contains('निदान अनिश्चित है'));
      expect(result.userMessageHi, contains('KVK'));
    });

    test('respects exact threshold boundaries (0.85 and 0.60)', () {
      // Exactly 0.85 should be Possible (not Likely, because PRD specifies > 85%)
      final rawAt85 = createMockOutput(scores: {
        'tomato_leaf_curl': 0.85,
        'tomato_healthy': 0.15,
      });
      final resultAt85 = engine.evaluate(rawOutput: rawAt85, selectedCrop: tomatoCrop);
      expect(resultAt85.category, equals(ConfidenceCategory.possible));
      expect(resultAt85.predictedDiseaseId, equals('tomato_leaf_curl'));
      expect(resultAt85.unlockFullGuidance, isFalse);

      // Slightly above 0.85 (0.8501) should be Likely
      final rawAbove85 = createMockOutput(scores: {
        'tomato_leaf_curl': 0.8501,
        'tomato_healthy': 0.1499,
      });
      final resultAbove85 = engine.evaluate(rawOutput: rawAbove85, selectedCrop: tomatoCrop);
      expect(resultAbove85.category, equals(ConfidenceCategory.likely));
      expect(resultAbove85.unlockFullGuidance, isTrue);

      // Exactly 0.60 should be Possible (PRD 60% – 85%)
      final rawAt60 = createMockOutput(scores: {
        'tomato_early_blight': 0.60,
        'tomato_healthy': 0.40,
      });
      final resultAt60 = engine.evaluate(rawOutput: rawAt60, selectedCrop: tomatoCrop);
      expect(resultAt60.category, equals(ConfidenceCategory.possible));
      expect(resultAt60.predictedDiseaseId, equals('tomato_early_blight'));

      // Below 0.60 (0.599) should be Uncertain
      final rawBelow60 = createMockOutput(scores: {
        'tomato_early_blight': 0.599,
        'tomato_healthy': 0.401,
      });
      final resultBelow60 = engine.evaluate(rawOutput: rawBelow60, selectedCrop: tomatoCrop);
      expect(resultBelow60.category, equals(ConfidenceCategory.uncertain));
      expect(resultBelow60.predictedDiseaseId, isNull);
    });

    test('identifies healthy leaf and assigns isHealthy correctly', () {
      final raw = createMockOutput(scores: {
        'tomato_healthy': 0.94,
        'tomato_early_blight': 0.04,
        'tomato_late_blight': 0.02,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: tomatoCrop,
      );

      expect(result.category, equals(ConfidenceCategory.likely));
      expect(result.isHealthy, isTrue);
      expect(result.predictedDiseaseId, equals('tomato_healthy'));
      expect(result.userMessageEn, contains('healthy'));
      expect(result.userMessageHi, contains('स्वस्थ'));
    });

    test('detects severe crop mismatch and withholds disease name', () {
      // Selected crop is Wheat, but model overwhelmingly predicts Tomato Early Blight
      final raw = createMockOutput(scores: {
        'tomato_early_blight': 0.91,
        'wheat_yellow_rust': 0.05,
        'wheat_healthy': 0.04,
      });

      final result = engine.evaluate(
        rawOutput: raw,
        selectedCrop: wheatCrop,
      );

      expect(result.category, equals(ConfidenceCategory.uncertain));
      expect(result.isCropMismatch, isTrue);
      expect(result.detectedCropId, equals('tomato'));
      expect(result.predictedDiseaseId, isNull);
      expect(result.routeToExpert, isTrue);
      expect(result.promptRetake, isTrue);
      expect(result.userMessageEn, contains('does not match the selected crop'));
      expect(result.userMessageHi, contains('पत्ती चुनी गई फसल'));
    });

    test('evaluates unrestricted when no crop context is specified', () {
      final raw = createMockOutput(scores: {
        'chili_bacterial_spot': 0.88,
        'tomato_early_blight': 0.08,
        'wheat_yellow_rust': 0.04,
      });

      final result = engine.evaluate(rawOutput: raw);

      expect(result.category, equals(ConfidenceCategory.likely));
      expect(result.cropId, equals('chili'));
      expect(result.predictedDiseaseId, equals('chili_bacterial_spot'));
      expect(result.unlockFullGuidance, isTrue);
    });

    test('ranks candidates in descending order of confidence', () {
      final raw = createMockOutput(scores: {
        'tomato_early_blight': 0.55,
        'tomato_late_blight': 0.30,
        'tomato_leaf_curl': 0.15,
      });

      final result = engine.evaluate(rawOutput: raw, selectedCrop: tomatoCrop);

      expect(result.candidateRankings.length, equals(4)); // all 4 tomato classes
      expect(result.candidateRankings.first.key, equals('tomato_early_blight'));
      expect(result.candidateRankings.first.value, equals(0.55));
      expect(result.candidateRankings[1].key, equals('tomato_late_blight'));
      expect(result.candidateRankings[1].value, equals(0.30));
    });
  });
}
