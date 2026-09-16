import 'package:flutter/foundation.dart';
import 'confidence_category.dart';
import 'crop.dart';
import 'severity_level.dart';
import 'treatment_guidance.dart';

/// Immutable domain model representing an on-device AI diagnosis result.
@immutable
class DiagnosisResult {
  /// Unique identifier of the diagnosis entry (e.g. UUID).
  final String id;

  /// Identifier of the crop being diagnosed (e.g. `'tomato'`, `'wheat'`).
  final String cropId;

  /// Resolves the corresponding [Crop] object for this scan.
  Crop get crop => Crop.fromId(cropId);

  /// Identifier of the classified condition (e.g. `'tomato_early_blight'`, `'wheat_healthy'`).
  final String diseaseId;

  /// English human-readable disease name.
  final String diseaseNameEn;

  /// Hindi vernacular disease name.
  final String diseaseNameHi;

  /// Decimal confidence score between 0.0 and 1.0 (e.g. 0.92 for 92%).
  final double confidenceScore;

  /// Assessed severity level of the infection.
  final SeverityLevel severity;

  /// Timestamp when the scan and diagnosis occurred.
  final DateTime timestamp;

  /// Local filesystem path where the captured leaf photo is saved.
  final String localImagePath;

  /// Remote cloud URL if the farmer opted in to photo backup (null by default).
  final String? remoteImageUrl;

  /// Whether this diagnosis entry has been synced to Cloud Firestore.
  final bool isSynced;

  /// Attached verified treatment guidance from the knowledge base, if available.
  final TreatmentGuidance? guidance;

  const DiagnosisResult({
    required this.id,
    required this.cropId,
    required this.diseaseId,
    required this.diseaseNameEn,
    required this.diseaseNameHi,
    required this.confidenceScore,
    required this.severity,
    required this.timestamp,
    required this.localImagePath,
    this.remoteImageUrl,
    this.isSynced = false,
    this.guidance,
  });

  /// Factory constructor to deserialize [DiagnosisResult] from a JSON map.
  /// Supports both snake_case and camelCase field keys.
  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp is DateTime) {
      parsedTimestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      // Duck-typing support for Firestore Timestamp
      try {
        parsedTimestamp = (rawTimestamp as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedTimestamp = DateTime.now();
      }
    }

    return DiagnosisResult(
      id: (json['id'] ?? '') as String,
      cropId: ((json['crop_id'] ?? json['cropId']) ?? '') as String,
      diseaseId: ((json['disease_id'] ?? json['diseaseId']) ?? '') as String,
      diseaseNameEn:
          ((json['disease_name_en'] ?? json['diseaseNameEn']) ?? '') as String,
      diseaseNameHi:
          ((json['disease_name_hi'] ?? json['diseaseNameHi']) ?? '') as String,
      confidenceScore:
          ((json['confidence_score'] ?? json['confidenceScore'] ?? 0.0) as num).toDouble(),
      severity: json['severity'] is String
          ? SeverityLevel.fromJson(json['severity'] as String)
          : SeverityLevel.medium,
      timestamp: parsedTimestamp,
      localImagePath:
          ((json['local_image_path'] ?? json['localImagePath']) as String?) ?? '',
      remoteImageUrl:
          (json['remote_image_url'] ?? json['remoteImageUrl']) as String?,
      isSynced: ((json['is_synced'] ?? json['isSynced']) as bool?) ?? false,
      guidance: json['guidance'] != null
          ? TreatmentGuidance.fromJson(json['guidance'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Serializes [DiagnosisResult] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_id': cropId,
      'disease_id': diseaseId,
      'disease_name_en': diseaseNameEn,
      'disease_name_hi': diseaseNameHi,
      'confidence_score': confidenceScore,
      'severity': severity.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'local_image_path': localImagePath,
      'remote_image_url': remoteImageUrl,
      'is_synced': isSynced,
      if (guidance != null) 'guidance': guidance!.toJson(),
    };
  }

  /// Confidence classification category mapped according to PRD Section 7.6.
  ConfidenceCategory get confidenceCategory =>
      ConfidenceCategory.fromScore(confidenceScore);

  /// True if the diagnosis classified the crop as healthy.
  bool get isHealthy =>
      diseaseId.toLowerCase().endsWith('_healthy') ||
      severity == SeverityLevel.healthy;

  /// Confidence score formatted as integer percentage (e.g. 92 for 0.92).
  int get confidencePercentage => (confidenceScore * 100).round();

  /// Returns localized disease name based on given language code (`'hi'` or `'en'`).
  String localizedDiseaseName(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? diseaseNameHi : diseaseNameEn;
  }

  /// Creates a copy of this [DiagnosisResult] with specified fields replaced.
  DiagnosisResult copyWith({
    String? id,
    String? cropId,
    String? diseaseId,
    String? diseaseNameEn,
    String? diseaseNameHi,
    double? confidenceScore,
    SeverityLevel? severity,
    DateTime? timestamp,
    String? localImagePath,
    String? remoteImageUrl,
    bool clearRemoteImageUrl = false,
    bool? isSynced,
    TreatmentGuidance? guidance,
    bool clearGuidance = false,
  }) {
    return DiagnosisResult(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      diseaseId: diseaseId ?? this.diseaseId,
      diseaseNameEn: diseaseNameEn ?? this.diseaseNameEn,
      diseaseNameHi: diseaseNameHi ?? this.diseaseNameHi,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      localImagePath: localImagePath ?? this.localImagePath,
      remoteImageUrl: clearRemoteImageUrl
          ? null
          : (remoteImageUrl ?? this.remoteImageUrl),
      isSynced: isSynced ?? this.isSynced,
      guidance: clearGuidance ? null : (guidance ?? this.guidance),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiagnosisResult &&
        other.id == id &&
        other.cropId == cropId &&
        other.diseaseId == diseaseId &&
        other.diseaseNameEn == diseaseNameEn &&
        other.diseaseNameHi == diseaseNameHi &&
        other.confidenceScore == confidenceScore &&
        other.severity == severity &&
        other.timestamp == timestamp &&
        other.localImagePath == localImagePath &&
        other.remoteImageUrl == remoteImageUrl &&
        other.isSynced == isSynced &&
        other.guidance == guidance;
  }

  @override
  int get hashCode => Object.hash(
        id,
        cropId,
        diseaseId,
        diseaseNameEn,
        diseaseNameHi,
        confidenceScore,
        severity,
        timestamp,
        localImagePath,
        remoteImageUrl,
        isSynced,
        guidance,
      );

  @override
  String toString() =>
      'DiagnosisResult(id: $id, cropId: $cropId, diseaseId: $diseaseId, confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%, severity: ${severity.name}, isSynced: $isSynced)';
}
