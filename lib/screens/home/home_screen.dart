import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../models/diagnosis_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crop_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/language_toggle_widget.dart';
import '../../widgets/scan_history_card.dart';
import '../../widgets/weather_card.dart';
import 'crop_selection_screen.dart';

/// Main farm home dashboard screen matching user wireframe and visual specs:
/// 1. Farmer Header: Profile Avatar (O) + Greeting + Location + Language Toggle [E|H]
/// 2. Search Bar: Rounded Search input pill
/// 3. Crop Schedule: Title + Active Crop badge + Horizontal circular crop avatars + (+) Add
/// 4. Weather Card: Outdoor real-time/cached weather info
/// 5. Help Your Crop / Scan Leaf for Disease: 3-step visual workflow + prominent Scan CTA
/// 6. Recent Scans: Active crop scan history or clean empty state with "View all"
class HomeScreen extends StatelessWidget {
  /// Optional injected [CropProvider] for testing.
  final CropProvider? cropProvider;

  /// Optional injected [AuthProvider] for testing.
  final AuthProvider? authProvider;

  /// Optional injected [HistoryProvider] for testing.
  final HistoryProvider? historyProvider;

  /// Optional injected [WeatherProvider] for testing.
  final WeatherProvider? weatherProvider;

  /// Optional injected [LocalStorageService] for testing.
  final LocalStorageService? localStorageService;

  /// Optional callback invoked when tapping the hero scan button.
  final VoidCallback? onScanTap;

  /// Optional callback invoked when tapping "Change" / "Add" crop.
  final VoidCallback? onChangeCropTap;

  /// Optional callback invoked when tapping "View All" history.
  final VoidCallback? onViewAllHistoryTap;

  /// Optional callback invoked when tapping the search bar.
  final VoidCallback? onSearchTap;

  const HomeScreen({
    super.key,
    this.cropProvider,
    this.authProvider,
    this.historyProvider,
    this.weatherProvider,
    this.localStorageService,
    this.onScanTap,
    this.onChangeCropTap,
    this.onViewAllHistoryTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCropProvider = cropProvider;
    if (effectiveCropProvider != null) {
      return ListenableBuilder(
        listenable: effectiveCropProvider,
        builder: (context, _) => _buildScaffold(context, effectiveCropProvider),
      );
    }

    CropProvider? watchedCrop;
    try {
      watchedCrop = context.watch<CropProvider>();
    } catch (_) {
      watchedCrop = null;
    }

    return _buildScaffold(context, watchedCrop);
  }

  Widget _buildScaffold(BuildContext context, CropProvider? crop) {
    AuthProvider? auth;
    try {
      auth = authProvider ?? context.watch<AuthProvider>();
    } catch (_) {
      auth = authProvider;
    }

    HistoryProvider? history;
    try {
      history = historyProvider ?? context.watch<HistoryProvider>();
    } catch (_) {
      history = historyProvider;
    }

    WeatherProvider? weather;
    try {
      weather = weatherProvider ?? context.watch<WeatherProvider>();
    } catch (_) {
      weather = weatherProvider;
    }

    final storage = localStorageService ?? LocalStorageService();
    final l10n = AppLocalizations.of(context);
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

    final activeCrop = crop?.selectedCrop ?? Crop.initialCrops.first;
    final activeCropId = activeCrop.id;

    // Fetch recent scans for active crop (reactively from HistoryProvider or fallback to storage)
    final allScans = (history != null && history.scans.isNotEmpty)
        ? history.scans
        : storage.getOfflineScans();
    final recentScans = allScans
        .where((s) => s.cropId.toLowerCase() == activeCropId.toLowerCase())
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Farmer Greeting Header (Avatar + Namaste + Language toggle [E|H])
              _buildFarmerHeader(context, auth, l10n, languageCode),
              const SizedBox(height: 14.0),

              // 2. Search Bar
              _buildSearchBar(context, languageCode, l10n),
              const SizedBox(height: 16.0),

              // 3. Crop Schedule (Horizontal circular items: Tomato, Potato, Chili, Wheat, Cotton, + Add)
              _buildCropScheduleSection(
                context: context,
                crop: crop,
                activeCrop: activeCrop,
                l10n: l10n,
                languageCode: languageCode,
              ),
              const SizedBox(height: 18.0),

              // 4. Outdoor Weather Card (Real-time live or cached forecast)
              WeatherCard(weatherProvider: weather, authProvider: auth),
              const SizedBox(height: 18.0),

              // 5. Help Your Crop / Scan Leaf for Disease (3-Step Guide + Prominent Scan CTA)
              _buildHelpYourCropCard(context, l10n, languageCode),
              const SizedBox(height: 22.0),

              // 6. Recent Scans Section
              _buildRecentScansSection(
                context: context,
                recentScans: recentScans,
                activeCrop: activeCrop,
                l10n: l10n,
                languageCode: languageCode,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Farmer Header: Profile Avatar (O) + Greeting + Location + Language Toggle
  Widget _buildFarmerHeader(
    BuildContext context,
    AuthProvider? auth,
    AppLocalizations? l10n,
    String languageCode,
  ) {
    final profile = auth?.profile;
    final farmerName = profile?.name.trim();
    final location = profile?.locationDisplay;

    String dateFormatted;
    try {
      dateFormatted = DateFormat(
        'EEEE, d MMMM',
        languageCode,
      ).format(DateTime.now());
    } catch (_) {
      dateFormatted = DateFormat('EEEE, d MMMM').format(DateTime.now());
    }

    final greetingTitle = (farmerName != null && farmerName.isNotEmpty)
        ? (languageCode == 'hi'
              ? 'नमस्ते, $farmerName'
              : 'Namaste, $farmerName')
        : (languageCode == 'hi' ? 'नमस्ते किसान' : 'Namaste, Farmer');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar (Clickable to navigate to Profile Screen)
        Semantics(
          label: languageCode == 'hi' ? 'प्रोफ़ाइल देखें' : 'View Profile',
          button: true,
          child: GestureDetector(
            key: const Key('home_screen_profile_avatar'),
            onTap: () => context.go(AppRoutes.profile),
            child: Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(80),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(20),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    (profile?.profilePhotoPath != null &&
                        profile!.profilePhotoPath!.isNotEmpty &&
                        File(profile.profilePhotoPath!).existsSync())
                    ? Image.file(
                        File(profile.profilePhotoPath!),
                        width: 48.0,
                        height: 48.0,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 26.0,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 26.0,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Greeting & Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greetingTitle,
                style: AppTypography.headline.copyWith(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3.0),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 3.0),
                  Expanded(
                    child: Text(
                      (location != null && location.isNotEmpty)
                          ? location
                          : dateFormatted,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12.5,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),

        // Language Switcher [ E | H ]
        const LanguageToggleWidget(isCompact: true),
      ],
    );
  }

  /// 2. Search Bar: Rounded Search input pill
  Widget _buildSearchBar(
    BuildContext context,
    String languageCode,
    AppLocalizations? l10n,
  ) {
    final hintText = languageCode == 'hi'
        ? 'फसल, रोग या लक्षण खोजें...'
        : 'Search crop, disease, or symptoms...';

    return Semantics(
      label: languageCode == 'hi' ? 'खोजें' : 'Search',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('home_search_bar'),
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            if (onSearchTap != null) {
              onSearchTap!();
            } else {
              context.go(AppRoutes.search);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 13.0,
            ),
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
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    hintText,
                    style: AppTypography.body.copyWith(
                      color: context.textSecondaryColor.withAlpha(180),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3. Crop Schedule Section: Horizontal circular crop avatars with active ring & (+) Add button
  Widget _buildCropScheduleSection({
    required BuildContext context,
    required CropProvider? crop,
    required Crop activeCrop,
    required AppLocalizations? l10n,
    required String languageCode,
  }) {
    final title = languageCode == 'hi' ? 'फसल अनुसूची' : 'Crop Schedule';
    final crops = crop?.supportedCrops ?? Crop.initialCrops;

    void handleChangeCrop() {
      if (onChangeCropTap != null) {
        onChangeCropTap!();
      } else {
        CropSelectionScreen.showAsModal(context, cropProvider: crop);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row: Title + "Active Crop" indicator badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppColors.primary.withAlpha(60),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    l10n?.activeCrop ?? 'Active Crop',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Horizontal Row of Circular Crop Avatars + Add Button
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...crops.map((c) {
                final isSelected =
                    c.id.toLowerCase() == activeCrop.id.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: _buildCropCircleItem(
                    context: context,
                    crop: c,
                    isSelected: isSelected,
                    languageCode: languageCode,
                    onTap: () {
                      crop?.selectCrop(c);
                    },
                  ),
                );
              }),

              // (+) Add Button Circle
              _buildAddCropCircleItem(
                context: context,
                languageCode: languageCode,
                onTap: handleChangeCrop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Single Circular Crop Avatar
  Widget _buildCropCircleItem({
    required BuildContext context,
    required Crop crop,
    required bool isSelected,
    required String languageCode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62.0,
                height: 62.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary.withAlpha(25)
                      : context.surfaceColor,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : context.borderColor,
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withAlpha(45),
                        blurRadius: 10.0,
                        offset: const Offset(0, 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 4.0,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _cropEmoji(crop.id),
                    style: const TextStyle(fontSize: 28.0),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11.0,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6.0),
          SizedBox(
            width: 64.0,
            child: Text(
              crop.localizedName(languageCode),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (context.isDarkMode
                          ? AppColors.primaryLight
                          : AppColors.primary)
                    : context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Circular (+) Add / Change Crop Button
  Widget _buildAddCropCircleItem({
    required BuildContext context,
    required String languageCode,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('change_crop_button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62.0,
              height: 62.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
                border: Border.all(
                  color: AppColors.primary.withAlpha(90),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(15),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 30.0,
                ),
              ),
            ),
            const SizedBox(height: 6.0),
            SizedBox(
              width: 64.0,
              child: Text(
                languageCode == 'hi' ? 'जोड़ें' : 'Add',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Help Your Crop Card: 3-step visual workflow + prominent CTA button
  Widget _buildHelpYourCropCard(
    BuildContext context,
    AppLocalizations? l10n,
    String languageCode,
  ) {
    final titleText = languageCode == 'hi'
        ? 'अपनी फसल की जाँच करें'
        : 'Help your crop';
    final step1Text = languageCode == 'hi' ? 'फोटो खींचें' : 'Take the picture';
    final step2Text = languageCode == 'hi' ? 'रोग पहचानें' : 'Analyse Disease';
    final step3Text = languageCode == 'hi'
        ? 'रिपोर्ट देखें'
        : 'Check the report';

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1B2E1E)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.primary.withAlpha(context.isDarkMode ? 60 : 40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(context.isDarkMode ? 30 : 12),
            blurRadius: 14.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            titleText,
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16.0),

          // 3-step visual workflow (Responsive Row)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Step 1: Take picture
              Expanded(
                child: _buildWorkflowStep(
                  icon: Icons.filter_center_focus_rounded,
                  label: step1Text,
                  context: context,
                ),
              ),

              // Arrow 1
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: AppColors.primary.withAlpha(180),
                  size: 20.0,
                ),
              ),

              // Step 2: Analyse Disease
              Expanded(
                child: _buildWorkflowStep(
                  icon: Icons.search_rounded,
                  label: step2Text,
                  context: context,
                ),
              ),

              // Arrow 2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: AppColors.primary.withAlpha(180),
                  size: 20.0,
                ),
              ),

              // Step 3: Check report
              Expanded(
                child: _buildWorkflowStep(
                  icon: Icons.assignment_turned_in_outlined,
                  label: step3Text,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // Prominent CTA Button (Full Width Pill)
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24.0),
              elevation: 2.0,
              shadowColor: AppColors.primary.withAlpha(90),
              child: InkWell(
                key: const ValueKey('hero_scan_card'),
                borderRadius: BorderRadius.circular(24.0),
                onTap: () {
                  if (onScanTap != null) {
                    onScanTap!();
                  } else {
                    context.push(AppRoutes.scan);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Text(
                          l10n?.scanLeafCta ?? 'Scan Leaf for Disease',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for 3-step visual workflow item
  Widget _buildWorkflowStep({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppColors.primary.withAlpha(50),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: AppColors.primary, size: 22.0),
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 6. Recent Scans Section: Active crop recent scan records or empty state
  Widget _buildRecentScansSection({
    required BuildContext context,
    required List<DiagnosisResult> recentScans,
    required Crop activeCrop,
    required AppLocalizations? l10n,
    required String languageCode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n?.recentScans ?? 'Recent Scans',
                style: AppTypography.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.0,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const ValueKey('view_all_scans_button'),
              onPressed: () {
                if (onViewAllHistoryTap != null) {
                  onViewAllHistoryTap!();
                } else {
                  context.go(AppRoutes.history);
                }
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
              child: Text(
                l10n?.viewAll ?? 'View All',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Scans Content List or Empty State
        if (recentScans.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentScans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final scan = recentScans[index];
              return ScanHistoryCard(
                scan: scan,
                languageCode: languageCode,
                onTap: () => context.push(AppRoutes.result, extra: scan),
              );
            },
          ),
        ] else ...[
          // Empty State Card
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 28.0,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: context.borderColor, width: 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco_outlined,
                      size: 32.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),
                Text(
                  l10n?.noRecentScans ??
                      'No recent scans. Tap scan to diagnose your crop.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 14.0,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
