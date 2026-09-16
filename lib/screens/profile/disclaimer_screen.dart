import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/language_toggle_widget.dart';

/// Full-screen in-app legal disclaimer and advisory notice screen.
///
/// Prominently displays liability disclaimers, ICAR/KVK guidance standards,
/// zero-chemical prescription guarantees, and toll-free agricultural helpline access.
///
/// Aligned with PRD Section 13 and Task 53 specifications.
class DisclaimerScreen extends StatelessWidget {
  /// Toll-free National Kisan Call Center dialer string.
  static const String kisanHelplineNumber = '18001801551';
  static const String kisanHelplineDisplayNumber = '1800-180-1551';

  /// Mandatory PRD Section 13 core disclaimer statement in English.
  static const String coreStatementEn =
      'Planten is an AI-powered decision support tool. It does not replace '
      'certified agronomist advice. Always consult local agriculture authorities '
      'before applying chemical treatments.';

  /// Mandatory PRD Section 13 core disclaimer statement in Vernacular Hindi.
  static const String coreStatementHi =
      'Planten एक एआई-आधारित निर्णय सहायता उपकरण है। यह प्रमाणित कृषि विशेषज्ञ '
      'की सलाह का विकल्प नहीं है। रासायनिक उपचार लागू करने से पहले हमेशा स्थानीय '
      'कृषि अधिकारियों से परामर्श करें।';

  /// Optional injected [LocaleProvider] for unit and widget testing.
  final LocaleProvider? localeProvider;

  /// Optional override for URL launching in tests without platform channels.
  final Future<bool> Function(Uri)? urlLauncherOverride;

  /// Optional callback invoked when the user confirms reading the disclaimer.
  final VoidCallback? onAccepted;

  const DisclaimerScreen({
    super.key,
    this.localeProvider,
    this.urlLauncherOverride,
    this.onAccepted,
  });

  LocaleProvider? _getLocaleProvider(BuildContext context) {
    if (localeProvider != null) return localeProvider;
    try {
      return Provider.of<LocaleProvider>(context);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleCallHelpline(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: kisanHelplineNumber);
    try {
      if (urlLauncherOverride != null) {
        await urlLauncherOverride!(uri);
        return;
      }
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
            content: Text('Could not open phone dialer.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialer error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocaleProvider = _getLocaleProvider(context);

    return ListenableBuilder(
      listenable: activeLocaleProvider ?? ValueNotifier(null),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final isHindi =
            Localizations.localeOf(context).languageCode == 'hi' ||
            (activeLocaleProvider?.isHindi ?? false);

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            backgroundColor: context.appBarBgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              key: const Key('disclaimer_back_button'),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              l10n?.disclaimer ??
                  (isHindi
                      ? 'कानूनी अस्वीकरण व सलाह'
                      : 'Legal Disclaimer & Advisory'),
              style: AppTypography.headline.copyWith(
                fontSize: isHindi ? 18 : 14,
                color: context.isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
            centerTitle: false,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: LanguageToggleWidget(isCompact: true),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Mandatory Core Disclaimer Hero Card
                  _buildHeroDisclaimerCard(context: context, isHindi: isHindi),
                  const SizedBox(height: 16),

                  // 2. Key Legal & Advisory Principles
                  _buildSectionHeader(
                    context: context,
                    title: isHindi
                        ? 'मुख्य दिशा-निर्देश'
                        : 'Key Operating Principles',
                    icon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildPrincipleCard(
                    context: context,
                    icon: Icons.smart_toy_outlined,
                    iconColor: AppColors.primary,
                    title: isHindi
                        ? 'केवल एआई निर्णय सहायता'
                        : 'Decision Support System Only',
                    description: isHindi
                        ? 'Planten दृश्य लक्षणों के आधार पर बीमारी की संभावना बताता है। यह मिट्टी की गुणवत्ता, मौसम व जड़ संबंधी जटिलताओं का पूर्ण परीक्षण नहीं करता।'
                        : 'Planten analyzes visible leaf patterns to identify probable conditions. It is not an agronomist substitute and cannot evaluate soil chemistry, weather, or root diseases.',
                  ),
                  const SizedBox(height: 10),
                  _buildPrincipleCard(
                    context: context,
                    icon: Icons.block_rounded,
                    iconColor: AppColors.warning,
                    title: isHindi
                        ? 'कीटनाशक दवाओं का नाम व मात्रा निषेध'
                        : 'Zero Chemical Brand/Dosage Prescriptions',
                    description: isHindi
                        ? 'सुरक्षा मानकों के तहत, Planten कभी भी विशिष्ट रासायनिक कीटनाशक ब्रांड या खुराक निर्धारित नहीं करता ताकि फसल को नुकसान न हो।'
                        : 'To prevent crop damage and regulatory violations, Planten strictly provides cultural/preventive guidance and never prescribes commercial chemical brands or dosage amounts.',
                  ),
                  const SizedBox(height: 10),
                  _buildPrincipleCard(
                    context: context,
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.primaryLight,
                    title: isHindi
                        ? 'कृषि विशेषज्ञों (KVK) से सलाह'
                        : 'Mandatory Agronomist Consultation',
                    description: isHindi
                        ? 'अनिश्चित या गंभीर मामलों में कोई भी कीटनाशक डालने से पहले नजदीकी कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से पुष्टि अवश्य करें।'
                        : 'For uncertain, severe, or widespread infections, always verify with your local Krishi Vigyan Kendra (KVK) or extension officer before purchasing farm inputs.',
                  ),
                  const SizedBox(height: 10),
                  _buildPrincipleCard(
                    context: context,
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.secondary,
                    title: isHindi
                        ? 'डेटा व फोटो गोपनीयता'
                        : 'On-Device Inference & Privacy',
                    description: isHindi
                        ? 'रोग निदान आपके फोन पर ऑफलाइन होता है। फोटो को क्लाउड पर अपलोड करना केवल आपकी सहमति (ऑप्ट-इन) पर निर्भर है।'
                        : 'Inference runs 100% locally on your phone. Photo upload to cloud storage is disabled by default and strictly opt-in.',
                  ),
                  const SizedBox(height: 20),

                  // 3. National Kisan Helpline Card
                  _buildHelplineCard(context: context, isHindi: isHindi),
                  const SizedBox(height: 24),

                  // 4. Accept CTA Button
                  AppButton(
                    key: const Key('disclaimer_accept_button'),
                    text: isHindi
                        ? 'मैंने समझ लिया और स्वीकार है'
                        : 'I Understand & Accept',
                    leadingIcon: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (onAccepted != null) {
                        onAccepted!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 1. Mandatory Core Disclaimer Hero Card
  Widget _buildHeroDisclaimerCard({required BuildContext context, required bool isHindi}) {
    final warningBorderColor = context.isDarkMode
        ? AppColors.warning.withAlpha(160)
        : AppColors.warning.withAlpha(120);

    return Container(
      key: const Key('disclaimer_hero_card'),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(context.isDarkMode ? 35 : 25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warningBorderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(context.isDarkMode ? 60 : 50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi
                          ? 'आधिकारिक कानूनी सूचना'
                          : 'Official Legal Notice',
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 16,
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isHindi
                          ? 'कृषि निर्णय सहायता व दायित्व सीमा'
                          : 'Liability Limitation & Support Standard',
                      style: AppTypography.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 12),
          Text(
            isHindi ? coreStatementHi : coreStatementEn,
            key: const Key('core_disclaimer_text'),
            style: AppTypography.body.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Header
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  /// Individual Operating Principle Card
  Widget _buildPrincipleCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. National Kisan Helpline Card
  Widget _buildHelplineCard({
    required BuildContext context,
    required bool isHindi,
  }) {
    return Container(
      key: const Key('kisan_helpline_card'),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? context.borderColor
              : AppColors.primaryLight.withAlpha(120),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi
                          ? 'राष्ट्रीय किसान कॉल सेंटर'
                          : 'National Kisan Call Center',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      isHindi
                          ? 'निःशुल्क सरकारी कृषि सहायता'
                          : 'Free Government Agriculture Helpline',
                      style: AppTypography.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _handleCallHelpline(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  child: Text(
                    kisanHelplineDisplayNumber,
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('call_kisan_center_button'),
                onPressed: () => _handleCallHelpline(context),
                icon: const Icon(Icons.call_rounded, size: 16),
                label: Text(isHindi ? 'कॉल करें' : 'Call Free'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
