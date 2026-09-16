import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/diagnosis_result.dart';
import 'confidence_badge.dart';

/// Summary card component used in scan history lists and dashboard recent scan widgets.
///
/// Layout:
/// - Left: $64\times 64\text{dp}$ photo thumbnail with 8px radius
/// - Center: Localized disease/condition name + formatted date + sync status
/// - Right: Compact [ConfidenceBadge] with score percentage
class ScanHistoryCard extends StatelessWidget {
  /// The diagnosis result model to display.
  final DiagnosisResult scan;

  /// Callback when user taps the card to view full diagnosis result details.
  final VoidCallback? onTap;

  /// Optional callback when user taps the delete icon button.
  final VoidCallback? onDelete;

  /// Language code for localized disease name (`'en'` or `'hi'`).
  final String languageCode;

  const ScanHistoryCard({
    super.key,
    required this.scan,
    this.onTap,
    this.onDelete,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(scan.timestamp);

    return Material(
      color: context.surfaceColor,
      elevation: 1.0,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 64x64 Thumbnail with 8px Radius
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildThumbnail(context),
                ),
              ),
              const SizedBox(width: 12),

              // Center Content: Title + Date + Cloud Sync Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scan.localizedDiseaseName(languageCode),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: AppTypography.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          scan.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                          size: 13,
                          color: scan.isSynced ? AppColors.success : context.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scan.isSynced
                              ? (languageCode == 'hi' ? 'क्लाउड सिंक' : 'Synced')
                              : (languageCode == 'hi' ? 'केवल ऑफलाइन' : 'Offline only'),
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: scan.isSynced ? AppColors.success : context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Content: Compact ConfidenceBadge + optional Delete Button
              if (onDelete != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConfidenceBadge(
                      score: scan.confidenceScore,
                      isCompact: true,
                      languageCode: languageCode,
                      showPercentage: true,
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      key: ValueKey('delete_scan_${scan.id}'),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error.withAlpha(220),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: languageCode == 'hi' ? 'स्कैन हटाएं' : 'Delete scan',
                      onPressed: onDelete,
                    ),
                  ],
                )
              else
                ConfidenceBadge(
                  score: scan.confidenceScore,
                  isCompact: true,
                  languageCode: languageCode,
                  showPercentage: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (scan.localImagePath.isNotEmpty) {
      final file = File(scan.localImagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackThumbnail(context),
        );
      }
    }
    if (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty) {
      return Image.network(
        scan.remoteImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackThumbnail(context),
      );
    }
    return _fallbackThumbnail(context);
  }

  Widget _fallbackThumbnail(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      alignment: Alignment.center,
      child: Icon(
        scan.isHealthy ? Icons.eco : Icons.spa,
        size: 30,
        color: scan.isHealthy ? AppColors.success : AppColors.primaryLight,
      ),
    );
  }
}
