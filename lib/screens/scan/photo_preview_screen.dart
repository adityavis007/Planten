import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/image_quality_checker.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/crop_provider.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/language_toggle_widget.dart';

/// Screen displaying the captured leaf photograph for visual verification,
/// automated blur/lighting quality check, and retake/continue options.
class PhotoPreviewScreen extends StatefulWidget {
  /// Path to the captured or selected image file.
  final String imagePath;

  /// Optional quality check override for testing.
  final Future<ImageQualityResult> Function(String)? qualityCheckOverride;

  /// Optional [ImageProvider] override for testing without local file access.
  final ImageProvider? imageProviderOverride;

  /// Optional callback invoked when the user selects "Retake Photo".
  final VoidCallback? onRetake;

  /// Optional callback invoked when the user selects "Analyze Leaf".
  final ValueChanged<String>? onAnalyze;

  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    this.qualityCheckOverride,
    this.imageProviderOverride,
    this.onRetake,
    this.onAnalyze,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  ImageQualityResult? _qualityResult;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _evaluateQuality();
  }

  Future<void> _evaluateQuality() async {
    setState(() => _isChecking = true);

    try {
      final ImageQualityResult result;
      if (widget.qualityCheckOverride != null) {
        result = await widget.qualityCheckOverride!(widget.imagePath);
      } else {
        result = await ImageQualityChecker.checkQualityFromFile(widget.imagePath);
      }

      if (mounted) {
        setState(() {
          _qualityResult = result;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _qualityResult = const ImageQualityResult(isValid: true);
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

    final hasWarning = !_isChecking &&
        _qualityResult != null &&
        !_qualityResult!.isValid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Zoomable Image Preview
            _buildImageViewer(),

            // 2. Top Navigation Bar (Back, Quality Badge, Language Toggle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildTopBar(context, languageCode),
              ),
            ),

            // 3. Bottom Controls & Warning Section
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _buildBottomControls(context, l10n, languageCode, hasWarning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the zoomable image preview with pinch-to-zoom capability.
  Widget _buildImageViewer() {
    final imageWidget = widget.imageProviderOverride != null
        ? Image(
            image: widget.imageProviderOverride!,
            fit: BoxFit.contain,
          )
        : Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 64.0,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Unable to load leaf image.',
                      style: AppTypography.body.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          );

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Center(child: imageWidget),
    );
  }

  /// Builds the top bar with back navigation, quality pill badge, and language toggle.
  Widget _buildTopBar(BuildContext context, String languageCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            key: const ValueKey('back_preview_button'),
            icon: Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22.0,
              ),
            ),
            onPressed: () => _handleRetake(context),
          ),

          // Quality Status Badge
          _buildQualityStatusBadge(languageCode),

          // Compact Language Switcher
          const LanguageToggleWidget(isCompact: true),
        ],
      ),
    );
  }

  /// Builds the quality status badge chip.
  Widget _buildQualityStatusBadge(String languageCode) {
    if (_isChecking) {
      return Container(
        key: const ValueKey('checking_quality_badge'),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(140),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14.0,
              height: 14.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              languageCode == 'hi' ? 'जांच हो रही है...' : 'Checking...',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final isValid = _qualityResult?.isValid ?? true;

    return Container(
      key: ValueKey(isValid ? 'good_quality_badge' : 'quality_issue_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.primary.withAlpha(180)
            : AppColors.warning.withAlpha(200),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isValid ? Colors.white38 : Colors.white60,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 16.0,
          ),
          const SizedBox(width: 6.0),
          Text(
            isValid
                ? (languageCode == 'hi' ? 'अच्छी फोटो' : 'Good Quality')
                : (languageCode == 'hi' ? 'गुणवत्ता चेतावनी' : 'Quality Issue'),
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom container with warning alert (if needed) and action buttons.
  Widget _buildBottomControls(
    BuildContext context,
    AppLocalizations? l10n,
    String languageCode,
    bool hasWarning,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(200),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quality Warning Alert Banner
          if (hasWarning) ...[
            Container(
              key: const ValueKey('quality_warning_banner'),
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1F16),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: AppColors.warning, width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _qualityResult?.localizedWarning(languageCode) ??
                              (languageCode == 'hi'
                                  ? 'फोटो धुंधली या अंधेरे में है।'
                                  : 'Photo appears blurry or dark.'),
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          languageCode == 'hi'
                              ? 'सटीक जांच के लिए साफ रोशनी में दोबारा फोटो लेने की सलाह दी जाती है।'
                              : 'Retaking in good light is recommended for accurate AI diagnosis.',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          if (hasWarning) ...[
            // When warning is present: Retake is prominent primary button
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    key: const ValueKey('continue_anyway_button'),
                    onPressed: () => _handleAnalyze(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white60, width: 1.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      languageCode == 'hi' ? 'फिर भी जांचें' : 'Continue',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    key: const ValueKey('retake_photo_button'),
                    text: l10n?.retakePhoto ?? 'Retake Photo',
                    leadingIcon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                    onPressed: () => _handleRetake(context),
                  ),
                ),
              ],
            ),
          ] else ...[
            // When photo is clean/valid: Analyze Leaf is primary button
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    key: const ValueKey('retake_photo_button'),
                    onPressed: () => _handleRetake(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white60, width: 1.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      l10n?.retakePhoto ?? 'Retake',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    key: const ValueKey('analyze_leaf_button'),
                    text: l10n?.analyzeLeaf ?? 'Analyze Leaf',
                    trailingIcon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                    onPressed: () => _handleAnalyze(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleRetake(BuildContext context) {
    if (widget.onRetake != null) {
      widget.onRetake!();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      try {
        context.go(AppRoutes.scan);
      } catch (_) {}
    }
  }

  Future<void> _handleAnalyze(BuildContext context) async {
    if (widget.onAnalyze != null) {
      widget.onAnalyze!(widget.imagePath);
      return;
    }

    DiagnosisProvider? diagnosisProvider;
    CropProvider? cropProvider;
    try {
      diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
      cropProvider = Provider.of<CropProvider>(context, listen: false);
    } catch (_) {}

    if (diagnosisProvider != null && cropProvider != null) {
      final crop = cropProvider.selectedCrop ??
          (cropProvider.supportedCrops.isNotEmpty
              ? cropProvider.supportedCrops.first
              : null);
      if (crop != null) {
        final file = File(widget.imagePath);
        try {
          final result = await diagnosisProvider.diagnoseLeaf(file, crop);
          if (context.mounted) {
            context.push(AppRoutes.result, extra: result);
          }
          return;
        } catch (_) {}
      }
    }

    if (context.mounted) {
      context.push(AppRoutes.result);
    }
  }
}
