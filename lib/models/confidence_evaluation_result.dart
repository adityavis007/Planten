import 'package:flutter/foundation.dart';
import 'confidence_category.dart';
import 'raw_inference_output.dart';

/// Immutable domain model representing evaluated diagnosis confidence,
/// enforcing PRD Section 7.6 guidelines and crop context constraints.
@immutable
class ConfidenceEvaluationResult {
  /// PRD 7.6 confidence category (`likely`, `possible`, `uncertain`).
  final ConfidenceCategory category;

  /// Identified disease identifier (e.g. `'tomato_early_blight'`).
  /// Strictly `null` if [category] is [ConfidenceCategory.uncertain] or if healthy.
  final String? predictedDiseaseId;

  /// Identifier of the crop evaluated (e.g. `'tomato'`, `'wheat'`).
  final String? cropId;

  /// Normalized confidence score in range `[0.0, 1.0]`.
  final double confidenceScore;

  /// Whether the diagnosed leaf is classified as healthy (e.g. `'tomato_healthy'`).
  final bool isHealthy;

  /// Whether the leaf appears to belong to a different crop than the selected crop context.
  final bool isCropMismatch;

  /// Detected crop identifier if [isCropMismatch] is true.
  final String? detectedCropId;

  /// Whether full cultural and preventive management steps are unlocked.
  /// Strictly `true` only when [category] is [ConfidenceCategory.likely].
  final bool unlockFullGuidance;

  /// Whether the UI should advise the farmer to retake a clearer photo.
  final bool promptRetake;

  /// Whether the UI should route to local agricultural officer / KVK consultation.
  final bool routeToExpert;

  /// Localized English explanation of the diagnosis state.
  final String userMessageEn;

  /// Localized Hindi explanation of the diagnosis state.
  final String userMessageHi;

  /// Ranked candidate predictions for the crop context.
  final List<MapEntry<String, double>> candidateRankings;

  /// The underlying raw model inference output.
  final RawInferenceOutput rawOutput;

  const ConfidenceEvaluationResult({
    required this.category,
    required this.predictedDiseaseId,
    required this.cropId,
    required this.confidenceScore,
    required this.isHealthy,
    required this.isCropMismatch,
    this.detectedCropId,
    required this.unlockFullGuidance,
    required this.promptRetake,
    required this.routeToExpert,
    required this.userMessageEn,
    required this.userMessageHi,
    required this.candidateRankings,
    required this.rawOutput,
  });

  /// Factory to construct an evaluated result enforcing all PRD Section 7.6 rules.
  factory ConfidenceEvaluationResult.create({
    required ConfidenceCategory category,
    required String? rawDiseaseId,
    required String? cropId,
    required double confidenceScore,
    required bool isHealthy,
    bool isCropMismatch = false,
    String? detectedCropId,
    required List<MapEntry<String, double>> candidateRankings,
    required RawInferenceOutput rawOutput,
    String? customMessageEn,
    String? customMessageHi,
  }) {
    // PRD 7.6 Rule: Never assert a disease name when confidence is uncertain (<60%)
    final String? effectiveDiseaseId;
    if (category == ConfidenceCategory.uncertain || isCropMismatch) {
      effectiveDiseaseId = null;
    } else {
      effectiveDiseaseId = rawDiseaseId;
    }

    final bool unlockFull = category == ConfidenceCategory.likely && !isCropMismatch;
    final bool retake = category != ConfidenceCategory.likely || isCropMismatch;
    final bool expert = category == ConfidenceCategory.uncertain || isCropMismatch;

    // Default localized messages
    final String msgEn;
    final String msgHi;

    if (isCropMismatch) {
      msgEn = 'Leaf does not match the selected crop (${cropId ?? "unknown"}). Please select the correct crop or retake photo.';
      msgHi = 'पत्ती चुनी गई फसल (${cropId ?? "अज्ञात"}) से मेल नहीं खाती। कृपया सही फसल चुनें या दोबारा फोटो लें।';
    } else if (isHealthy) {
      msgEn = 'Plant appears healthy. No significant disease symptoms detected.';
      msgHi = 'पौधा स्वस्थ प्रतीत होता है। रोग का कोई महत्वपूर्ण लक्षण नहीं मिला।';
    } else {
      switch (category) {
        case ConfidenceCategory.likely:
          msgEn = 'High confidence diagnosis. Verified management steps are available.';
          msgHi = 'सटीक निदान। प्रमाणित रोकथाम और देखभाल के उपाय उपलब्ध हैं।';
          break;
        case ConfidenceCategory.possible:
          msgEn = 'Possible disease detected. Retake photo in clearer light for higher precision.';
          msgHi = 'संभावित रोग मिला। अधिक सटीकता के लिए बेहतर रोशनी में दोबारा फोटो लें।';
          break;
        case ConfidenceCategory.uncertain:
          msgEn = 'Diagnosis uncertain. Please consult a local agricultural officer (KVK) or retake photo.';
          msgHi = 'निदान अनिश्चित है। कृपया नजदीकी कृषि अधिकारी (KVK) से संपर्क करें या दोबारा फोटो लें।';
          break;
      }
    }

    return ConfidenceEvaluationResult(
      category: category,
      predictedDiseaseId: effectiveDiseaseId,
      cropId: cropId,
      confidenceScore: confidenceScore,
      isHealthy: isHealthy,
      isCropMismatch: isCropMismatch,
      detectedCropId: detectedCropId,
      unlockFullGuidance: unlockFull,
      promptRetake: retake,
      routeToExpert: expert,
      userMessageEn: customMessageEn ?? msgEn,
      userMessageHi: customMessageHi ?? msgHi,
      candidateRankings: List.unmodifiable(candidateRankings),
      rawOutput: rawOutput,
    );
  }

  /// Returns localized message based on language code (`'hi'` or `'en'`).
  String localizedMessage(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? userMessageHi : userMessageEn;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfidenceEvaluationResult &&
        other.category == category &&
        other.predictedDiseaseId == predictedDiseaseId &&
        other.cropId == cropId &&
        other.confidenceScore == confidenceScore &&
        other.isHealthy == isHealthy &&
        other.isCropMismatch == isCropMismatch &&
        other.detectedCropId == detectedCropId &&
        other.unlockFullGuidance == unlockFullGuidance &&
        other.promptRetake == promptRetake &&
        other.routeToExpert == routeToExpert &&
        other.rawOutput == rawOutput;
  }

  @override
  int get hashCode => Object.hash(
        category,
        predictedDiseaseId,
        cropId,
        confidenceScore,
        isHealthy,
        isCropMismatch,
        detectedCropId,
        unlockFullGuidance,
        promptRetake,
        routeToExpert,
        rawOutput,
      );

  @override
  String toString() =>
      'ConfidenceEvaluationResult(category: ${category.name}, disease: $predictedDiseaseId, score: ${(confidenceScore * 100).toStringAsFixed(1)}%, cropMismatch: $isCropMismatch)';
}
