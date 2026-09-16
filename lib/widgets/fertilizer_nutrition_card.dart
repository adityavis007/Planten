import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../l10n/app_localizations.dart';
import '../models/treatment_guidance.dart';

/// Expandable, high-contrast advisory card displaying scientific
/// fertilizer and crop nutrition recommendations.
///
/// Divides recommendations into 3 legally compliant and agronomist-aligned sections:
/// 1. Bio & Organic Nutrition (safe natural soil builders & composts)
/// 2. Balanced Fertilizers & Micronutrients (generic chemical classes, e.g. NPK, Zinc, Boron)
/// 3. Regulatory Safety Disclaimer (advising soil tests and local KVK guidance)
class FertilizerNutritionCard extends StatefulWidget {
  /// The treatment guidance model containing nutrition data.
  final TreatmentGuidance guidance;

  /// Active language code (`'en'` or `'hi'`).
  final String languageCode;

  /// Whether the advisory card starts in an expanded state. Defaults to `true`.
  final bool initiallyExpanded;

  const FertilizerNutritionCard({
    super.key,
    required this.guidance,
    this.languageCode = 'en',
    this.initiallyExpanded = true,
  });

  @override
  State<FertilizerNutritionCard> createState() =>
      _FertilizerNutritionCardState();
}

class _FertilizerNutritionCardState extends State<FertilizerNutritionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.languageCode.toLowerCase() == 'hi';
    final l10n = AppLocalizations.of(context);
    final guidance = widget.guidance;

    final organicNutrition = guidance.localizedOrganicNutrition(widget.languageCode) ??
        (isHindi
            ? 'सड़ी गोबर की खाद या वर्मीकम्पोस्ट (केंचुआ खाद) का प्रयोग करें।'
            : 'Apply well-decomposed farmyard manure or vermicompost to enrich soil health.');

    final fertilizerClass = guidance.localizedFertilizerClass(widget.languageCode) ??
        (isHindi
            ? 'मृदा स्वास्थ्य कार्ड के अनुसार संतुलित NPK और सूक्ष्म पोषक तत्वों का प्रयोग करें।'
            : 'Apply balanced NPK and essential micronutrients based on soil test analysis.');

    final nutritionDisclaimer = guidance.localizedNutritionDisclaimer(widget.languageCode) ??
        (isHindi
            ? 'खाद की सही मात्रा खेत की मिट्टी और फसल की अवस्था पर निर्भर करती है। सटीक मात्रा के लिए नजदीकी कृषि केंद्र (KVK) से संपर्क करें।'
            : 'Nutrient requirements vary by soil conditions and crop stage. Consult your local agricultural officer or Krishi Vigyan Kendra (KVK).');

    final headerTitle = l10n?.nutritionTitle ??
        (isHindi ? 'अनुशंसित खाद व फसल पोषण' : 'Recommended Fertilizer & Nutrition');

    return Material(
      key: const ValueKey('fertilizer_nutrition_card'),
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
          // Header (Tap to toggle expansion)
          InkWell(
            key: const ValueKey('fertilizer_nutrition_header'),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: AppColors.primary,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: AppTypography.sectionTitle.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          isHindi
                              ? 'वैज्ञानिक व संतुलित पोषण सलाह'
                              : 'Scientific & balanced nutrition advisory',
                          style: AppTypography.caption.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 24.0,
                      color: _isExpanded
                          ? AppColors.primary
                          : context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          if (_isExpanded) ...[
            Divider(height: 1.0, color: context.borderColor),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Bio & Organic Nutrition
                  _buildSectionCard(
                    context: context,
                    key: const ValueKey('fertilizer_organic_section'),
                    badgeIcon: Icons.eco_rounded,
                    badgeLabel: l10n?.organicNutritionLabel ??
                        (isHindi
                            ? 'जैविक एवं प्राकृतिक खाद'
                            : 'Bio & Organic Boost'),
                    badgeColor: AppColors.primary,
                    bgColor: AppColors.primaryLight.withAlpha(
                      context.isDarkMode ? 35 : 24,
                    ),
                    borderColor: AppColors.primary.withAlpha(60),
                    bodyText: organicNutrition,
                    bodyTextKey: const ValueKey('fertilizer_organic_content'),
                  ),

                  const SizedBox(height: 14.0),

                  // Section 2: Balanced Fertilizers & Micronutrients
                  _buildSectionCard(
                    context: context,
                    key: const ValueKey('fertilizer_chemical_section'),
                    badgeIcon: Icons.science_outlined,
                    badgeLabel: l10n?.fertilizerClassLabel ??
                        (isHindi
                            ? 'संतुलित उर्वरक एवं पोषण'
                            : 'Balanced Nutrients'),
                    badgeColor: const Color(0xFF0277BD),
                    bgColor: const Color(0xFF0277BD).withAlpha(
                      context.isDarkMode ? 30 : 16,
                    ),
                    borderColor: const Color(0xFF0277BD).withAlpha(60),
                    bodyText: fertilizerClass,
                    bodyTextKey: const ValueKey('fertilizer_chemical_content'),
                  ),

                  const SizedBox(height: 14.0),

                  // Section 3: Safety Disclaimer
                  _buildDisclaimerSection(
                    context: context,
                    key: const ValueKey('fertilizer_disclaimer_section'),
                    disclaimerText: nutritionDisclaimer,
                    noteText: l10n?.dosageDisclaimerNote,
                    isHindi: isHindi,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a high-contrast recommendation section card.
  Widget _buildSectionCard({
    required BuildContext context,
    required Key key,
    required IconData badgeIcon,
    required String badgeLabel,
    required Color badgeColor,
    required Color bgColor,
    required Color borderColor,
    required String bodyText,
    required Key bodyTextKey,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Label Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 16.0, color: badgeColor),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  badgeLabel,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Advisory Body Text (High contrast outdoor readability >= 14sp)
          Text(
            bodyText,
            key: bodyTextKey,
            style: AppTypography.body.copyWith(
              fontSize: 14.0,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the safety disclaimer box.
  Widget _buildDisclaimerSection({
    required BuildContext context,
    required Key key,
    required String disclaimerText,
    String? noteText,
    required bool isHindi,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFFFB74D),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFFE65100),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disclaimerText,
                  key: const ValueKey('fertilizer_disclaimer_content'),
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF4E342E),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (noteText != null && noteText.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    noteText,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFFBF360C),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
