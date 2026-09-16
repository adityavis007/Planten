import 'package:flutter/material.dart';
import 'package:planten/widgets/language_toggle_widget.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/crop.dart';
import '../../models/crop_farming_guide.dart';

/// Screen presenting in-depth crop cultivation and farming guidance.
///
/// Features exact components from user wireframe sketch:
/// - Top header: Circular crop image/avatar, crop name, duration, best weather/month.
/// - Card 1: `(O) Management Guidance` (soil, spacing, irrigation, nutrition).
/// - Card 2: `Symptoms` (major diseases & visual symptoms).
/// - Card 3: `Preventive Action` with bullet points (`o o`).
/// - Card 4: `Important Safety` (PPE, Pre-Harvest Interval, spray precautions).
/// - Bottom Badge: `source: verified` with verified checkmark badge.
class CropFarmingDetailScreen extends StatelessWidget {
  /// The crop for which to display farming guidance.
  final Crop crop;

  /// Optional pre-resolved [CropFarmingGuide] for testing or overrides.
  final CropFarmingGuide? guide;

  const CropFarmingDetailScreen({super.key, required this.crop, this.guide});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isHindi = languageCode.toLowerCase() == 'hi';
    final effectiveGuide = guide ?? CropFarmingGuide.fromCropId(crop.id);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarBgColor,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('crop_detail_back_button'),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          isHindi ? '${crop.nameHi} की खेती' : '${crop.nameEn} Farming Guide',
          style: AppTypography.headline.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 19.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageToggleWidget(isCompact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Section: Circle Image + Crop Name + Duration + Best Weather Month
              _buildCropHeader(context, effectiveGuide, isHindi, languageCode),
              const SizedBox(height: 18.0),

              // 2. Card 1: (O) Management Guidance
              _buildManagementGuidanceCard(
                context,
                effectiveGuide,
                isHindi,
                languageCode,
              ),
              const SizedBox(height: 14.0),

              // 3. Card 2: Symptoms
              _buildSymptomsCard(
                context,
                effectiveGuide,
                isHindi,
                languageCode,
              ),
              const SizedBox(height: 14.0),

              // 4. Card 3: Preventive Action (with bullet points o o)
              _buildPreventiveActionCard(
                context,
                effectiveGuide,
                isHindi,
                languageCode,
              ),
              const SizedBox(height: 14.0),

              // 5. Card 4: Important Safety
              _buildSafetyCard(context, effectiveGuide, isHindi, languageCode),
              const SizedBox(height: 16.0),

              // 6. Footer Badge: source: verified
              _buildVerifiedSourceBadge(
                context,
                effectiveGuide,
                isHindi,
                languageCode,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Top header section featuring circular crop avatar, crop name, duration, and best weather month.
  Widget _buildCropHeader(
    BuildContext context,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Crop Image / Avatar (image in sketch)
          Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withAlpha(70),
                width: 2.0,
              ),
            ),
            child: Center(
              child: Text(
                _cropEmoji(crop.id),
                style: const TextStyle(fontSize: 38.0),
              ),
            ),
          ),
          const SizedBox(width: 18.0),

          // Text column: Crop Name + Duration + Best Weather Month
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Name
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    guide.localizedName(languageCode),
                    style: AppTypography.headline.copyWith(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4.0),

                // Time:- duration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: const Icon(
                        Icons.schedule_rounded,
                        size: 15.0,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3.0),
                    Expanded(
                      child: Text(
                        '${isHindi ? "समय / अवधि:" : "Time / Duration:"} ${guide.localizedDuration(languageCode)}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5.0),

                // Best weather month
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 15.0,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 3.0),
                    Expanded(
                      child: Text(
                        '${isHindi ? "सर्वोत्तम मौसम:" : "Best Weather:"} ${guide.localizedBestWeather(languageCode)}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
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

  /// Card 1: `(O) Management Guidance`
  Widget _buildManagementGuidanceCard(
    BuildContext context,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with (O) Circle Badge
          Row(
            children: [
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.agriculture_rounded,
                    size: 18.0,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  isHindi
                      ? 'प्रबंधन मार्गदर्शन (Management Guidance)'
                      : 'Management Guidance',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Divider(height: 1.0),
          const SizedBox(height: 12.0),

          // Content
          Text(
            guide.localizedManagementGuidance(languageCode),
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: `Symptoms`
  Widget _buildSymptomsCard(
    BuildContext context,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warning, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18.0,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  isHindi ? 'लक्षण (Symptoms)' : 'Symptoms',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Divider(height: 1.0),
          const SizedBox(height: 12.0),

          // Content
          Text(
            guide.localizedSymptoms(languageCode),
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Card 3: `Preventive Action` (with bullet points o o)
  Widget _buildPreventiveActionCard(
    BuildContext context,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    final actions = guide.localizedPreventiveActions(languageCode);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 18.0,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  isHindi
                      ? 'निवारक उपाय (Preventive Action)'
                      : 'Preventive Action',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Divider(height: 1.0),
          const SizedBox(height: 12.0),

          // Bullet Points (o o in sketch)
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 9.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hollow bullet circle 'o' as drawn in wireframe sketch
                  Container(
                    margin: const EdgeInsets.only(top: 5.0, right: 10.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.0),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      action,
                      style: AppTypography.body.copyWith(
                        fontSize: 13.5,
                        height: 1.45,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 4: `Important Safety`
  Widget _buildSafetyCard(
    BuildContext context,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    size: 18.0,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  isHindi
                      ? 'महत्वपूर्ण सुरक्षा (Important Safety)'
                      : 'Important Safety',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Divider(height: 1.0),
          const SizedBox(height: 12.0),

          // Content
          Text(
            guide.localizedSafetyPrecautions(languageCode),
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Badge: `source: verified`
  Widget _buildVerifiedSourceBadge(
    BuildContext context,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 18.0,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              'source: verified (${guide.localizedSource(languageCode)})',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static String _cropEmoji(String cropId) {
    switch (cropId.toLowerCase()) {
      case 'tomato':
        return '🍅';
      case 'potato':
        return '🥔';
      case 'wheat':
        return '🌾';
      case 'chili':
        return '🌶️';
      case 'cotton':
        return '☁️';
      default:
        return '🌱';
    }
  }
}
