/// Represents the severity level of plant infection or condition.
enum SeverityLevel {
  /// Plant is healthy with no significant pathogen damage.
  healthy,

  /// Early-stage infection, localized symptoms.
  low,

  /// Moderate infection spreading across multiple leaves.
  medium,

  /// Severe infection requiring urgent intervention or quarantine.
  high;

  /// Parses a string representation into [SeverityLevel].
  ///
  /// Defaults to [SeverityLevel.medium] if unrecognized.
  static SeverityLevel fromJson(String value) {
    return SeverityLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => SeverityLevel.medium,
    );
  }

  /// Returns the string representation for JSON serialization.
  String toJson() => name;

  /// English display label.
  String get labelEn {
    switch (this) {
      case SeverityLevel.healthy:
        return 'Healthy';
      case SeverityLevel.low:
        return 'Low Severity';
      case SeverityLevel.medium:
        return 'Medium Severity';
      case SeverityLevel.high:
        return 'High Severity';
    }
  }

  /// Hindi display label.
  String get labelHi {
    switch (this) {
      case SeverityLevel.healthy:
        return 'स्वस्थ';
      case SeverityLevel.low:
        return 'हल्का प्रकोप';
      case SeverityLevel.medium:
        return 'मध्यम प्रकोप';
      case SeverityLevel.high:
        return 'गंभीर प्रकोप';
    }
  }

  bool get isHealthy => this == SeverityLevel.healthy;
  bool get isLow => this == SeverityLevel.low;
  bool get isMedium => this == SeverityLevel.medium;
  bool get isHigh => this == SeverityLevel.high;
}
