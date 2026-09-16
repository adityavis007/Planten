import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    localStorage = LocalStorageService(prefs: prefs);
  });

  group('CropProvider (Task 31)', () {
    test('initializes with 5 V1 launch crops', () {
      final provider = CropProvider(localStorageService: localStorage);

      expect(provider.supportedCrops.length, 5);
      final cropIds = provider.supportedCrops.map((c) => c.id).toList();
      expect(cropIds, containsAll(['tomato', 'potato', 'wheat', 'chili', 'cotton']));
    });

    test('defaults selectedCrop to Tomato when storage is empty', () {
      final provider = CropProvider(localStorageService: localStorage);

      expect(provider.selectedCrop, isNotNull);
      expect(provider.selectedCrop!.id, 'tomato');
      expect(provider.selectedCropId, 'tomato');
      expect(provider.selectedCrop!.nameEn, 'Tomato');
      expect(provider.selectedCrop!.nameHi, 'टमाटर');
    });

    test('restores persisted crop from LocalStorageService on initialization', () async {
      await localStorage.saveSelectedCrop('wheat');

      final provider = CropProvider(localStorageService: localStorage);

      expect(provider.selectedCrop, isNotNull);
      expect(provider.selectedCrop!.id, 'wheat');
      expect(provider.selectedCropId, 'wheat');
      expect(provider.selectedCrop!.nameEn, 'Wheat');
      expect(provider.selectedCrop!.nameHi, 'गेहूं');
    });

    test('gracefully falls back to first crop if storage contains invalid crop ID', () async {
      await localStorage.saveSelectedCrop('invalid_crop_xyz');

      final provider = CropProvider(localStorageService: localStorage);

      expect(provider.selectedCrop, isNotNull);
      expect(provider.selectedCrop!.id, 'tomato');
    });

    test('selectCrop updates selectedCrop, notifies listeners, and persists ID', () async {
      final provider = CropProvider(localStorageService: localStorage);
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      final potato = provider.getCropById('potato');
      expect(potato, isNotNull);

      await provider.selectCrop(potato!);

      expect(provider.selectedCrop, potato);
      expect(provider.selectedCropId, 'potato');
      expect(notificationCount, 1);

      // Verify persisted to storage
      expect(localStorage.getSelectedCrop(), 'potato');
    });

    test('selectCrop does not re-notify or re-persist if the same crop is re-selected', () async {
      final provider = CropProvider(localStorageService: localStorage);
      final tomato = provider.selectedCrop!;

      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      await provider.selectCrop(tomato);

      expect(notificationCount, 0);
    });

    test('selectCropById selects correct crop and returns true for valid ID', () async {
      final provider = CropProvider(localStorageService: localStorage);

      final success = await provider.selectCropById('chili');

      expect(success, isTrue);
      expect(provider.selectedCropId, 'chili');
      expect(provider.selectedCrop!.nameEn, 'Chili');
      expect(localStorage.getSelectedCrop(), 'chili');
    });

    test('selectCropById returns false and preserves active crop for unknown ID', () async {
      final provider = CropProvider(localStorageService: localStorage);
      expect(provider.selectedCropId, 'tomato');

      final success = await provider.selectCropById('non_existent_crop');

      expect(success, isFalse);
      expect(provider.selectedCropId, 'tomato');
      expect(localStorage.getSelectedCrop(), isNull);
    });

    test('getCropById performs case-insensitive lookup', () {
      final provider = CropProvider(localStorageService: localStorage);

      final cotton = provider.getCropById('COTTON');
      expect(cotton, isNotNull);
      expect(cotton!.id, 'cotton');

      final missing = provider.getCropById('mango');
      expect(missing, isNull);
    });

    test('isSelected correctly reports whether a crop matches current selection', () async {
      final provider = CropProvider(localStorageService: localStorage);
      final tomato = provider.getCropById('tomato')!;
      final wheat = provider.getCropById('wheat')!;

      expect(provider.isSelected(tomato), isTrue);
      expect(provider.isSelected(wheat), isFalse);

      await provider.selectCrop(wheat);

      expect(provider.isSelected(tomato), isFalse);
      expect(provider.isSelected(wheat), isTrue);
    });

    test('crop selection survives simulated app restart', () async {
      // First session: user selects cotton
      final providerSession1 = CropProvider(localStorageService: localStorage);
      await providerSession1.selectCropById('cotton');
      expect(providerSession1.selectedCropId, 'cotton');

      // Second session: new provider instance with same storage
      final providerSession2 = CropProvider(localStorageService: localStorage);
      expect(providerSession2.selectedCropId, 'cotton');
      expect(providerSession2.selectedCrop!.nameEn, 'Cotton');
      expect(providerSession2.selectedCrop!.nameHi, 'कपास');
    });

    test('syncWithProfile updates active crop to farmer primary crop', () async {
      final provider = CropProvider(localStorageService: localStorage);
      expect(provider.selectedCropId, 'tomato');

      // Farmer profile has wheat and potato
      await provider.syncWithProfile(['wheat', 'potato']);
      expect(provider.selectedCropId, 'wheat');

      // If current crop is already in list, do not change
      await provider.syncWithProfile(['potato', 'wheat']);
      expect(provider.selectedCropId, 'wheat');
    });
  });
}
