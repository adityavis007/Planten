import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/severity_level.dart';

/// Pill-shaped indicator chip displaying disease/pest infection severity.
///
/// Complies with accessibility standards by never relying on color alone:
/// - Low: Green (`AppColors.success`) + shield icon + "Low Severity"
/// - Medium: Amber (`AppColors.warning`) + warning icon + "Medium Severity"
/// - High: Deep Rust (`AppColors.error`) + alert icon + "High Severity"
/// - Healthy: Healthy Green (`AppColors.success`) + leaf icon + "Healthy"
class SeverityChip extends StatelessWidget {
  /// The assessed severity level.
  final SeverityLevel severity;

  /// Optional language code (`'en'` or `'hi'`).
  final String languageCode;

  /// If true, renders a filled solid badge rather than a soft-tinted pill.
  final bool isSolid;

  /// Whether to render a compact chip for list tiles and metadata bars.
  final bool isCompact;

  const SeverityChip({
    super.key,
    required this.severity,
    this.languageCode = 'en',
    this.isSolid = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHindi = languageCode.toLowerCase() == 'hi';

    Color baseColor;
    IconData iconData;
    String label;

    switch (severity) {
      case SeverityLevel.healthy:
        baseColor = AppColors.success;
        iconData = Icons.eco_rounded;
        label = isHindi ? severity.labelHi : severity.labelEn;
        break;
      case SeverityLevel.low:
        baseColor = AppColors.success;
        iconData = Icons.shield_outlined;
        label = isHindi ? severity.labelHi : severity.labelEn;
        break;
      case SeverityLevel.medium:
        baseColor = AppColors.warning;
        iconData = Icons.report_problem_outlined;
        label = isHindi ? severity.labelHi : severity.labelEn;
        break;
      case SeverityLevel.high:
        baseColor = AppColors.error;
        iconData = Icons.warning_rounded;
        label = isHindi ? severity.labelHi : severity.labelEn;
        break;
    }

    final backgroundColor = isSolid ? baseColor : baseColor.withAlpha(26);
    final foregroundColor = isSolid ? Colors.white : baseColor;
    final borderColor = isSolid ? Colors.transparent : baseColor.withAlpha(120);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isSolid ? null : Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: isCompact ? 13 : 15,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: isCompact
                ? AppTypography.caption.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  )
                : AppTypography.bodyMedium.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
          ),
        ],
      ),
    );
  }
}
