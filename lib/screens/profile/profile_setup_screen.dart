import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../models/crop.dart';
import '../../models/farmer_profile.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/language_toggle_widget.dart';

/// Screen allowing new farmers to register their profile details during onboarding:
/// - Full Name, Village, District, State.
/// - Primary crops grown (multi-select chip selector).
/// - Cloud photo backup privacy preference (defaults to strictly OFF).
/// - Profile photo upload via Camera and Gallery.
/// - Saves locally and to Firestore via [AuthProvider], routing to `/home`.
class ProfileSetupScreen extends StatefulWidget {
  /// Optional injected [AuthProvider] for widget testing.
  final AuthProvider? authProvider;

  /// Optional custom callback invoked upon successful profile creation/update.
  final VoidCallback? onSaved;

  /// Optional callback invoked when tapping the disclaimer link during onboarding.
  final VoidCallback? onDisclaimerTap;

  const ProfileSetupScreen({
    super.key,
    this.authProvider,
    this.onSaved,
    this.onDisclaimerTap,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _villageController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;
  late final TextEditingController _phoneController;

  final Set<String> _selectedCropIds = <String>{};
  bool _photoBackupOptIn = false; // Strictly defaults to false (PRD Section 8)
  String? _profilePhotoPath;
  bool _isInitialized = false;

  String? _cropsValidationError;
  String? _clientErrorMessage;

  @override
  void initState() {
    super.initState();
    final existingProfile = widget.authProvider?.profile;

    _nameController = TextEditingController(text: existingProfile?.name ?? '');
    _villageController = TextEditingController(
      text: existingProfile?.village ?? '',
    );
    _districtController = TextEditingController(
      text: existingProfile?.district ?? '',
    );
    _stateController = TextEditingController(
      text: existingProfile?.state ?? '',
    );
    final initialPhone = existingProfile?.phoneNumber ?? '';
    final cleanedPhone = initialPhone.startsWith('+91')
        ? initialPhone.substring(3)
        : initialPhone;
    _phoneController = TextEditingController(text: cleanedPhone);

    if (existingProfile != null) {
      if (existingProfile.primaryCrops.isNotEmpty) {
        _selectedCropIds.addAll(existingProfile.primaryCrops);
      }
      _photoBackupOptIn = existingProfile.photoBackupOptIn;
      _profilePhotoPath = existingProfile.profilePhotoPath;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      AuthProvider? auth = widget.authProvider;
      if (auth == null) {
        try {
          auth = Provider.of<AuthProvider>(context, listen: false);
        } catch (_) {
          auth = null;
        }
      }
      final existingProfile = auth?.profile;
      if (existingProfile != null) {
        if (_nameController.text.isEmpty && existingProfile.name.isNotEmpty) {
          _nameController.text = existingProfile.name;
        }
        if (_villageController.text.isEmpty &&
            existingProfile.village.isNotEmpty) {
          _villageController.text = existingProfile.village;
        }
        if (_districtController.text.isEmpty &&
            existingProfile.district.isNotEmpty) {
          _districtController.text = existingProfile.district;
        }
        if (_stateController.text.isEmpty && existingProfile.state.isNotEmpty) {
          _stateController.text = existingProfile.state;
        }
        if (_phoneController.text.isEmpty &&
            existingProfile.phoneNumber.isNotEmpty) {
          final phone = existingProfile.phoneNumber;
          _phoneController.text =
              phone.startsWith('+91') ? phone.substring(3) : phone;
        }
        if (_selectedCropIds.isEmpty &&
            existingProfile.primaryCrops.isNotEmpty) {
          _selectedCropIds.addAll(existingProfile.primaryCrops);
        }
        _photoBackupOptIn = existingProfile.photoBackupOptIn;
        if (_profilePhotoPath == null &&
            existingProfile.profilePhotoPath != null) {
          _profilePhotoPath = existingProfile.profilePhotoPath;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profilePhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPhotoPickerOptions(BuildContext context, bool isHindi) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal handle bar
                Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  isHindi ? 'प्रोफ़ाइल फ़ोटो चुनें' : 'Select Profile Photo',
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  isHindi
                      ? 'कैमरा या गैलरी से अपनी फोटो अपलोड करें'
                      : 'Choose photo from Camera or Gallery',
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 20.0),

                // Option 1: Camera
                ListTile(
                  key: const Key('photo_picker_camera_tile'),
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 22.0,
                    ),
                  ),
                  title: Text(
                    isHindi ? 'कैमरा (Camera)' : 'Camera',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  subtitle: Text(
                    isHindi
                        ? 'कैमरे से नई फ़ोटो खींचें'
                        : 'Take a photo with camera',
                    style: AppTypography.caption.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8.0),

                // Option 2: Gallery
                ListTile(
                  key: const Key('photo_picker_gallery_tile'),
                  leading: Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 22.0,
                    ),
                  ),
                  title: Text(
                    isHindi ? 'गैलरी (Gallery)' : 'Gallery',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  subtitle: Text(
                    isHindi
                        ? 'गैलरी से मौजूदा फ़ोटो चुनें'
                        : 'Choose from your gallery',
                    style: AppTypography.caption.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),

                // Option 3: Remove photo (if existing)
                if (_profilePhotoPath != null) ...[
                  const SizedBox(height: 8.0),
                  ListTile(
                    key: const Key('photo_picker_remove_tile'),
                    leading: Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 22.0,
                      ),
                    ),
                    title: Text(
                      isHindi ? 'फ़ोटो हटाएं' : 'Remove Photo',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      isHindi
                          ? 'डिफ़ॉल्ट अवतार पर वापस जाएं'
                          : 'Revert to default avatar',
                      style: AppTypography.caption.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _profilePhotoPath = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSaveProfile(AuthProvider? auth) async {
    setState(() {
      _clientErrorMessage = null;
      _cropsValidationError = null;
    });
    auth?.clearError();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasSelectedCrops = _selectedCropIds.isNotEmpty;

    if (!hasSelectedCrops) {
      setState(() {
        _cropsValidationError =
            'Please select at least one crop you cultivate.';
      });
    }

    if (!isFormValid || !hasSelectedCrops) {
      return;
    }

    FocusScope.of(context).unfocus();

    final uid = auth?.user?.uid ?? auth?.profile?.uid ?? 'anonymous_uid';
    final phoneInput = _phoneController.text.trim();
    final phoneNumber = phoneInput.isNotEmpty
        ? (phoneInput.startsWith('+') ? phoneInput : '+91$phoneInput')
        : (auth?.user?.phoneNumber ??
            auth?.profile?.phoneNumber ??
            auth?.pendingPhoneNumber ??
            '');

    final now = DateTime.now();
    final updatedProfile = FarmerProfile(
      uid: uid,
      phoneNumber: phoneNumber,
      name: _nameController.text.trim(),
      village: _villageController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      primaryCrops: _selectedCropIds.toList(),
      photoBackupOptIn: _photoBackupOptIn,
      profilePhotoPath: _profilePhotoPath,
      createdAt: auth?.profile?.createdAt ?? now,
      updatedAt: now,
    );

    bool success = false;
    if (auth != null) {
      success = await auth.updateProfile(updatedProfile);
    } else {
      success = true;
    }

    if (!mounted) return;

    if (success) {
      if (widget.onSaved != null) {
        widget.onSaved!();
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider? auth = widget.authProvider;
    try {
      auth ??= context.watch<AuthProvider>();
    } catch (_) {
      auth = null;
    }

    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final activeError = _clientErrorMessage ?? auth?.errorMessage;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n?.profileSetupTitle ?? 'Profile Setup',
          style: AppTypography.headline.copyWith(
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: LanguageToggleWidget(isCompact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: context.borderColor, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 10.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(60),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              (_profilePhotoPath != null &&
                                  _profilePhotoPath!.isNotEmpty &&
                                  File(_profilePhotoPath!).existsSync())
                              ? Image.file(
                                  File(_profilePhotoPath!),
                                  width: 48.0,
                                  height: 48.0,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_pin_rounded,
                                    color: AppColors.primary,
                                    size: 28.0,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_pin_rounded,
                                  color: AppColors.primary,
                                  size: 28.0,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Your Farm Profile',
                              style: AppTypography.sectionTitle.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16.0,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'Help Planten tailor diagnoses and management advice to your specific crops and region.',
                              style: AppTypography.caption.copyWith(
                                color: context.textSecondaryColor,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Avatar Picker (Camera & Gallery options)
                _buildAvatarPicker(context, locale.languageCode == 'hi'),
                const SizedBox(height: 16.0),

                // Error Banner
                if (activeError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.error, width: 1.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20.0,
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            activeError,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Farmer Name Field
                _buildInputField(
                  context: context,
                  controller: _nameController,
                  label: l10n?.farmerName ?? 'Farmer Name',
                  hint: l10n?.enterFarmerName ?? 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Please enter a valid farmer name (min 2 characters).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Village Field
                _buildInputField(
                  context: context,
                  controller: _villageController,
                  label: l10n?.village ?? 'Village',
                  hint: l10n?.enterVillage ?? 'Enter your village name',
                  icon: Icons.home_work_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your village.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Row for District & State
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        context: context,
                        controller: _districtController,
                        label: l10n?.district ?? 'District',
                        hint: l10n?.enterDistrict ?? 'Enter district',
                        icon: Icons.location_city_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter district.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _buildInputField(
                        context: context,
                        controller: _stateController,
                        label: l10n?.state ?? 'State',
                        hint: l10n?.enterState ?? 'Enter state',
                        icon: Icons.map_outlined,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter state.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Phone Number (Farmer Contact Info)
                _buildInputField(
                  context: context,
                  controller: _phoneController,
                  label: l10n?.phoneNumber ?? 'Phone Number',
                  hint: l10n?.enterPhoneNumber ??
                      'Enter 10-digit mobile number',
                  icon: Icons.phone_outlined,
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        value.trim().length < 10) {
                      return 'Please enter a valid 10-digit mobile number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Primary Crops Multi-Select Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.primaryCrops ?? 'Primary Crops Grown',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.0,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '${_selectedCropIds.length} selected',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Select the primary crops you grow on your farm (at least 1):',
                  style: AppTypography.caption.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 13.0,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Crop Chips Wrap
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: Crop.initialCrops.map((crop) {
                    final isSelected = _selectedCropIds.contains(crop.id);
                    return FilterChip(
                      key: ValueKey('crop_chip_${crop.id}'),
                      selected: isSelected,
                      showCheckmark: true,
                      checkmarkColor: Colors.white,
                      avatar: CircleAvatar(
                        radius: 12.0,
                        backgroundColor: isSelected
                            ? Colors.white.withAlpha(50)
                            : AppColors.primary.withAlpha(20),
                        child: Text(
                          _cropEmoji(crop.id),
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      ),
                      label: Text(
                        crop.localizedName(locale.languageCode),
                        style: AppTypography.body.copyWith(
                          fontSize: 14.0,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : context.textPrimaryColor,
                        ),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: context.surfaceColor,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : context.borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCropIds.add(crop.id);
                            _cropsValidationError = null;
                          } else {
                            _selectedCropIds.remove(crop.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                // Crop Validation Error Message
                if (_cropsValidationError != null) ...[
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      _cropsValidationError!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24.0),

                // Privacy Consent Section (Cloud Photo Backup Opt-In)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: context.borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
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
                                  l10n?.photoBackupConsent ??
                                      'Cloud Photo Backup (Optional)',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  l10n?.photoBackupConsentDesc ?? 'Allow backing up leaf photos to cloud storage for model improvement.',
                                  style: AppTypography.caption.copyWith(
                                    color: context.textSecondaryColor,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Semantics(
                            label: 'Cloud Photo Backup Switch',
                            child: Switch(
                              key: const ValueKey('photo_backup_switch'),
                              value: _photoBackupOptIn,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withAlpha(
                                100,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _photoBackupOptIn = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: context.backgroundColor,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14.0,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                'Leaf photos are diagnosed on-device. Backing up photos is completely optional.',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32.0),

                // Submit CTA Button
                AppButton(
                  key: const ValueKey('save_profile_button'),
                  text: l10n?.saveAndContinue ?? 'Save & Continue',
                  isLoading: auth?.isLoading ?? false,
                  trailingIcon: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  onPressed: () => _handleSaveProfile(auth),
                ),
                const SizedBox(height: 12.0),

                // Disclaimer Link during Onboarding (Task 53)
                InkWell(
                  key: const Key('onboarding_disclaimer_button'),
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () {
                    if (widget.onDisclaimerTap != null) {
                      widget.onDisclaimerTap!();
                      return;
                    }
                    try {
                      context.push(AppRoutes.disclaimer);
                    } catch (_) {
                      _showDisclaimerDialog(
                        context,
                        locale.languageCode == 'hi',
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          size: 14.0,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            locale.languageCode == 'hi'
                                ? 'कानूनी अस्वीकरण व सलाह पढ़ें'
                                : 'Read Legal Disclaimer & Advisory',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          textInputAction: textInputAction,
          style: AppTypography.body.copyWith(
            fontSize: 15.0,
            color: context.textPrimaryColor,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(
              color: context.textSecondaryColor.withAlpha(160),
              fontSize: 14.0,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20.0),
            filled: true,
            fillColor: context.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.error, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  String _cropEmoji(String cropId) {
    switch (cropId) {
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

  void _showDisclaimerDialog(BuildContext context, bool isHindi) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('onboarding_disclaimer_dialog'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            child: Text(
              isHindi
                  ? 'Planten एक एआई-आधारित निर्णय सहायता उपकरण है। यह प्रमाणित कृषि विशेषज्ञ की सलाह का विकल्प नहीं है। रासायनिक उपचार लागू करने से पहले हमेशा स्थानीय कृषि अधिकारियों से परामर्श करें।'
                  : 'Planten is an AI-powered decision support tool. It does not replace certified agronomist advice. Always consult local agriculture authorities before applying chemical treatments.',
              style: AppTypography.body,
            ),
          ),
          actions: [
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

  Widget _buildAvatarPicker(BuildContext context, bool isHindi) {
    final hasPhoto =
        _profilePhotoPath != null &&
        _profilePhotoPath!.isNotEmpty &&
        File(_profilePhotoPath!).existsSync();

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Avatar Circle
              GestureDetector(
                key: const Key('profile_avatar_picker'),
                onTap: () => _showPhotoPickerOptions(context, isHindi),
                child: Container(
                  width: 96.0,
                  height: 96.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(25),
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(35),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? Image.file(
                            File(_profilePhotoPath!),
                            width: 96.0,
                            height: 96.0,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 52.0,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 52.0,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              ),

              // Camera Badge Overlay at Bottom Right
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  key: const Key('profile_camera_badge'),
                  onTap: () => _showPhotoPickerOptions(context, isHindi),
                  child: Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.surfaceColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          TextButton.icon(
            key: const Key('profile_change_photo_text_btn'),
            onPressed: () => _showPhotoPickerOptions(context, isHindi),
            icon: const Icon(
              Icons.add_a_photo_outlined,
              size: 16.0,
              color: AppColors.primary,
            ),
            label: Text(
              hasPhoto
                  ? (isHindi ? 'फोटो बदलें' : 'Change Photo')
                  : (isHindi ? 'फोटो जोड़ें' : 'Add Profile Photo'),
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
