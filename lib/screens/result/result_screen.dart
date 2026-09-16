import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../models/confidence_category.dart';
import '../../models/crop.dart';
import '../../models/severity_level.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/language_toggle_widget.dart';
import '../../widgets/severity_chip.dart';
import '../../widgets/consult_expert_bottom_sheet.dart';
import '../../widgets/fertilizer_nutrition_card.dart';
import '../../widgets/treatment_guidance_view.dart';

/// Full-screen diagnosis result view presenting the on-device AI diagnosis.
///
/// Visual hierarchy:
/// - Top App Bar: Back navigation, localized screen title, and compact language toggle.
/// - Top Card: Leaf photograph (rounded 14px) with scan timestamp and crop badge.
/// - Center Details Card:
///   - For Likely/Possible/Healthy: Localized condition title (large semibold),
///     paired with [ConfidenceBadge] and [SeverityChip].
///   - For Uncertain (<60% confidence): Dedicated warning card in Harvest Amber / Deep Rust
///     with prominent retake & KVK contact CTAs; strictly hides any guessed disease name.
/// - Scan Failure Checklist (Uncertain state): Actionable breakdown of lighting, blur, clutter.
/// - Treatment Guidance View: Verified non-chemical cultural steps (hidden in uncertain state).
/// - Sticky Bottom Navigation Bar: Contextual CTAs adapting to confidence & severity.
class ResultScreen extends StatelessWidget {
  /// The diagnosis result model to display.
  /// If null, attempts to read [DiagnosisProvider.currentDiagnosis].
  final DiagnosisResult? result;

  /// Injected image provider override for testing without filesystem access.
  final ImageProvider? imageProviderOverride;

  /// Optional callback invoked when the user taps "Consult Agriculture Expert" or "Contact KVK".
  final VoidCallback? onConsultExpertTap;

  /// Optional callback invoked when the user taps "Done / Back to Home".
  final VoidCallback? onDoneTap;

  /// Optional callback invoked when the user taps back.
  final VoidCallback? onBackTap;

  /// Optional callback invoked when the user taps "Retake Photo in Better Light".
  final VoidCallback? onRetakeTap;

  const ResultScreen({
    super.key,
    this.result,
    this.imageProviderOverride,
    this.onConsultExpertTap,
    this.onDoneTap,
    this.onBackTap,
    this.onRetakeTap,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve active diagnosis result from props or Provider
    DiagnosisResult? activeResult = result;
    if (activeResult == null) {
      try {
        final provider = context.watch<DiagnosisProvider>();
        activeResult = provider.currentDiagnosis;
      } catch (_) {
        activeResult = null;
      }
    }

    final l10n = AppLocalizations.of(context);
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

    if (activeResult == null) {
      return _buildEmptyState(context, l10n);
    }

    return _buildResultScaffold(context, activeResult, l10n, languageCode);
  }

  /// Builds the full diagnosis result screen when an active diagnosis exists.
  Widget _buildResultScaffold(
    BuildContext context,
    DiagnosisResult scan,
    AppLocalizations? l10n,
    String languageCode,
  ) {
    final isHindi = languageCode.toLowerCase() == 'hi';
    final crop = _resolveCrop(scan.cropId);
    final isUncertain = scan.confidenceCategory == ConfidenceCategory.uncertain;
    final isHighSeverity = scan.severity == SeverityLevel.high;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarBgColor,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('result_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => _handleBack(context),
        ),
        title: Text(
          l10n?.resultTitle ?? 'Diagnosis Result',
          style: AppTypography.headline.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LanguageToggleWidget(isCompact: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Leaf Photograph & Metadata Card
            _buildPhotoCard(context, scan, crop, languageCode),
            const SizedBox(height: 16.0),

            // 2. Condition Presentation
            if (isUncertain) ...[
              // Dedicated Low-Confidence / Uncertain Result Screen State (Task 44)
              _buildUncertainDiagnosisCard(
                context,
                scan,
                l10n,
                languageCode,
                isHindi,
              ),
              const SizedBox(height: 16.0),
              // Diagnostic Checklist of why photo might have failed
              _buildUncertainChecklistCard(context, languageCode, isHindi),
            ] else ...[
              // Standard Condition & Diagnosis Details Card
              _buildDiagnosisCard(context, scan, l10n, languageCode, isHindi),
              const SizedBox(height: 16.0),

              // 3. Verified Treatment Guidance (Task 43)
              if (scan.guidance != null && !scan.isHealthy) ...[
                TreatmentGuidanceView(
                  key: const ValueKey('result_treatment_guidance_view'),
                  guidance: scan.guidance!,
                  languageCode: languageCode,
                ),
                const SizedBox(height: 16.0),
              ],

              // 4. Recommended Fertilizer & Crop Nutrition Advisory
              if (scan.guidance != null && scan.guidance!.hasNutritionAdvisory) ...[
                FertilizerNutritionCard(
                  key: const ValueKey('result_fertilizer_nutrition_card'),
                  guidance: scan.guidance!,
                  languageCode: languageCode,
                ),
                const SizedBox(height: 16.0),
              ],

              // 5. Advisory or Reassurance Banner
              _buildAdvisoryBanner(
                scan,
                l10n,
                languageCode,
                false,
                isHighSeverity,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildStickyBottomBar(
        context,
        l10n,
        isUncertain,
        isHighSeverity,
      ),
    );
  }

  /// 1. Top Card displaying the leaf photograph, crop badge, and scan timestamp.
  Widget _buildPhotoCard(
    BuildContext context,
    DiagnosisResult scan,
    Crop crop,
    String languageCode,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy • hh:mm a');
    final formattedDate = dateFormat.format(scan.timestamp);

    return Material(
      color: context.surfaceColor,
      elevation: 1.5,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Leaf Photo Display
          SizedBox(
            height: 220,
            width: double.infinity,
            child: _buildPhotoViewer(scan),
          ),

          // Metadata bar below image (Crop badge, timestamp, sync indicator)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Crop Badge
                Container(
                  key: const ValueKey('result_crop_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(80),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.grass_rounded,
                        size: 15.0,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        crop.localizedName(languageCode),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Timestamp & Sync
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14.0,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      formattedDate,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the photo image with overrides and safe fallback.
  Widget _buildPhotoViewer(DiagnosisResult scan) {
    if (imageProviderOverride != null) {
      return Image(
        key: const ValueKey('result_leaf_image'),
        image: imageProviderOverride!,
        fit: BoxFit.cover,
      );
    }

    if (scan.localImagePath.isNotEmpty) {
      final file = File(scan.localImagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: const ValueKey('result_leaf_image'),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackPhotoPlaceholder(),
        );
      }
    }

    if (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty) {
      return Image.network(
        scan.remoteImageUrl!,
        key: const ValueKey('result_leaf_image'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackPhotoPlaceholder(),
      );
    }

    return _buildFallbackPhotoPlaceholder();
  }

  Widget _buildFallbackPhotoPlaceholder() {
    return Container(
      key: const ValueKey('result_leaf_placeholder'),
      color: const Color(0xFFEFEFEF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 48.0,
              color: AppColors.primary.withAlpha(160),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Captured Leaf Photo',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Standard Center Card for Known Diagnoses (Likely / Possible / Healthy).
  Widget _buildDiagnosisCard(
    BuildContext context,
    DiagnosisResult scan,
    AppLocalizations? l10n,
    String languageCode,
    bool isHindi,
  ) {
    final conditionTitle = _resolveConditionTitle(scan, l10n, languageCode);
    final description = _resolveDescription(scan, l10n, languageCode);

    return Material(
      color: context.surfaceColor,
      elevation: 1.5,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Condition / Disease Title
            Text(
              conditionTitle,
              key: const ValueKey('result_condition_title'),
              style: AppTypography.headline.copyWith(
                color: scan.isHealthy
                    ? AppColors.success
                    : context.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 12.0),

            // Confidence Badge + Severity Chip Row
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConfidenceBadge(
                  key: const ValueKey('result_confidence_badge'),
                  score: scan.confidenceScore,
                  languageCode: languageCode,
                  showPercentage: true,
                ),
                SeverityChip(
                  key: const ValueKey('result_severity_chip'),
                  severity: scan.severity,
                  languageCode: languageCode,
                  isSolid: true,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(height: 1.0, color: context.borderColor),
            const SizedBox(height: 14.0),

            // Section Header: Plain-language explanation
            Text(
              isHindi ? 'लक्षण व स्थिति' : 'What is happening',
              style: AppTypography.sectionTitle.copyWith(
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              description,
              key: const ValueKey('result_description_text'),
              style: AppTypography.body.copyWith(
                color: context.textPrimaryColor,
                height: 1.45,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dedicated Low-Confidence / Uncertain Result State Warning Card (Task 44).
  ///
  /// Strictly adheres to PRD Section 7.6:
  /// - Confidence < 0.60: No disease name asserted.
  /// - Harvest Amber / Deep Rust warning styling.
  /// - Prominent dual action triggers for photo retake and expert consultation.
  Widget _buildUncertainDiagnosisCard(
    BuildContext context,
    DiagnosisResult scan,
    AppLocalizations? l10n,
    String languageCode,
    bool isHindi,
  ) {
    return Material(
      color: context.surfaceColor,
      elevation: 1.5,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: AppColors.warning, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner with Harvest Amber & Deep Rust accents
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF2C2410)
                  : const Color(0xFFFFF8E1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14.0),
                topRight: Radius.circular(14.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.warning.withAlpha(80),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.uncertainDiagnosis ?? 'Uncertain Diagnosis',
                        key: const ValueKey('result_condition_title'),
                        style: AppTypography.headline.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        isHindi
                            ? 'रोग की पुष्टि नहीं हो सकी — कोई दवा न डालें'
                            : 'Inconclusive scan — do not apply chemicals',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF5D4037),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence Badge (Severity is suppressed in Uncertain state per Fix 3)
                ConfidenceBadge(
                  key: const ValueKey('result_confidence_badge'),
                  score: scan.confidenceScore,
                  languageCode: languageCode,
                  showPercentage: true,
                ),
                const SizedBox(height: 14.0),

                // Safety Callout Box
                Container(
                  key: const ValueKey('uncertain_warning_banner'),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: AppColors.error.withAlpha(100),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.error,
                        size: 20.0,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          l10n?.uncertainDiagnosisNotice ?? 'The app is uncertain about this leaf condition. Please do not apply chemicals blindly and consult a certified agriculture officer.',
                          style: AppTypography.body.copyWith(
                            color: const Color(0xFF4E342E),
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Diagnostic checklist card detailing why the photograph might have failed (Task 44).
  Widget _buildUncertainChecklistCard(
    BuildContext context,
    String languageCode,
    bool isHindi,
  ) {
    final checklistItems = [
      (
        icon: Icons.wb_sunny_outlined,
        title: isHindi ? 'छाया व रोशनी की कमी' : 'Harsh Shadows or Low Light',
        desc: isHindi
            ? 'तेज धूप की कड़ी छाया या अंधेरे में पत्ती के लक्षण छिप जाते हैं।'
            : 'Harsh direct sunlight shadows or low ambient lighting obscure symptoms.',
      ),
      (
        icon: Icons.center_focus_weak_rounded,
        title: isHindi ? 'दूरी व कैमरा फोकस' : 'Distance or Blur',
        desc: isHindi
            ? 'पत्ती कैमरे से बहुत दूर थी या हाथ हिलने से फोटो धुंधली हो गई।'
            : 'Camera was held too far away or motion blur softened fine leaf details.',
      ),
      (
        icon: Icons.filter_vintage_outlined,
        title: isHindi
            ? 'फ्रेम में एक से अधिक पत्तियां'
            : 'Multiple Leaves in Frame',
        desc: isHindi
            ? 'फ्रेम में पृष्ठभूमि का कचरा, कई पत्तियां या घास-फूस आने से जांच भ्रमित हो सकती है।'
            : 'Multiple overlapping leaves or background clutter confuse the visual model.',
      ),
      (
        icon: Icons.eco_outlined,
        title: isHindi
            ? 'शुरुआती या अस्पष्ट लक्षण'
            : 'Early-Stage or Ambiguous Symptoms',
        desc: isHindi
            ? 'रोग बहुत शुरुआती अवस्था में हो सकता है या पानी की कमी/गर्मी के तनाव जैसा हो सकता है।'
            : 'Symptoms may be in a very early stage or resemble heat/drought stress.',
      ),
    ];

    return Material(
      key: const ValueKey('uncertain_checklist_card'),
      color: context.surfaceColor,
      elevation: 1.5,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primary,
                  size: 22.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    isHindi
                        ? 'फोटो स्पष्ट क्यों नहीं आई? (जांच सूची)'
                        : 'Why might this scan have failed?',
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              isHindi
                  ? 'सटीक एआई परिणाम के लिए इन बातों का ध्यान रखें:'
                  : 'Check for these common issues that reduce AI accuracy:',
              style: AppTypography.caption.copyWith(
                color: context.textSecondaryColor,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14.0),
            Divider(height: 1.0, color: context.borderColor),
            const SizedBox(height: 12.0),

            // Checklist Items
            ...checklistItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        item.icon,
                        size: 18.0,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            item.desc,
                            style: AppTypography.body.copyWith(
                              fontSize: 12.5,
                              color: context.textSecondaryColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tip Banner
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: context.borderColor, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppColors.accent,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'सुझाव: दिन के उजाले में केवल एक पत्ती को फ्रेम के बीच में रखकर स्थिर फोटो लें।'
                          : 'Pro Tip: Frame a single infected leaf steadily in good daylight for best results.',
                      style: AppTypography.caption.copyWith(
                        color: context.textPrimaryColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Advisory banner for healthy or high-severity cases.
  Widget _buildAdvisoryBanner(
    DiagnosisResult scan,
    AppLocalizations? l10n,
    String languageCode,
    bool isUncertain,
    bool isHighSeverity,
  ) {
    if (scan.isHealthy) {
      return Container(
        key: const ValueKey('healthy_reassurance_banner'),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(20),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppColors.success.withAlpha(90),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22.0,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                languageCode == 'hi'
                    ? 'फसल पूरी तरह स्वस्थ है। किसी उपचार या दवा की आवश्यकता नहीं है।'
                    : 'The plant appears healthy. No chemical or cultural treatment required.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isHighSeverity) {
      return Container(
        key: const ValueKey('high_severity_warning_banner'),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.error, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 24.0,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                languageCode == 'hi'
                    ? 'उच्च संक्रमण स्तर: यह रोग तेजी से फैल सकता है। तुरंत रोकथाम के उपाय अपनाएं या कृषि विशेषज्ञ से मिलें।'
                    : 'High infection severity: This condition may spread rapidly. Implement cultural prevention or consult an expert immediately.',
                style: AppTypography.body.copyWith(
                  color: AppColors.error,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// 4. Sticky Bottom Bar adapting dynamically to scan result state.
  Widget _buildStickyBottomBar(
    BuildContext context,
    AppLocalizations? l10n,
    bool isUncertain,
    bool isHighSeverity,
  ) {
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isHindi = languageCode.toLowerCase() == 'hi';

    return Container(
      key: const ValueKey('result_bottom_action_bar'),
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            offset: const Offset(0, -2),
            blurRadius: 6.0,
          ),
        ],
        border: Border(top: BorderSide(color: context.borderColor, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (isUncertain) ...[
              // Primary CTA for Uncertain state: Retake Photo in Better Light (Task 44)
              Expanded(
                flex: 3,
                child: AppButton(
                  key: const ValueKey('retake_photo_button'),
                  text:
                      l10n?.retakePhoto ??
                      (isHindi ? 'साफ़ फोटो दोबारा लें' : 'Retake Photo'),
                  leadingIcon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  onPressed: () => _handleRetake(context),
                ),
              ),
              const SizedBox(width: 12.0),
              // Secondary CTA: Contact Local Krishi Vigyan Kendra (KVK)
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  key: const ValueKey('consult_expert_button'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () => _handleConsultExpert(context),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isHindi ? 'कृषि केंद्र' : 'Contact KVK',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (isHighSeverity) ...[
              // Primary CTA: Consult Agriculture Expert for high severity
              Expanded(
                flex: 3,
                child: AppButton(
                  key: const ValueKey('consult_expert_button'),
                  text: l10n?.consultExpert ?? 'Consult Expert',
                  leadingIcon: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Colors.white,
                    size: 19.0,
                  ),
                  onPressed: () => _handleConsultExpert(context),
                ),
              ),
              const SizedBox(width: 12.0),
              // Secondary CTA: Home
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  key: const ValueKey('done_home_button'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () => _handleDone(context),
                  child: Text(
                    l10n?.homeTitle ?? 'Home',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primary,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Normal Flow: Primary CTA is Done/Home
              Expanded(
                flex: 3,
                child: AppButton(
                  key: const ValueKey('done_home_button'),
                  text: l10n?.homeTitle ?? 'Back to Home',
                  leadingIcon: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  onPressed: () => _handleDone(context),
                ),
              ),
              const SizedBox(width: 12.0),
              // Secondary CTA: Consult Expert
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  key: const ValueKey('consult_expert_button'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () => _handleConsultExpert(context),
                  child: Text(
                    l10n?.callNow ?? 'Expert Help',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primary,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Empty state rendered when no diagnosis is provided.
  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarBgColor,
        title: Text(l10n?.resultTitle ?? 'Diagnosis Result'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.find_in_page_outlined,
                size: 64.0,
                color: context.textSecondaryColor,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No Diagnosis Available',
                style: AppTypography.headline.copyWith(
                  fontSize: 18.0,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Please scan a crop leaf to view diagnosis details.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24.0),
              AppButton(
                text: l10n?.scanLeafCta ?? 'Scan Leaf',
                onPressed: () => _handleDone(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  Crop _resolveCrop(String cropId) {
    return Crop.initialCrops.firstWhere(
      (c) => c.id.toLowerCase() == cropId.toLowerCase(),
      orElse: () => Crop(
        id: cropId,
        nameEn: cropId.isNotEmpty
            ? cropId[0].toUpperCase() + cropId.substring(1)
            : 'Crop',
        nameHi: cropId,
        iconAssetPath: 'assets/icons/crops/tomato.png',
      ),
    );
  }

  String _resolveConditionTitle(
    DiagnosisResult scan,
    AppLocalizations? l10n,
    String languageCode,
  ) {
    if (scan.isHealthy) {
      return l10n?.healthyPlant ?? 'Healthy Plant';
    }

    final diseaseName = scan.localizedDiseaseName(languageCode);

    switch (scan.confidenceCategory) {
      case ConfidenceCategory.likely:
        return l10n?.likelyDisease(diseaseName) ?? 'Likely $diseaseName';
      case ConfidenceCategory.possible:
        return l10n?.possibleDisease(diseaseName) ?? 'Possible $diseaseName';
      case ConfidenceCategory.uncertain:
        return l10n?.uncertainDiagnosis ?? 'Uncertain Diagnosis';
    }
  }

  String _resolveDescription(
    DiagnosisResult scan,
    AppLocalizations? l10n,
    String languageCode,
  ) {
    if (scan.isHealthy) {
      return l10n?.healthyPlantDesc ??
          'No visible signs of disease, pest damage, or nutrient deficiency detected.';
    }

    if (scan.confidenceCategory == ConfidenceCategory.uncertain) {
      return l10n?.uncertainDiagnosisNotice ??
          'The app is uncertain about this leaf condition. Please do not apply chemicals blindly and consult a certified agriculture officer.';
    }

    if (scan.guidance != null) {
      return scan.guidance!.localizedSymptoms(languageCode);
    }

    return languageCode == 'hi'
        ? 'पत्ती पर बीमारी के लक्षण पाए गए हैं। उचित प्रबंधन के लिए सलाह लें।'
        : 'Symptoms detected on plant leaf. Please review guidance steps and consult an expert.';
  }

  void _handleBack(BuildContext context) {
    if (onBackTap != null) {
      onBackTap!();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      try {
        context.go(AppRoutes.home);
      } catch (_) {}
    }
  }

  void _handleDone(BuildContext context) {
    if (onDoneTap != null) {
      onDoneTap!();
      return;
    }

    try {
      context.go(AppRoutes.home);
    } catch (_) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _handleRetake(BuildContext context) {
    if (onRetakeTap != null) {
      onRetakeTap!();
      return;
    }

    try {
      context.go(AppRoutes.scan);
    } catch (_) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _handleConsultExpert(BuildContext context) {
    if (onConsultExpertTap != null) {
      onConsultExpertTap!();
      return;
    }

    ConsultExpertBottomSheet.show(context, result: result);
  }
}
