import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../models/farmer_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crop_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_sync_service.dart';
import '../../widgets/language_toggle_widget.dart';

/// Comprehensive Farmer Profile & Settings screen:
/// - Farmer details card (Name, Phone number, Village/District, Edit CTA).
/// - Primary crops selector (interactive toggles updating cultivated crops in real-time).
/// - App theme preference tile (Dark & Light mode switcher).
/// - Privacy settings tile: "Back up photos to cloud" switch toggle (strictly opt-in).
/// - Offline sync status indicator ("All scans synced" or "X scans waiting for internet" + "Sync Now").
/// - Legal & advisory disclaimer preview.
/// - "Log Out" button with safety confirmation dialog.
class ProfileScreen extends StatefulWidget {
  /// Optional injected providers and services for widget and integration testing.
  final AuthProvider? authProvider;
  final HistoryProvider? historyProvider;
  final CropProvider? cropProvider;
  final ThemeProvider? themeProvider;
  final FirestoreSyncService? syncService;
  final VoidCallback? onEditDetailsTap;
  final VoidCallback? onLoggedOut;
  final VoidCallback? onDisclaimerTap;

  const ProfileScreen({
    super.key,
    this.authProvider,
    this.historyProvider,
    this.cropProvider,
    this.themeProvider,
    this.syncService,
    this.onEditDetailsTap,
    this.onLoggedOut,
    this.onDisclaimerTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSyncingManual = false;
  String? _syncFeedbackMessage;

  AuthProvider? _getAuthProvider(BuildContext context) {
    if (widget.authProvider != null) return widget.authProvider;
    try {
      return Provider.of<AuthProvider>(context);
    } catch (_) {
      return null;
    }
  }

  HistoryProvider? _getHistoryProvider(BuildContext context) {
    if (widget.historyProvider != null) return widget.historyProvider;
    try {
      return Provider.of<HistoryProvider>(context);
    } catch (_) {
      return null;
    }
  }

  LocaleProvider? _getLocaleProvider(BuildContext context) {
    try {
      return Provider.of<LocaleProvider>(context);
    } catch (_) {
      return null;
    }
  }

  CropProvider? _getCropProvider(BuildContext context) {
    if (widget.cropProvider != null) return widget.cropProvider;
    try {
      return Provider.of<CropProvider>(context);
    } catch (_) {
      return null;
    }
  }

  ThemeProvider? _getThemeProvider(BuildContext context) {
    if (widget.themeProvider != null) return widget.themeProvider;
    try {
      return Provider.of<ThemeProvider>(context);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleToggleCrop(
    String cropId,
    AuthProvider? auth,
    CropProvider? cropProvider,
    bool isHindi,
  ) async {
    if (auth == null) return;

    final existingProfile =
        auth.profile ??
        FarmerProfile(
          uid: auth.user?.uid ?? 'anonymous_uid',
          phoneNumber: auth.user?.phoneNumber ?? '',
          name: '',
          village: '',
          district: '',
          state: '',
          createdAt: DateTime.now(),
        );

    final currentCrops = List<String>.from(existingProfile.primaryCrops);
    if (currentCrops.contains(cropId)) {
      if (currentCrops.length > 1) {
        currentCrops.remove(cropId);
        // If the removed crop was currently active in CropProvider, switch to another selected crop
        if (cropProvider != null &&
            cropProvider.selectedCropId == cropId &&
            currentCrops.isNotEmpty) {
          await cropProvider.selectCropById(currentCrops.first);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'कम से कम एक मुख्य फसल चुनी होनी चाहिए।'
                  : 'At least one primary crop must be selected.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    } else {
      currentCrops.add(cropId);
    }

    final updated = existingProfile.copyWith(
      primaryCrops: currentCrops,
      updatedAt: DateTime.now(),
    );

    await auth.updateProfile(updated);
  }

  Future<void> _handleTogglePhotoBackup(bool value, AuthProvider? auth) async {
    if (auth == null) return;

    final existingProfile =
        auth.profile ??
        FarmerProfile(
          uid: auth.user?.uid ?? 'anonymous_uid',
          phoneNumber: auth.user?.phoneNumber ?? '',
          name: '',
          village: '',
          district: '',
          state: '',
          createdAt: DateTime.now(),
        );

    final updated = existingProfile.copyWith(
      photoBackupOptIn: value,
      updatedAt: DateTime.now(),
    );

    await auth.updateProfile(updated);
  }

  Future<void> _handleManualSync(
    FirestoreSyncService? syncService,
    HistoryProvider? history,
  ) async {
    if (_isSyncingManual) return;
    setState(() {
      _isSyncingManual = true;
      _syncFeedbackMessage = null;
    });

    try {
      final service = syncService ?? FirestoreSyncService();
      final result = await service.syncPendingScans();
      if (mounted) {
        await history?.loadHistory();
        setState(() {
          if (result.status == SyncStatus.offline) {
            _syncFeedbackMessage =
                'Device is offline. Will auto-sync when online.';
          } else if (result.status == SyncStatus.success) {
            _syncFeedbackMessage =
                'Successfully synced ${result.syncedCount} scan(s)!';
          } else if (result.status == SyncStatus.noPending) {
            _syncFeedbackMessage = 'All scans are already synced.';
          } else {
            _syncFeedbackMessage =
                result.errorMessage ??
                'Sync completed with status: ${result.status.name}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncFeedbackMessage = 'Sync error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingManual = false;
        });
      }
    }
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider? auth,
    bool isHindi,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          key: const Key('logout_dialog'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHindi ? 'लॉग आउट करें' : 'Log Out',
                  style: AppTypography.sectionTitle,
                ),
              ),
            ],
          ),
          content: Text(
            isHindi
                ? 'क्या आप वाकई Planten से लॉग आउट करना चाहते हैं? आपकी स्थानीय जांच इस डिवाइस पर सुरक्षित रहेंगी।'
                : 'Are you sure you want to log out of Planten? Your offline scan history will remain safely preserved on this device.',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              key: const Key('cancel_logout_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                isHindi ? 'रद्द करें' : 'Cancel',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              key: const Key('confirm_logout_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                if (auth != null) {
                  await auth.logout();
                }
                if (widget.onLoggedOut != null) {
                  widget.onLoggedOut!();
                } else if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: Text(isHindi ? 'लॉग आउट' : 'Log Out'),
            ),
          ],
        );
      },
    );
  }

  void _showDisclaimerDialog(BuildContext context, bool isHindi) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('disclaimer_dialog'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsOverflowButtonSpacing: 8.0,
          title: Row(
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHindi
                      ? 'कानूनी अस्वीकरण व सलाह'
                      : 'Legal Disclaimer & Advisory',
                  style: AppTypography.sectionTitle,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isHindi
                      ? 'Planten एक एआई-आधारित निर्णय सहायता उपकरण है। यह प्रमाणित कृषि वैज्ञानिक या स्थानीय कृषि विस्तार अधिकारी की सलाह का विकल्प नहीं है। किसी भी रासायनिक उपचार या कीटनाशक के प्रयोग से पहले हमेशा अपने स्थानीय कृषि विज्ञान केंद्र (KVK) या किसान कॉल सेंटर (1800-180-1551) से परामर्श लें।'
                      : 'Planten is an AI-powered agricultural decision support system. It does not replace certified agronomist advice. Always consult local Krishi Vigyan Kendra (KVK) officers or the Kisan Call Center (1800-180-1551) before applying chemical treatments.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1800-180-1551',
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      ElevatedButton.icon(
                        key: const Key('dialog_call_kisan_button'),
                        onPressed: () async {
                          final uri = Uri.parse('tel:18001801551');
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.call_rounded, size: 14),
                        label: Text(
                          isHindi ? 'कॉल करें' : 'Call Free',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('view_full_disclaimer_button'),
              onPressed: () {
                Navigator.of(ctx).pop();
                try {
                  context.push(AppRoutes.disclaimer);
                } catch (_) {}
              },
              child: Text(isHindi ? 'विस्तृत नियम' : 'Full Policy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
              ),
              child: Text(isHindi ? 'समझ गया' : 'Understood'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = _getAuthProvider(context);
    final history = _getHistoryProvider(context);
    final localeProvider = _getLocaleProvider(context);
    final cropProvider = _getCropProvider(context);
    final themeProvider = _getThemeProvider(context);

    final listenables = <Listenable>[
      ?auth,
      ?history,
      ?localeProvider,
      ?cropProvider,
      ?themeProvider,
    ];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final isHindi =
            Localizations.localeOf(context).languageCode == 'hi' ||
            (localeProvider?.isHindi ?? false);
        final l10n = AppLocalizations.of(context);

        final profile = auth?.profile;
        final user = auth?.user;

        final displayName = (profile?.name.trim().isNotEmpty ?? false)
            ? profile!.name.trim()
            : (isHindi ? 'किसान मित्र' : 'Farmer Friend');

        final displayPhone = (profile?.phoneNumber.trim().isNotEmpty ?? false)
            ? profile!.phoneNumber.trim()
            : ((user?.phoneNumber?.trim().isNotEmpty ?? false)
                  ? user!.phoneNumber!.trim()
                  : '+91 98765 43210');

        final locationParts =
            [profile?.village, profile?.district, profile?.state]
                .where((p) => p != null && p.trim().isNotEmpty)
                .map((p) => p!.trim())
                .toList();

        final displayLocation = locationParts.isNotEmpty
            ? locationParts.join(', ')
            : (isHindi ? 'गाँव / जिला दर्ज नहीं है' : 'Location not specified');

        final selectedCrops = profile?.primaryCrops ?? const ['tomato'];
        final photoBackupOptIn = profile?.photoBackupOptIn ?? false;
        final unsyncedCount = history?.unsyncedCount ?? 0;

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            title: Text(
              l10n?.profileTitle ??
                  (isHindi ? 'किसान प्रोफाइल' : 'Farmer Profile'),
              style: AppTypography.headline.copyWith(
                color: context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: context.appBarBgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
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
                  // 1. Farmer Info Card
                  _buildFarmerInfoCard(
                    context: context,
                    displayName: displayName,
                    displayPhone: displayPhone,
                    displayLocation: displayLocation,
                    profilePhotoPath: profile?.profilePhotoPath,
                    isHindi: isHindi,
                  ),
                  const SizedBox(height: 16),

                  // 2. Primary Crops Selector
                  _buildPrimaryCropsCard(
                    context: context,
                    selectedCrops: selectedCrops,
                    auth: auth,
                    cropProvider: cropProvider,
                    isHindi: isHindi,
                  ),
                  const SizedBox(height: 16),

                  // 3. Theme Mode Preference Tile (Dark & Light Theme)
                  _buildThemeCard(
                    context: context,
                    isHindi: isHindi,
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 16),

                  // 4. Privacy Settings Tile (Photo Backup)
                  _buildPrivacyCard(
                    context: context,
                    photoBackupOptIn: photoBackupOptIn,
                    auth: auth,
                    isHindi: isHindi,
                  ),
                  const SizedBox(height: 16),

                  // 5. Offline Sync Status Indicator
                  _buildOfflineSyncCard(
                    context: context,
                    unsyncedCount: unsyncedCount,
                    history: history,
                    isHindi: isHindi,
                  ),
                  const SizedBox(height: 16),

                  // 6. Disclaimer & Legal Notice Tile
                  _buildDisclaimerTile(context: context, isHindi: isHindi),
                  const SizedBox(height: 24),

                  // 7. Log Out Action
                  _buildLogoutButton(auth: auth, isHindi: isHindi),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 1. Farmer Info Card
  Widget _buildFarmerInfoCard({
    required BuildContext context,
    required String displayName,
    required String displayPhone,
    required String displayLocation,
    String? profilePhotoPath,
    required bool isHindi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(context.isDarkMode ? 35 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                key: const Key('profile_screen_avatar'),
                onTap: () {
                  if (widget.onEditDetailsTap != null) {
                    widget.onEditDetailsTap!();
                  } else {
                    context.push(AppRoutes.profileSetup);
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(60),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                  ),
                  child: ClipOval(
                    child:
                        (profilePhotoPath != null &&
                            profilePhotoPath.isNotEmpty &&
                            File(profilePhotoPath).existsSync())
                        ? Image.file(
                            File(profilePhotoPath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.agriculture_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.agriculture_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.sectionTitle.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayPhone,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayLocation,
                            style: AppTypography.caption.copyWith(
                              color: context.textSecondaryColor,
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
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('edit_profile_button'),
              onPressed: () {
                if (widget.onEditDetailsTap != null) {
                  widget.onEditDetailsTap!();
                } else {
                  context.push(AppRoutes.profileSetup);
                }
              },
              icon: const Icon(
                Icons.edit_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                isHindi ? 'विवरण बदलें' : 'Edit Details',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Primary Crops Selector Card
  Widget _buildPrimaryCropsCard({
    required BuildContext context,
    required List<String> selectedCrops,
    required AuthProvider? auth,
    required CropProvider? cropProvider,
    required bool isHindi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.spa_rounded,
                color: context.isDarkMode
                    ? AppColors.primaryLight
                    : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'मेरी मुख्य फसलें' : 'My Primary Crops',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 16,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isHindi
                ? 'जिन फसलों की आप खेती करते हैं उन्हें चुनें (टैप करके जोड़ें या हटाएं)'
                : 'Select crops you cultivate (tap to toggle):',
            style: AppTypography.caption.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Crop.initialCrops.map((crop) {
              final isSelected = selectedCrops.contains(crop.id);
              return FilterChip(
                key: Key('crop_chip_${crop.id}'),
                selected: isSelected,
                showCheckmark: true,
                checkmarkColor: Colors.white,
                label: Text(
                  crop.localizedName(isHindi ? 'hi' : 'en'),
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                backgroundColor: context.backgroundColor,
                selectedColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : context.borderColor,
                  ),
                ),
                onSelected: (_) =>
                    _handleToggleCrop(crop.id, auth, cropProvider, isHindi),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 3. App Theme Mode Card (Light & Dark Theme)
  Widget _buildThemeCard({
    required BuildContext context,
    required bool isHindi,
    ThemeProvider? themeProvider,
  }) {
    final theme = themeProvider ?? _getThemeProvider(context);
    final isDark = theme?.isDarkMode ?? false;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? const Color(0xFFFBC02D) : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? 'ऐप थीम' : 'App Theme',
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 16,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    isHindi
                        ? (isDark ? 'डार्क मोड सक्रिय' : 'लाइट मोड सक्रिय')
                        : (isDark ? 'Dark mode active' : 'Light mode active'),
                    style: AppTypography.caption.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Segmented Theme Switcher: Light / Dark
          Container(
            key: const Key('profile_theme_toggle'),
            height: 38.0,
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: const Key('theme_light_btn'),
                  onTap: () => theme?.setThemeMode(ThemeMode.light),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: !isDark ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.light_mode_rounded,
                            size: 15.0,
                            color: !isDark
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            isHindi ? 'लाइट' : 'Light',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: !isDark
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  key: const Key('theme_dark_btn'),
                  onTap: () => theme?.setThemeMode(ThemeMode.dark),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dark_mode_rounded,
                            size: 15.0,
                            color: isDark
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            isHindi ? 'डार्क' : 'Dark',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Privacy Settings Card (Photo Backup)
  Widget _buildPrivacyCard({
    required BuildContext context,
    required bool photoBackupOptIn,
    required AuthProvider? auth,
    required bool isHindi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: context.isDarkMode
                ? AppColors.primaryLight
                : AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'क्लाउड फोटो बैकअप' : 'Cloud Photo Backup',
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 16,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHindi
                      ? 'पत्तियों की फोटो क्लाउड पर सुरक्षित करें (मोबाइल डेटा का उपयोग करता है)'
                      : 'Back up photos to cloud (uses mobile data & storage)',
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('photo_backup_switch'),
            value: photoBackupOptIn,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => _handleTogglePhotoBackup(val, auth),
          ),
        ],
      ),
    );
  }

  /// 5. Offline Sync Status Indicator Card
  Widget _buildOfflineSyncCard({
    required BuildContext context,
    required int unsyncedCount,
    required HistoryProvider? history,
    required bool isHindi,
  }) {
    final allSynced = unsyncedCount == 0;
    final isDark = context.isDarkMode;
    final cardColor = allSynced
        ? (isDark
              ? const Color(0xFF142414)
              : AppColors.primaryLight.withAlpha(40))
        : (isDark ? const Color(0xFF281C10) : AppColors.warning.withAlpha(30));
    final borderColor = allSynced
        ? (isDark
              ? AppColors.primaryLight.withAlpha(60)
              : AppColors.primaryLight.withAlpha(100))
        : (isDark
              ? AppColors.warning.withAlpha(60)
              : AppColors.warning.withAlpha(100));
    final iconColor = allSynced
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : AppColors.warning;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allSynced ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allSynced
                          ? (isHindi ? 'सभी जांच सिंक हैं' : 'All scans synced')
                          : (isHindi
                                ? '$unsyncedCount जांच सिंक होना बाकी'
                                : '$unsyncedCount scan(s) waiting for internet'),
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allSynced
                          ? (isHindi
                                ? 'आपकी सभी जांच क्लाउड पर सुरक्षित हैं।'
                                : 'All diagnosis records are safely saved.')
                          : (isHindi
                                ? 'इंटरनेट कनेक्ट होने पर अपने आप अपलोड हो जाएंगी।'
                                : 'Will automatically sync when internet restores.'),
                      style: AppTypography.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!allSynced) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSyncingManual)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  ElevatedButton.icon(
                    key: const Key('profile_sync_now_button'),
                    onPressed: () =>
                        _handleManualSync(widget.syncService, history),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text(isHindi ? 'अभी सिंक करें' : 'Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (_syncFeedbackMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _syncFeedbackMessage!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 6. Disclaimer & Legal Notice Tile
  Widget _buildDisclaimerTile({
    required BuildContext context,
    required bool isHindi,
  }) {
    return Material(
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('disclaimer_tile'),
        leading: Icon(
          Icons.gavel_rounded,
          color: context.isDarkMode
              ? AppColors.primaryLight
              : AppColors.primary,
        ),
        title: Text(
          isHindi ? 'कानूनी अस्वीकरण व सलाह' : 'Legal Disclaimer & Advisory',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          isHindi
              ? 'आईसीएआर और कृषि विज्ञान केंद्र निर्देश'
              : 'ICAR & KVK guidance information',
          style: AppTypography.caption.copyWith(
            color: context.textSecondaryColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.textSecondaryColor,
        ),
        onTap: () {
          if (widget.onDisclaimerTap != null) {
            widget.onDisclaimerTap!();
            return;
          }
          _showDisclaimerDialog(context, isHindi);
        },
      ),
    );
  }

  /// 7. Log Out Button
  Widget _buildLogoutButton({
    required AuthProvider? auth,
    required bool isHindi,
  }) {
    return OutlinedButton.icon(
      key: const Key('logout_button'),
      onPressed: () => _showLogoutDialog(context, auth, isHindi),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 48),
      ),
      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
      label: Text(
        isHindi ? 'लॉग आउट करें' : 'Log Out',
        style: AppTypography.sectionTitle.copyWith(
          fontSize: 16,
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
