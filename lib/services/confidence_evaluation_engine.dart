import '../models/confidence_category.dart';
import '../models/confidence_evaluation_result.dart';
import '../models/crop.dart';
import '../models/raw_inference_output.dart';

/// Rule evaluation engine enforcing PRD Section 7.6 confidence brackets
/// and active crop context filtering for AI diagnoses.
class ConfidenceEvaluationEngine {
  /// Minimum confidence threshold for a "Likely" diagnosis (PRD 7.6: > 85%).
  final double likelyThreshold;

  /// Minimum confidence threshold for a "Possible" diagnosis (PRD 7.6: 60% – 85%).
  final double possibleThreshold;

  const ConfidenceEvaluationEngine({
    this.likelyThreshold = 0.85,
    this.possibleThreshold = 0.60,
  });

  /// Evaluates [rawOutput] against the [selectedCrop] (or [cropId]) context.
  ///
  /// Strictly follows PRD Section 7.6:
  /// - `> 0.85`: [ConfidenceCategory.likely], asserts predicted disease, full guidance unlocked.
  /// - `0.60 – 0.85`: [ConfidenceCategory.possible], asserts predicted disease, prompts photo retake, partial guidance.
  /// - `< 0.60`: [ConfidenceCategory.uncertain], asserts NO disease name, prompts retake, routes to KVK / agriculture expert.
  ConfidenceEvaluationResult evaluate({
    required RawInferenceOutput rawOutput,
    Crop? selectedCrop,
    String? cropId,
  }) {
    final effectiveCropId = selectedCrop?.id ?? cropId;

    // 1. If crop context is provided, filter candidates to that crop
    if (effectiveCropId != null && effectiveCropId.isNotEmpty) {
      return _evaluateWithCropContext(rawOutput, effectiveCropId);
    }

    // 2. Unrestricted evaluation across all model classes
    return _evaluateUnrestricted(rawOutput);
  }

  /// Evaluates inference outputs strictly constrained to the given [targetCropId].
  ConfidenceEvaluationResult _evaluateWithCropContext(
    RawInferenceOutput rawOutput,
    String targetCropId,
  ) {
    final cropPrefix = '${targetCropId.toLowerCase()}_';

    // Filter predictions belonging to this crop
    final cropCandidates = rawOutput.labelProbabilities.entries
        .where((e) => e.key.toLowerCase().startsWith(cropPrefix))
        .toList();

    // Sort candidates descending by probability
    cropCandidates.sort((a, b) => b.value.compareTo(a.value));

    // Determine overall top prediction across all crops
    final overallTopEntry = rawOutput.getTopK(1).firstOrNull;
    final overallTopCropId = overallTopEntry != null
        ? extractCropId(overallTopEntry.key)
        : null;

    // Detect severe crop mismatch (e.g. tomato disease predicted when wheat was selected)
    final bool isSevereMismatch = overallTopCropId != null &&
        overallTopCropId.toLowerCase() != targetCropId.toLowerCase() &&
        overallTopEntry!.value >= possibleThreshold &&
        (cropCandidates.isEmpty || cropCandidates.first.value < possibleThreshold);

    if (isSevereMismatch) {
      return ConfidenceEvaluationResult.create(
        category: ConfidenceCategory.uncertain,
        rawDiseaseId: null,
        cropId: targetCropId,
        confidenceScore: overallTopEntry.value,
        isHealthy: false,
        isCropMismatch: true,
        detectedCropId: overallTopCropId,
        candidateRankings: cropCandidates,
        rawOutput: rawOutput,
      );
    }

    // If no candidate classes found for selected crop, return uncertain
    if (cropCandidates.isEmpty) {
      return ConfidenceEvaluationResult.create(
        category: ConfidenceCategory.uncertain,
        rawDiseaseId: null,
        cropId: targetCropId,
        confidenceScore: 0.0,
        isHealthy: false,
        isCropMismatch: false,
        candidateRankings: const [],
        rawOutput: rawOutput,
      );
    }

    final topCandidate = cropCandidates.first;
    final score = topCandidate.value;
    final isHealthy = topCandidate.key.toLowerCase().endsWith('_healthy');
    final category = categorizeScore(score);

    return ConfidenceEvaluationResult.create(
      category: category,
      rawDiseaseId: topCandidate.key,
      cropId: targetCropId,
      confidenceScore: score,
      isHealthy: isHealthy,
      isCropMismatch: false,
      candidateRankings: cropCandidates,
      rawOutput: rawOutput,
    );
  }

  /// Evaluates inference outputs across all classes without crop filtering.
  ConfidenceEvaluationResult _evaluateUnrestricted(RawInferenceOutput rawOutput) {
    final allCandidates = rawOutput.getTopK(rawOutput.labels.length);
    if (allCandidates.isEmpty) {
      return ConfidenceEvaluationResult.create(
        category: ConfidenceCategory.uncertain,
        rawDiseaseId: null,
        cropId: null,
        confidenceScore: 0.0,
        isHealthy: false,
        isCropMismatch: false,
        candidateRankings: const [],
        rawOutput: rawOutput,
      );
    }

    final topCandidate = allCandidates.first;
    final score = topCandidate.value;
    final cropId = extractCropId(topCandidate.key);
    final isHealthy = topCandidate.key.toLowerCase().endsWith('_healthy');
    final category = categorizeScore(score);

    return ConfidenceEvaluationResult.create(
      category: category,
      rawDiseaseId: topCandidate.key,
      cropId: cropId,
      confidenceScore: score,
      isHealthy: isHealthy,
      isCropMismatch: false,
      candidateRankings: allCandidates,
      rawOutput: rawOutput,
    );
  }

  /// Categorizes a probability score into [ConfidenceCategory] per PRD Section 7.6.
  ConfidenceCategory categorizeScore(double score) {
    if (score > likelyThreshold) {
      return ConfidenceCategory.likely;
    } else if (score >= possibleThreshold) {
      return ConfidenceCategory.possible;
    } else {
      return ConfidenceCategory.uncertain;
    }
  }

  /// Extracts the crop prefix from a full disease label (e.g. `'tomato_early_blight'` -> `'tomato'`).
  static String extractCropId(String classLabel) {
    final firstUnderscore = classLabel.indexOf('_');
    if (firstUnderscore == -1) return classLabel;
    return classLabel.substring(0, firstUnderscore);
  }

  /// Extracts the condition/disease suffix from a label (e.g. `'tomato_early_blight'` -> `'early_blight'`).
  static String extractConditionId(String classLabel) {
    final firstUnderscore = classLabel.indexOf('_');
    if (firstUnderscore == -1) return classLabel;
    return classLabel.substring(firstUnderscore + 1);
  }
}
