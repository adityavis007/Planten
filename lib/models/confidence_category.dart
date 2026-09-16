/// Represents the confidence classification category based on PRD Section 7.6 thresholds.
enum ConfidenceCategory {
  /// Confidence > 85%: Likely disease match, full guidance unlocked.
  likely,

  /// Confidence 60% – 85%: Possible disease match, partial guidance with prompt to retake.
  possible,

  /// Confidence < 60%: Uncertain diagnosis, routes to agriculture expert consultation.
  uncertain;

  /// Categorizes a raw decimal confidence score (0.0 to 1.0) into a [ConfidenceCategory].
  ///
  /// - `score > 0.85`: [likely]
  /// - `0.60 <= score <= 0.85`: [possible]
  /// - `score < 0.60`: [uncertain]
  static ConfidenceCategory fromScore(double score) {
    if (score > 0.85) {
      return ConfidenceCategory.likely;
    } else if (score >= 0.60) {
      return ConfidenceCategory.possible;
    } else {
      return ConfidenceCategory.uncertain;
    }
  }

  /// Parses a string value into [ConfidenceCategory].
  ///
  /// Defaults to [ConfidenceCategory.uncertain] if unparseable.
  static ConfidenceCategory fromJson(String value) {
    return ConfidenceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => ConfidenceCategory.uncertain,
    );
  }

  /// Returns the string name representation for JSON serialization.
  String toJson() => name;

  /// English display label.
  String get labelEn {
    switch (this) {
      case ConfidenceCategory.likely:
        return 'Likely';
      case ConfidenceCategory.possible:
        return 'Possible';
      case ConfidenceCategory.uncertain:
        return 'Uncertain';
    }
  }

  /// Hindi display label.
  String get labelHi {
    switch (this) {
      case ConfidenceCategory.likely:
        return 'संभावित';
      case ConfidenceCategory.possible:
        return 'यह रोग हो सकता है';
      case ConfidenceCategory.uncertain:
        return 'निदान अनिश्चित';
    }
  }

  bool get isLikely => this == ConfidenceCategory.likely;
  bool get isPossible => this == ConfidenceCategory.possible;
  bool get isUncertain => this == ConfidenceCategory.uncertain;
}
