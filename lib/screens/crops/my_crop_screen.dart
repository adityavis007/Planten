import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/crop.dart';
import '../../models/crop_farming_guide.dart';
import 'crop_farming_detail_screen.dart';

/// Screen presenting the 2-column grid of agricultural crops.
///
/// Features exact components from Screen 1 of user wireframe sketch:
/// - Header: "My Crop"
/// - 2-column grid of rounded crop cards:
///   - Tomato, Potato, Wheat, Chili, Cotton
/// - Tapping any crop navigates to [CropFarmingDetailScreen].
class MyCropScreen extends StatelessWidget {
  /// Optional list of crops to display for testing or overrides.
  final List<Crop>? crops;

  /// Optional callback when tapping a crop card.
  final void Function(Crop crop)? onCropTap;

  const MyCropScreen({super.key, this.crops, this.onCropTap});

  @override
  Widget build(BuildContext context) {
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isHindi = languageCode.toLowerCase() == 'hi';
    final displayCrops = crops ?? Crop.initialCrops;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarBgColor,
        elevation: 0,
        title: Text(
          isHindi ? 'मेरी फसलें (My Crop)' : 'My Crop',
          style: AppTypography.headline.copyWith(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guidance banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(50),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      size: 20.0,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        isHindi
                            ? 'खेती की संपूर्ण जानकारी और मार्गदर्शन के लिए फसल चुनें'
                            : 'Select a crop for verified farming and cultivation guide',
                        style: AppTypography.caption.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 2-Column Crop Cards Grid (Matching Wireframe Sketch)
              Expanded(
                child: GridView.builder(
                  key: const ValueKey('my_crop_grid'),
                  itemCount: displayCrops.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.0,
                    mainAxisSpacing: 14.0,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final crop = displayCrops[index];
                    final guide = CropFarmingGuide.fromCropId(crop.id);
                    return _buildCropCard(
                      context,
                      crop,
                      guide,
                      isHindi,
                      languageCode,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropCard(
    BuildContext context,
    Crop crop,
    CropFarmingGuide guide,
    bool isHindi,
    String languageCode,
  ) {
    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(16.0),
      elevation: 2.0,
      shadowColor: Colors.black.withAlpha(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('crop_card_${crop.id}'),
        onTap: () {
          if (onCropTap != null) {
            onCropTap!(crop);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CropFarmingDetailScreen(crop: crop),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: context.borderColor, width: 1.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Crop Icon / Emoji
              Container(
                width: 58.0,
                height: 58.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _cropEmoji(crop.id),
                    style: const TextStyle(fontSize: 32.0),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              // Crop Name (e.g. Tomato / टमाटर)
              Text(
                crop.localizedName(languageCode),
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),

              // Duration Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  guide.localizedDuration(languageCode).split('(').first.trim(),
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.0,
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
      ),
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
