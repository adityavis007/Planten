import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../l10n/app_localizations.dart';
import '../models/diagnosis_result.dart';
import 'app_button.dart';

/// Modal bottom sheet providing direct contact with agricultural experts,
/// one-tap Kisan Call Center dialing (`1800-180-1551`), and KVK sample preparation steps.
///
/// Designed per PRD Section 7.6, Section 7.7, and Task 45.
class ConsultExpertBottomSheet extends StatelessWidget {
  /// National Kisan Call Center toll-free helpline number.
  static const String kisanCallCenterNumber = '18001801551';
  static const String kisanCallCenterDisplayNumber = '1800-180-1551';

  /// The active diagnosis result, if available.
  final DiagnosisResult? result;

  /// Optional override for URL launching in tests without platform channels.
  final Future<bool> Function(Uri)? urlLauncherOverride;

  /// Optional callback when user taps "Share Diagnosis Card".
  final VoidCallback? onShareTap;

  const ConsultExpertBottomSheet({
    super.key,
    this.result,
    this.urlLauncherOverride,
    this.onShareTap,
  });

  /// Displays the [ConsultExpertBottomSheet] modal with standard styling and drag handle.
  static Future<T?> show<T>(
    BuildContext context, {
    DiagnosisResult? result,
    Future<bool> Function(Uri)? urlLauncherOverride,
    VoidCallback? onShareTap,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ConsultExpertBottomSheet(
        result: result,
        urlLauncherOverride: urlLauncherOverride,
        onShareTap: onShareTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isHindi = languageCode.toLowerCase() == 'hi';

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44.0,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // 2. Header
              _buildHeader(context, l10n, isHindi),
              const SizedBox(height: 18.0),

              // 3. Kisan Call Center (KCC) One-Tap Dialer Card
              _buildKisanCallCenterCard(context, l10n, isHindi),
              const SizedBox(height: 18.0),

              // 4. KVK In-Person Sample Guide
              _buildKvkSampleGuideCard(context, isHindi),
              const SizedBox(height: 18.0),

              // 5. Share Diagnosis Card with Extension Worker
              _buildShareDiagnosisCard(context, isHindi),
              const SizedBox(height: 16.0),

              // 6. Advisory Footer
              _buildAdvisoryFooter(isHindi),
            ],
          ),
        ),
      ),
    );
  }

  /// Sheet header with icon, title, and close button.
  Widget _buildHeader(BuildContext context, AppLocalizations? l10n, bool isHindi) {
    return Row(
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: AppColors.primary,
            size: 24.0,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.consultExpert ?? (isHindi ? 'कृषि अधिकारी से सलाह लें' : 'Consult Agriculture Expert'),
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                isHindi
                    ? 'निशुल्क सरकारी सहायता व मार्गदर्शन'
                    : 'Free Government Agricultural Advisory',
                style: AppTypography.caption.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('close_expert_sheet_button'),
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// National Kisan Call Center dialer card with one-tap dialing.
  Widget _buildKisanCallCenterCard(
    BuildContext context,
    AppLocalizations? l10n,
    bool isHindi,
  ) {
    return Container(
      key: const ValueKey('kisan_call_center_card'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primary.withAlpha(90), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  isHindi ? 'टोल-फ्री' : 'TOLL FREE',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                isHindi ? 'किसान कॉल सेंटर (भारत सरकार)' : 'Kisan Call Center (Govt. of India)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Toll-free phone number (tap to call)
          InkWell(
            onTap: () => _handleCall(context),
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                kisanCallCenterDisplayNumber,
                key: const ValueKey('kcc_number_text'),
                style: AppTypography.headline.copyWith(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),

          Text(
            isHindi
                ? 'प्रतिदिन सुबह 6:00 से रात 10:00 बजे तक • 22 क्षेत्रीय भाषाओं में कृषि वैज्ञानिकों द्वारा सलाह उपलब्ध'
                : 'Available 6:00 AM – 10:00 PM (All 7 Days) • Speak to agronomists in 22 regional languages.',
            style: AppTypography.body.copyWith(
              fontSize: 12.5,
              color: const Color(0xFF2E5D32),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14.0),

          // Primary One-Tap Call CTA
          AppButton(
            key: const ValueKey('kcc_call_button'),
            text: isHindi ? 'अभी कॉल करें (1800-180-1551)' : 'Call Now (1800-180-1551)',
            leadingIcon: const Icon(
              Icons.phone_in_talk_rounded,
              color: Colors.white,
              size: 20.0,
            ),
            onPressed: () => _handleCall(context),
          ),
        ],
      ),
    );
  }

  /// Practical checklist for farmers visiting their district KVK extension center.
  Widget _buildKvkSampleGuideCard(BuildContext context, bool isHindi) {
    final instructions = [
      (
        icon: Icons.grass_rounded,
        title: isHindi ? 'ताजा पत्ती का नमूना लें' : 'Collect Fresh Samples',
        desc: isHindi
            ? 'प्रभावित पौधे से 2-3 पत्तियां लें जिनमें हल्के व गंभीर दोनों लक्षण दिखाई दे रहे हों।'
            : 'Pluck 2–3 leaves displaying early to intermediate symptoms from different canopy levels.',
      ),
      (
        icon: Icons.markunread_mailbox_outlined,
        title: isHindi ? 'कागज के लिफाफे में रखें' : 'Use Paper Envelope or Cloth',
        desc: isHindi
            ? 'नमूने को साफ कागज या अखबार में लपेटें। प्लास्टिक की बंद थैली से बचें ताकि फंगस न सड़े।'
            : 'Wrap in clean dry paper or cloth pouch. Avoid airtight plastic which causes sweating.',
      ),
      (
        icon: Icons.edit_note_rounded,
        title: isHindi ? 'बुआई व मौसम की जानकारी' : 'Note Variety & Field Details',
        desc: isHindi
            ? 'फसल की किस्म, बुआई की तारीख, हाल ही में डाली गई खाद व मौसम (धुंध/बारिश) नोट कर लें।'
            : 'Record sowing date, seed variety, recent fertilizer/irrigation, and local weather.',
      ),
    ];

    return Container(
      key: const ValueKey('kvk_sample_guide_card'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.secondary,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  isHindi ? 'नजदीकी कृषि विज्ञान केंद्र (KVK) पर कैसे दिखाएं?' : 'How to Visit Your Local KVK Officer',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.0,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            isHindi
                ? 'सटीक प्रयोगशाला जांच के लिए कृषि वैज्ञानिक को यह नमूना दिखाएं:'
                : 'Follow these steps before presenting plant samples to extension officers:',
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12.0),
          Divider(height: 1.0, color: context.borderColor),
          const SizedBox(height: 12.0),

          ...instructions.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18.0,
                    color: AppColors.secondary,
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
          )),
        ],
      ),
    );
  }

  /// Share / Save diagnosis card section for extension workers.
  Widget _buildShareDiagnosisCard(BuildContext context, bool isHindi) {
    return Container(
      key: const ValueKey('share_diagnosis_card'),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: context.borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.share_rounded,
              color: AppColors.primary,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'कृषि मित्र से रिपोर्ट साझा करें' : 'Share Scan with Extension Worker',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isHindi
                      ? 'ग्राम सेवक या कृषि अधिकारी को यह डिजिटल कार्ड दिखाएं'
                      : 'Show or send this digital scan card to field officers',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          OutlinedButton(
            key: const ValueKey('share_diagnosis_button'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 40),
              side: const BorderSide(color: AppColors.primary, width: 1.2),
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () => _handleShare(context, isHindi),
            child: Text(
              isHindi ? 'साझा करें' : 'Share',
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Advisory footer reminder.
  Widget _buildAdvisoryFooter(bool isHindi) {
    return Center(
      child: Text(
        isHindi
            ? 'प्लांटन केवल सलाहकार सहायता प्रदान करता है। दवा छिड़काव से पहले कृषि वैज्ञानिक की लिखित अनुशंसा अवश्य लें।'
            : 'Planten is an advisory decision-support tool. Always obtain certified agronomist approval before applying chemical products.',
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    );
  }

  // --- Handlers ---

  Future<void> _handleCall(BuildContext context) async {
    final uri = Uri.parse('tel:$kisanCallCenterNumber');

    if (urlLauncherOverride != null) {
      await urlLauncherOverride!(uri);
      return;
    }

    try {
      // Launch external phone dialer application directly
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri);
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open phone dialer on this device.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dialer error. Please dial 1800-180-1551 manually.'),
          ),
        );
      }
    }
  }

  void _handleShare(BuildContext context, bool isHindi) {
    if (onShareTap != null) {
      onShareTap!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHindi
              ? 'जांच कार्ड तैयार है: किसान कॉल सेंटर या कृषि अधिकारी को दिखाएं।'
              : 'Diagnosis card ready to share with extension worker.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
