import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/crop_provider.dart';
import '../../services/camera_service.dart';
import '../home/crop_selection_screen.dart';

/// Full-screen camera viewfinder screen with leaf alignment guide frame,
/// flash toggle, active crop indicator, and gallery upload fallback.
class ScanScreen extends StatefulWidget {
  /// Optional injected [CameraService] for testability.
  final CameraService? cameraService;

  /// Optional injected [CropProvider] for testability.
  final CropProvider? cropProvider;

  /// Optional callback invoked when a photo is captured or selected.
  final ValueChanged<String>? onPhotoCaptured;

  /// Optional callback invoked when the close button is pressed.
  final VoidCallback? onClose;

  const ScanScreen({
    super.key,
    this.cameraService,
    this.cropProvider,
    this.onPhotoCaptured,
    this.onClose,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  late final CameraService _cameraService;
  late final bool _isInternalService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.cameraService != null) {
      _cameraService = widget.cameraService!;
      _isInternalService = false;
    } else {
      _cameraService = CameraService();
      _isInternalService = true;
    }

    _cameraService.addListener(_onCameraUpdated);

    if (!_cameraService.isInitialized) {
      _cameraService.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.removeListener(_onCameraUpdated);
    if (_isInternalService) {
      _cameraService.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle camera lifecycle when app pauses/resumes
    if (!_cameraService.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.initialize();
    }
  }

  void _onCameraUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCropProvider = widget.cropProvider ??
        (() {
          try {
            return context.watch<CropProvider>();
          } catch (_) {
            return null;
          }
        })();

    final l10n = AppLocalizations.of(context);
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final activeCrop =
        effectiveCropProvider?.selectedCrop ?? Crop.initialCrops.first;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Viewfinder / Preview
            _buildViewfinder(),

            // 2. Alignment Guide Box & Instruction Overlay
            _buildAlignmentGuide(l10n),

            // 3. Top Navigation & Action Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildTopBar(context, activeCrop, languageCode, effectiveCropProvider),
              ),
            ),

            // 4. Bottom Capture & Controls Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _buildBottomBar(context, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the camera preview or fallback UI when camera is initializing or unavailable.
  Widget _buildViewfinder() {
    if (_cameraService.isInitialized && _cameraService.controller != null) {
      final controller = _cameraService.controller!;
      final aspectRatio = controller.value.previewSize != null
          ? controller.value.aspectRatio
          : (16.0 / 9.0);

      return LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxWidth * aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          );
        },
      );
    }

    if (_cameraService.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 64.0,
              ),
              const SizedBox(height: 16.0),
              Text(
                _cameraService.errorMessage ?? 'Camera unavailable.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                key: const ValueKey('retry_camera_button'),
                onPressed: () => _cameraService.initialize(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 3.0,
      ),
    );
  }

  /// Builds the on-screen leaf alignment frame with corner brackets and guidance text.
  Widget _buildAlignmentGuide(AppLocalizations? l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxGuideWidth = (constraints.maxWidth * 0.72).clamp(200.0, 320.0);
        final maxGuideHeight = (constraints.maxHeight * 0.52).clamp(240.0, 400.0);
        final guideWidth = maxGuideWidth;
        final guideHeight = (guideWidth * 1.25).clamp(200.0, maxGuideHeight);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alignment Instruction Badge
              Container(
                key: const ValueKey('align_leaf_guide_banner'),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                margin: const EdgeInsets.only(bottom: 18.0),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.center_focus_strong_rounded,
                      color: AppColors.primaryLight,
                      size: 18.0,
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        l10n?.alignLeafGuide ??
                            'Align infected leaf inside the box',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Guide Frame Box
              Container(
                key: const ValueKey('alignment_guide_frame'),
                width: guideWidth,
                height: guideHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.white.withAlpha(90),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top-Left Corner
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCornerBracket(
                        isTop: true,
                        isLeft: true,
                      ),
                    ),
                    // Top-Right Corner
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCornerBracket(
                        isTop: true,
                        isLeft: false,
                      ),
                    ),
                    // Bottom-Left Corner
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCornerBracket(
                        isTop: false,
                        isLeft: true,
                      ),
                    ),
                    // Bottom-Right Corner
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCornerBracket(
                        isTop: false,
                        isLeft: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a high-contrast corner bracket for the viewfinder guide.
  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    const bracketSize = 24.0;
    const strokeWidth = 3.5;
    const bracketColor = AppColors.primaryLight;

    return Container(
      width: bracketSize,
      height: bracketSize,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: bracketColor, width: strokeWidth)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: bracketColor, width: strokeWidth)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: bracketColor, width: strokeWidth)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: bracketColor, width: strokeWidth)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(20.0) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(20.0) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(20.0) : Radius.zero,
          bottomRight:
              !isTop && !isLeft ? const Radius.circular(20.0) : Radius.zero,
        ),
      ),
    );
  }

  /// Builds the top bar with close button, active crop pill, and flash toggle.
  Widget _buildTopBar(
    BuildContext context,
    Crop activeCrop,
    String languageCode,
    CropProvider? cropProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close / Back Button
          _buildCircleIconButton(
            key: const ValueKey('close_scan_button'),
            icon: Icons.close_rounded,
            onPressed: () => _handleClose(context),
          ),

          // Active Crop Pill
          GestureDetector(
            key: const ValueKey('active_crop_pill'),
            onTap: () => _showCropSelector(context, cropProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _cropEmoji(activeCrop.id),
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    activeCrop.localizedName(languageCode),
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white70,
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),

          // Flash Mode Toggle Button
          _buildCircleIconButton(
            key: const ValueKey('flash_toggle_button'),
            icon: _flashIcon(_cameraService.currentFlashMode),
            onPressed: () => _cameraService.toggleFlashMode(),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom control bar with gallery button, shutter capture CTA, and flip button.
  Widget _buildBottomBar(BuildContext context, AppLocalizations? l10n) {
    final canFlipCamera = _cameraService.availableCamerasList.length > 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(190),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Gallery Picker Button
              IconButton(
                key: const ValueKey('gallery_picker_button'),
                icon: Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(32),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.0),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
                onPressed: () => _handlePickFromGallery(context),
              ),

              // Large Circular Shutter Button
              GestureDetector(
                key: const ValueKey('shutter_button'),
                onTap: _cameraService.isTakingPicture ? null : () => _handleCapture(context),
                child: Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(90),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _cameraService.isTakingPicture
                        ? const SizedBox(
                            width: 32.0,
                            height: 32.0,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3.0,
                            ),
                          )
                        : Container(
                            width: 62.0,
                            height: 62.0,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 28.0,
                            ),
                          ),
                  ),
                ),
              ),

              // Flip Camera Button or Balance Spacer
              if (canFlipCamera)
                IconButton(
                  key: const ValueKey('switch_camera_button'),
                  icon: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(32),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.0),
                    ),
                    child: const Icon(
                      Icons.flip_camera_ios_rounded,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                  onPressed: () => _cameraService.switchCamera(),
                )
              else
                const SizedBox(width: 48.0, height: 48.0),
            ],
          ),
          const SizedBox(height: 14.0),

          // Helper Subtitle
          Text(
            l10n?.tapToCapture ?? 'Tap shutter button to capture',
            style: AppTypography.caption.copyWith(
              color: Colors.white70,
              fontSize: 13.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required Key key,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      key: key,
      icon: Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(140),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22.0,
        ),
      ),
      onPressed: onPressed,
    );
  }

  IconData _flashIcon(FlashMode mode) {
    return switch (mode) {
      FlashMode.torch => Icons.flash_on_rounded,
      FlashMode.auto => Icons.flash_auto_rounded,
      _ => Icons.flash_off_rounded,
    };
  }

  String _cropEmoji(String cropId) {
    return switch (cropId) {
      'tomato' => '🍅',
      'potato' => '🥔',
      'wheat' => '🌾',
      'chili' => '🌶️',
      'cotton' => '🌱',
      _ => '🌿',
    };
  }

  Future<void> _handleCapture(BuildContext context) async {
    final XFile? photo = await _cameraService.takePicture();
    if (photo != null && context.mounted) {
      _navigateToPreview(context, photo.path);
    }
  }

  Future<void> _handlePickFromGallery(BuildContext context) async {
    final XFile? photo = await _cameraService.pickImageFromGallery();
    if (photo != null && context.mounted) {
      _navigateToPreview(context, photo.path);
    }
  }

  void _navigateToPreview(BuildContext context, String imagePath) {
    if (widget.onPhotoCaptured != null) {
      widget.onPhotoCaptured!(imagePath);
      return;
    }

    context.push(AppRoutes.scanPreview, extra: imagePath);
  }

  void _showCropSelector(BuildContext context, CropProvider? provider) {
    CropSelectionScreen.showAsModal(context, cropProvider: provider);
  }

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
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
}
