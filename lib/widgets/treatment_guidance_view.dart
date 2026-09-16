import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/treatment_guidance.dart';

/// Expandable cultural and preventative treatment guidance component.
///
/// Designed per PRD Section 7.7 and Task 43:
/// - Expandable accordion sections for:
///   1. "Symptoms / लक्षण"
///   2. "Preventive Actions / रोकथाम के उपाय" (numbered cultural steps)
///   3. "Important Safety Advice / महत्वपूर्ण सूचना"
/// - Strict adherence to non-chemical safety rules: no chemical dosages or brand names.
/// - Certified ICAR / Krishi Vigyan Kendra (KVK) attribution badge.
class TreatmentGuidanceView extends StatefulWidget {
  /// The verified treatment guidance domain model.
  final TreatmentGuidance guidance;

  /// Active language code (`'en'` or `'hi'`).
  final String languageCode;

  /// Whether the "Symptoms" accordion starts expanded.
  final bool initialExpandSymptoms;

  /// Whether the "Preventive Actions" accordion starts expanded.
  final bool initialExpandPrevention;

  /// Whether the "Safety Advice" accordion starts expanded.
  final bool initialExpandSafety;

  const TreatmentGuidanceView({
    super.key,
    required this.guidance,
    this.languageCode = 'en',
    this.initialExpandSymptoms = false,
    this.initialExpandPrevention = true,
    this.initialExpandSafety = false,
  });

  @override
  State<TreatmentGuidanceView> createState() => _TreatmentGuidanceViewState();
}

class _TreatmentGuidanceViewState extends State<TreatmentGuidanceView> {
  late bool _symptomsExpanded;
  late bool _preventionExpanded;
  late bool _safetyExpanded;

  @override
  void initState() {
    super.initState();
    _symptomsExpanded = widget.initialExpandSymptoms;
    _preventionExpanded = widget.initialExpandPrevention;
    _safetyExpanded = widget.initialExpandSafety;
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.languageCode.toLowerCase() == 'hi';
    final guidance = widget.guidance;

    final symptomsText = guidance.localizedSymptoms(widget.languageCode);
    final culturalSteps = guidance.localizedCulturalSteps(widget.languageCode);
    final disclaimerText = guidance.localizedDisclaimer(widget.languageCode);

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
          // 1. Header with Management Category Badge
          _buildHeader(isHindi, guidance),

          Divider(height: 1.0, color: context.borderColor),

          // 2. Accordion 1: Symptoms / लक्षण
          _buildAccordionTile(
            context: context,
            key: const ValueKey('accordion_symptoms'),
            headerKey: const ValueKey('accordion_symptoms_header'),
            title: isHindi ? 'लक्षण' : 'Symptoms',
            icon: Icons.search_rounded,
            isExpanded: _symptomsExpanded,
            onToggle: () => setState(() => _symptomsExpanded = !_symptomsExpanded),
            child: Text(
              symptomsText,
              key: const ValueKey('guidance_symptoms_content'),
              style: AppTypography.body.copyWith(
                height: 1.5,
                color: context.textPrimaryColor,
              ),
            ),
          ),

          Divider(height: 1.0, color: context.borderColor),

          // 3. Accordion 2: Preventive & Cultural Actions / रोकथाम के उपाय
          _buildAccordionTile(
            context: context,
            key: const ValueKey('accordion_prevention'),
            headerKey: const ValueKey('accordion_prevention_header'),
            title: isHindi ? 'रोकथाम के उपाय' : 'Preventive Actions',
            icon: Icons.shield_outlined,
            isExpanded: _preventionExpanded,
            onToggle: () => setState(() => _preventionExpanded = !_preventionExpanded),
            child: _buildNumberedStepsList(context, culturalSteps),
          ),

          Divider(height: 1.0, color: context.borderColor),

          // 4. Accordion 3: Safety Advice / महत्वपूर्ण सुरक्षा सलाह
          _buildAccordionTile(
            context: context,
            key: const ValueKey('accordion_safety'),
            headerKey: const ValueKey('accordion_safety_header'),
            title: isHindi ? 'महत्वपूर्ण सूचना व सलाह' : 'Important Safety Advice',
            icon: Icons.verified_user_outlined,
            isExpanded: _safetyExpanded,
            onToggle: () => setState(() => _safetyExpanded = !_safetyExpanded),
            child: _buildSafetyAdviceBox(context, isHindi, disclaimerText),
          ),

          Divider(height: 1.0, color: context.borderColor),

          // 5. Verified Source Attribution (ICAR & KVK)
          _buildAttributionFooter(context, isHindi),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isHindi, TreatmentGuidance guidance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.healing_rounded,
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
                  isHindi ? 'रोकथाम व प्रबंधन' : 'Management Guidance',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isHindi
                      ? 'कृषि वैज्ञानिकों द्वारा प्रमाणित सुरक्षा उपाय'
                      : 'Agronomist-verified cultural care steps',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          // Category chip
          Container(
            key: const ValueKey('management_category_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(25),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: AppColors.secondary.withAlpha(80),
                width: 0.8,
              ),
            ),
            child: Text(
              guidance.managementCategory,
              style: AppTypography.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Collapsible accordion tile following clean disclosure pattern.
  Widget _buildAccordionTile({
    required BuildContext context,
    required Key key,
    required Key headerKey,
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      key: key,
      children: [
        InkWell(
          key: headerKey,
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.0,
                  color: isExpanded ? AppColors.primary : context.textSecondaryColor,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isExpanded ? AppColors.primary : context.textPrimaryColor,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22.0,
                    color: isExpanded ? AppColors.primary : context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: child,
          ),
      ],
    );
  }

  /// Numbered list of cultural steps for the "Preventive Actions" accordion.
  Widget _buildNumberedStepsList(BuildContext context, List<String> steps) {
    if (steps.isEmpty) {
      return Text(
        'No specific cultural steps available.',
        style: AppTypography.body.copyWith(color: context.textSecondaryColor),
      );
    }

    return Column(
      key: const ValueKey('guidance_prevention_content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final stepNumber = index + 1;
        final stepText = steps[index];

        return Padding(
          padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 10.0 : 0.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Number Badge
              Container(
                width: 24.0,
                height: 24.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(90),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$stepNumber',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.0,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              // Step Text
              Expanded(
                child: Text(
                  stepText,
                  style: AppTypography.body.copyWith(
                    height: 1.45,
                    fontSize: 14.0,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Box for "Important Safety Advice" emphasizing verified KVK advice & no chemical prescriptions.
  Widget _buildSafetyAdviceBox(BuildContext context, bool isHindi, String disclaimerText) {
    final boxBg = context.isDarkMode ? const Color(0xFF2C2410) : const Color(0xFFFFF9E6);
    final titleColor = context.isDarkMode ? const Color(0xFFFFD54F) : const Color(0xFF5D4037);
    final bodyColor = context.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF4E342E);

    return Container(
      key: const ValueKey('guidance_safety_content'),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.warning.withAlpha(120), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  isHindi
                      ? 'रासायनिक दवाओं का अंधाधुंध छिड़काव न करें'
                      : 'Avoid Unauthorized Chemical Spraying',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.0,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            disclaimerText.isNotEmpty
                ? disclaimerText
                : (isHindi
                    ? 'प्लांटन रासायनिक दवाओं की मात्रा नहीं बताता। किसी भी कीटनाशक के प्रयोग से पहले स्थानीय कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से संपर्क करें।'
                    : 'Planten does not prescribe chemical dosages. Consult your nearest Krishi Vigyan Kendra (KVK) or agriculture officer before applying chemical products.'),
            style: AppTypography.body.copyWith(
              fontSize: 13.0,
              height: 1.4,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Attribution note citing ICAR & Krishi Vigyan Kendra (KVK) guidelines.
  Widget _buildAttributionFooter(BuildContext context, bool isHindi) {
    return Container(
      key: const ValueKey('icar_kvk_attribution'),
      color: context.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 16.0,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              isHindi
                  ? 'स्रोत: आईसीएआर (ICAR) एवं कृषि विज्ञान केंद्र (KVK) द्वारा प्रमाणित सलाह'
                  : 'Source: Verified by ICAR & Krishi Vigyan Kendra (KVK) Advisory',
              style: AppTypography.caption.copyWith(
                color: context.textSecondaryColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
