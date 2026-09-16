import 'package:flutter/foundation.dart';
import '../models/crop.dart';
import '../services/local_storage_service.dart';

export '../models/crop.dart';

/// State management provider managing supported agricultural crops,
/// active crop selection, and persistence to [LocalStorageService].
class CropProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final List<Crop> _supportedCrops;

  Crop? _selectedCrop;

  CropProvider({
    LocalStorageService? localStorageService,
    List<Crop>? supportedCrops,
    Crop? initialCrop,
  })  : _localStorageService = localStorageService ?? LocalStorageService(),
        _supportedCrops = supportedCrops ?? List<Crop>.from(Crop.initialCrops) {
    if (initialCrop != null) {
      _selectedCrop = initialCrop;
    } else {
      loadPersistedCrop();
    }
  }

  /// List of supported crops for disease diagnosis.
  List<Crop> get supportedCrops => List.unmodifiable(_supportedCrops);

  /// Currently active crop for scanning and disease management.
  Crop? get selectedCrop => _selectedCrop;

  /// Unique identifier of the currently active crop (e.g. `'tomato'`), or null.
  String? get selectedCropId => _selectedCrop?.id;

  /// Loads the persisted crop preference from local storage.
  /// Defaults to the first crop in [_supportedCrops] (Tomato) if no valid preference is saved.
  void loadPersistedCrop() {
    final persistedId = _localStorageService.getSelectedCrop();
    if (persistedId != null && persistedId.trim().isNotEmpty) {
      final match = getCropById(persistedId);
      if (match != null) {
        _selectedCrop = match;
        notifyListeners();
        return;
      }
    }

    // Default to first supported crop (Tomato)
    if (_supportedCrops.isNotEmpty) {
      _selectedCrop = _supportedCrops.first;
    }
    notifyListeners();
  }

  /// Syncs active crop preference with the farmer's primary crop list.
  /// Selects the first crop from [primaryCrops] if current crop is not among them.
  Future<void> syncWithProfile(List<String> primaryCrops) async {
    if (primaryCrops.isEmpty) return;
    if (_selectedCrop == null || !primaryCrops.contains(_selectedCrop!.id)) {
      await selectCropById(primaryCrops.first);
    }
  }

  /// Sets the active crop and asynchronously persists the selection to [LocalStorageService].
  Future<void> selectCrop(Crop crop) async {
    if (_selectedCrop == crop) return;

    _selectedCrop = crop;
    notifyListeners();

    await _localStorageService.saveSelectedCrop(crop.id);
  }

  /// Finds and selects a crop by its unique ID (e.g. `'wheat'`).
  Future<bool> selectCropById(String cropId) async {
    final crop = getCropById(cropId);
    if (crop != null) {
      await selectCrop(crop);
      return true;
    }
    return false;
  }

  /// Returns the [Crop] matching [cropId], or null if not found.
  Crop? getCropById(String cropId) {
    final normalized = cropId.trim().toLowerCase();
    try {
      return _supportedCrops.firstWhere(
        (c) => c.id.toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks whether the specified [crop] is the currently active crop.
  bool isSelected(Crop crop) => _selectedCrop?.id == crop.id;
}
