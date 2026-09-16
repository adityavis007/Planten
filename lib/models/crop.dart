import 'package:flutter/foundation.dart';

/// Immutable domain model representing a supported agricultural crop.
@immutable
class Crop {
  /// Unique identifier of the crop (e.g. `'tomato'`, `'potato'`).
  final String id;

  /// English name of the crop.
  final String nameEn;

  /// Hindi vernacular name of the crop.
  final String nameHi;

  /// Path to the crop icon asset.
  final String iconAssetPath;

  const Crop({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.iconAssetPath,
  });

  /// Factory constructor to deserialize [Crop] from a JSON map.
  /// Supports both snake_case and camelCase field keys for flexibility.
  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      nameEn: (json['name_en'] ?? json['nameEn']) as String,
      nameHi: (json['name_hi'] ?? json['nameHi']) as String,
      iconAssetPath: (json['icon_asset_path'] ?? json['iconAssetPath']) as String,
    );
  }

  /// Serializes [Crop] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_hi': nameHi,
      'icon_asset_path': iconAssetPath,
    };
  }

  /// Creates a copy of this [Crop] with specified fields replaced.
  Crop copyWith({
    String? id,
    String? nameEn,
    String? nameHi,
    String? iconAssetPath,
  }) {
    return Crop(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      iconAssetPath: iconAssetPath ?? this.iconAssetPath,
    );
  }

  /// Returns localized crop name based on given language code (`'hi'` or `'en'`).
  String localizedName(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? nameHi : nameEn;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Crop &&
        other.id == id &&
        other.nameEn == nameEn &&
        other.nameHi == nameHi &&
        other.iconAssetPath == iconAssetPath;
  }

  @override
  int get hashCode => Object.hash(id, nameEn, nameHi, iconAssetPath);

  @override
  String toString() =>
      'Crop(id: $id, nameEn: $nameEn, nameHi: $nameHi, iconAssetPath: $iconAssetPath)';

  /// Pre-defined list of the 5 V1 launch crops.
  static const List<Crop> initialCrops = [
    Crop(
      id: 'tomato',
      nameEn: 'Tomato',
      nameHi: 'टमाटर',
      iconAssetPath: 'assets/icons/crops/tomato.png',
    ),
    Crop(
      id: 'potato',
      nameEn: 'Potato',
      nameHi: 'आलू',
      iconAssetPath: 'assets/icons/crops/potato.png',
    ),
    Crop(
      id: 'wheat',
      nameEn: 'Wheat',
      nameHi: 'गेहूं',
      iconAssetPath: 'assets/icons/crops/wheat.png',
    ),
    Crop(
      id: 'chili',
      nameEn: 'Chili',
      nameHi: 'मिर्च',
      iconAssetPath: 'assets/icons/crops/chili.png',
    ),
    Crop(
      id: 'cotton',
      nameEn: 'Cotton',
      nameHi: 'कपास',
      iconAssetPath: 'assets/icons/crops/cotton.png',
    ),
  ];

  /// Resolves a [Crop] by its identifier, defaulting to a basic [Crop] instance if unknown.
  static Crop fromId(String cropId) {
    final normalized = cropId.trim().toLowerCase();
    try {
      return initialCrops.firstWhere((c) => c.id.toLowerCase() == normalized);
    } catch (_) {
      final capitalized = cropId.isNotEmpty
          ? '${cropId[0].toUpperCase()}${cropId.substring(1)}'
          : cropId;
      return Crop(
        id: cropId,
        nameEn: capitalized,
        nameHi: capitalized,
        iconAssetPath: 'assets/icons/crops/$cropId.png',
      );
    }
  }
}
