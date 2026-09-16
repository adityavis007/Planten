import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/crop.dart';

/// Large visual card representing a crop in selection grids and home screen dashboards.
///
/// Complies with outdoor legibility and accessibility guidelines:
/// - Minimum touch target $\ge 100\times 100\text{dp}$
/// - 14px rounded corners with gentle elevation
/// - Active selection highlight with 2.0dp Forest Green border and checkmark badge
class CropTileCard extends StatelessWidget {
  /// The crop domain entity to display.
  final Crop crop;

  /// Whether this crop is currently selected.
  final bool isSelected;

  /// Tap callback executed when user selects the crop.
  final VoidCallback? onTap;

  /// Active language code (`'en'` or `'hi'`) for crop label localization.
  final String languageCode;

  /// Width of the card tile. Enforced minimum is 100.0 dp.
  final double? width;

  /// Height of the card tile. Enforced minimum is 100.0 dp.
  final double? height;

  const CropTileCard({
    super.key,
    required this.crop,
    this.isSelected = false,
    this.onTap,
    this.languageCode = 'en',
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width != null && width! < 100.0 ? 100.0 : width;
    final effectiveHeight = height != null && height! < 100.0 ? 100.0 : height;

    final cardBorder = BorderSide(
      color: isSelected
          ? (context.isDarkMode ? AppColors.primaryLight : AppColors.primary)
          : context.borderColor,
      width: isSelected ? 2.0 : 1.0,
    );

    final cardColor = isSelected
        ? (context.isDarkMode
            ? AppColors.primaryLight.withAlpha(35)
            : AppColors.primary.withAlpha(20))
        : context.surfaceColor;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 100.0,
        minHeight: 100.0,
        maxWidth: effectiveWidth ?? double.infinity,
        maxHeight: effectiveHeight ?? double.infinity,
      ),
      child: Material(
        color: cardColor,
        elevation: isSelected ? 2.0 : 1.0,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: cardBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withAlpha(30),
          highlightColor: AppColors.primary.withAlpha(15),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Crop Icon / Illustration
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          crop.iconAssetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.agriculture,
                              size: 40,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Localized Crop Name
                      Text(
                        crop.localizedName(languageCode),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? (context.isDarkMode ? AppColors.primaryLight : AppColors.primary)
                              : context.textPrimaryColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Accessible Checkmark Overlay when Selected
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
