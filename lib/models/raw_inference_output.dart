import 'package:flutter/foundation.dart';

/// Immutable domain model representing raw AI model inference outputs.
@immutable
class RawInferenceOutput {
  /// Probability values for each output class (summing to ~1.0).
  final List<double> probabilities;

  /// Ordered class labels corresponding to [probabilities].
  final List<String> labels;

  /// Time taken to execute inference on device, in milliseconds.
  final int inferenceTimeMs;

  const RawInferenceOutput({
    required this.probabilities,
    required this.labels,
    required this.inferenceTimeMs,
  });

  /// Factory constructor to create [RawInferenceOutput] from raw outputs and labels.
  /// Automatically validates list lengths match.
  factory RawInferenceOutput.fromProbabilities({
    required List<double> probabilities,
    required List<String> labels,
    required int inferenceTimeMs,
  }) {
    if (probabilities.length != labels.length) {
      throw ArgumentError(
        'Probabilities count (${probabilities.length}) must match labels count (${labels.length}).',
      );
    }
    return RawInferenceOutput(
      probabilities: List.unmodifiable(probabilities),
      labels: List.unmodifiable(labels),
      inferenceTimeMs: inferenceTimeMs,
    );
  }

  /// Maps every class label to its corresponding probability score.
  Map<String, double> get labelProbabilities {
    final map = <String, double>{};
    for (int i = 0; i < labels.length && i < probabilities.length; i++) {
      map[labels[i]] = probabilities[i];
    }
    return Map.unmodifiable(map);
  }

  /// Index of the class with highest probability.
  int get topIndex {
    if (probabilities.isEmpty) return -1;
    int maxIdx = 0;
    double maxVal = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxVal) {
        maxVal = probabilities[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  /// Label of the class with highest probability.
  String get topLabel {
    final idx = topIndex;
    if (idx < 0 || idx >= labels.length) return '';
    return labels[idx];
  }

  /// Highest probability score in range [0.0, 1.0].
  double get topConfidence {
    final idx = topIndex;
    if (idx < 0 || idx >= probabilities.length) return 0.0;
    return probabilities[idx];
  }

  /// Returns the top [k] predictions sorted descending by probability.
  List<MapEntry<String, double>> getTopK(int k) {
    if (k <= 0) return const [];
    final entries = labelProbabilities.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(k).toList();
  }

  /// Returns the probability score for a given [label], or `0.0` if not found.
  double probabilityFor(String label) {
    return labelProbabilities[label] ?? 0.0;
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'probabilities': probabilities,
      'labels': labels,
      'inference_time_ms': inferenceTimeMs,
      'top_label': topLabel,
      'top_confidence': topConfidence,
    };
  }

  /// Deserializes from a JSON map.
  factory RawInferenceOutput.fromJson(Map<String, dynamic> json) {
    final probs = (json['probabilities'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    final lbls = (json['labels'] as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    final timeMs = (json['inference_time_ms'] ?? json['inferenceTimeMs'] ?? 0) as int;

    return RawInferenceOutput.fromProbabilities(
      probabilities: probs,
      labels: lbls,
      inferenceTimeMs: timeMs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawInferenceOutput &&
        listEquals(other.probabilities, probabilities) &&
        listEquals(other.labels, labels) &&
        other.inferenceTimeMs == inferenceTimeMs;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(probabilities),
        Object.hashAll(labels),
        inferenceTimeMs,
      );

  @override
  String toString() =>
      'RawInferenceOutput(topLabel: $topLabel, topConfidence: ${(topConfidence * 100).toStringAsFixed(1)}%, latency: ${inferenceTimeMs}ms)';
}
