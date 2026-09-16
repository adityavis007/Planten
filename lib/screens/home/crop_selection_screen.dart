import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/crop_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/crop_tile_card.dart';
import '../../widgets/language_toggle_widget.dart';

/// Screen and modal component for visual crop selection.
///
/// Features:
/// - 2-column [GridView] of [CropTileCard] widgets for all 5 V1 launch crops.
/// - Low-literacy visual card selection with high contrast and minimum 100x100dp touch targets.
/// - Immediate synchronization with [CropProvider] and local storage persistence.
/// - Can be presented as a full screen route or via [showAsModal].
class CropSelectionScreen extends StatelessWidget {
  /// Optional injected [CropProvider] for testing.
  final CropProvider? cropProvider;

  /// Optional callback invoked when a crop is selected.
  final ValueChanged<Crop>? onCropSelected;

  /// Whether this screen is rendered inside a modal bottom sheet.
  final bool isModal;

  const CropSelectionScreen({
    super.key,
    this.cropProvider,
    this.onCropSelected,
    this.isModal = false,
  });

  /// Presents [CropSelectionScreen] as a modal bottom sheet.
  static Future<Crop?> showAsModal(
    BuildContext context, {
    CropProvider? cropProvider,
    ValueChanged<Crop>? onCropSelected,
  }) {
    return showModalBottomSheet<Crop>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.82,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: CropSelectionScreen(
            isModal: true,
            cropProvider: cropProvider,
            onCropSelected: onCropSelected,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCropProvider = cropProvider;
    if (effectiveCropProvider != null) {
      return ListenableBuilder(
        listenable: effectiveCropProvider,
        builder: (context, _) => _buildContent(context, effectiveCropProvider),
      );
    }

    CropProvider? watchedCrop;
    try {
      watchedCrop = context.watch<CropProvider>();
    } catch (_) {
      watchedCrop = null;
    }

    return _buildContent(context, watchedCrop);
  }

  Widget _buildContent(BuildContext context, CropProvider? crop) {
    final l10n = AppLocalizations.of(context);
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

    final crops = crop?.supportedCrops ?? Crop.initialCrops;
    final selectedCrop = crop?.selectedCrop ?? crops.first;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: isModal
            ? IconButton(
                key: const ValueKey('close_crop_selection_button'),
                icon: Icon(Icons.close_rounded, color: context.textPrimaryColor),
                onPressed: () => _handleBack(context),
              )
            : IconButton(
                key: const ValueKey('back_crop_selection_button'),
                icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
                onPressed: () => _handleBack(context),
              ),
        title: Text(
          l10n?.selectCrop ?? 'Select Crop',
          style: AppTypography.headline.copyWith(
            fontSize: 20.0,
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
        child: Column(
          children: [
            // Modal drag handle if in modal mode
            if (isModal) ...[
              Center(
                child: Container(
                  width: 44.0,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ],

            // Subtitle Guidance Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: context.borderColor, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: AppColors.primary,
                      size: 22.0,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Tap a crop below to set it as your active crop for diagnosis.',
                        style: AppTypography.caption.copyWith(
                          color: context.textSecondaryColor,
                          fontSize: 13.0,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2-Column Crop Grid
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                crossAxisCount: 2,
                crossAxisSpacing: 14.0,
                mainAxisSpacing: 14.0,
                childAspectRatio: 1.15,
                children: crops.map((cropItem) {
                  final isSelected = cropItem.id == selectedCrop.id;

                  return KeyedSubtree(
                    key: ValueKey('modal_crop_option_${cropItem.id}'),
                    child: CropTileCard(
                      key: ValueKey('crop_tile_${cropItem.id}'),
                      crop: cropItem,
                      isSelected: isSelected,
                      languageCode: languageCode,
                      onTap: () => _handleSelectCrop(context, crop, cropItem),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom Confirmation Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: AppButton(
                key: const ValueKey('confirm_crop_selection_button'),
                text: 'Done',
                trailingIcon: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20.0,
                ),
                onPressed: () => _handleBack(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSelectCrop(
    BuildContext context,
    CropProvider? provider,
    Crop crop,
  ) async {
    if (provider != null) {
      await provider.selectCrop(crop);
    }
    onCropSelected?.call(crop);

    if (context.mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, crop);
      }
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      try {
        context.go('/home');
      } catch (_) {}
    }
  }
}
