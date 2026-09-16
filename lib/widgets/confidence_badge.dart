import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/confidence_category.dart';

/// Pill-shaped badge displaying AI diagnosis confidence.
///
/// Strictly adheres to PRD Section 7.6:
/// - >85%: Forest Green background, "Likely" label + check icon
/// - 60–85%: Amber Orange background, "Possible" label + info icon
/// - <60%: Deep Rust background, "Uncertain" label + warning icon
/// Never relies on color alone — always pairs semantic color with an explicit icon and text.
class ConfidenceBadge extends StatelessWidget {
  /// Confidence score between 0.0 and 1.0 (or 0–100).
  final double? score;

  /// Explicit category if already computed.
  final ConfidenceCategory? category;

  /// Whether to append formatted percentage (e.g. `Likely (92%)`).
  final bool showPercentage;

  /// Optional language code (`'en'` or `'hi'`).
  final String languageCode;

  /// Whether to render a slightly smaller badge for compact list tiles.
  final bool isCompact;

  const ConfidenceBadge({
    super.key,
    this.score,
    this.category,
    this.showPercentage = true,
    this.languageCode = 'en',
    this.isCompact = false,
  }) : assert(score != null || category != null, 'Either score or category must be provided');

  /// Convenience constructor taking score directly.
  const ConfidenceBadge.fromScore({
    Key? key,
    required double score,
    bool showPercentage = true,
    String languageCode = 'en',
    bool isCompact = false,
  }) : this(
          key: key,
          score: score,
          showPercentage: showPercentage,
          languageCode: languageCode,
          isCompact: isCompact,
        );

  /// Convenience constructor taking [ConfidenceCategory].
  const ConfidenceBadge.fromCategory({
    Key? key,
    required ConfidenceCategory category,
    double? score,
    bool showPercentage = false,
    String languageCode = 'en',
    bool isCompact = false,
  }) : this(
          key: key,
          category: category,
          score: score,
          showPercentage: showPercentage,
          languageCode: languageCode,
          isCompact: isCompact,
        );

  @override
  Widget build(BuildContext context) {
    final double normalizedScore = score != null
        ? (score! > 1.0 ? score! / 100.0 : score!)
        : 0.0;

    final resolvedCategory = category ?? ConfidenceCategory.fromScore(normalizedScore);
    final isHindi = languageCode.toLowerCase() == 'hi';

    Color backgroundColor;
    IconData iconData;
    String label;

    switch (resolvedCategory) {
      case ConfidenceCategory.likely:
        backgroundColor = AppColors.primary;
        iconData = Icons.check_circle;
        label = isHindi ? resolvedCategory.labelHi : resolvedCategory.labelEn;
        break;
      case ConfidenceCategory.possible:
        backgroundColor = AppColors.warning;
        iconData = Icons.info_outline;
        label = isHindi ? resolvedCategory.labelHi : resolvedCategory.labelEn;
        break;
      case ConfidenceCategory.uncertain:
        backgroundColor = AppColors.error;
        iconData = Icons.warning_amber_rounded;
        label = isHindi ? resolvedCategory.labelHi : resolvedCategory.labelEn;
        break;
    }

    final int percentage = (normalizedScore * 100).round();
    final displayText = (showPercentage && score != null) ? '$label ($percentage%)' : label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: isCompact ? 14 : 16,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            displayText,
            style: isCompact
                ? AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                : AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
          ),
        ],
      ),
    );
  }
}
