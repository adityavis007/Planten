import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(prefs: prefs);
  });

  group('LocalStorageService (Task 15)', () {
    test('persists and retrieves selected crop ID', () async {
      expect(storageService.getSelectedCrop(), isNull);

      final success = await storageService.saveSelectedCrop('tomato');
      expect(success, isTrue);
      expect(storageService.getSelectedCrop(), 'tomato');

      await storageService.saveSelectedCrop('wheat');
      expect(storageService.getSelectedCrop(), 'wheat');
    });

    test('persists and retrieves farmer profile with 100% fidelity', () async {
      final now = DateTime.utc(2026, 9, 9, 12, 0, 0);
      final profile = FarmerProfile(
        uid: 'farmer-99',
        phoneNumber: '+919876543210',
        name: 'Kishore Kumar',
        village: 'Bilaspur',
        district: 'Rampur',
        state: 'Uttar Pradesh',
        primaryCrops: const ['wheat', 'potato'],
        photoBackupOptIn: false,
        createdAt: now,
      );

      expect(storageService.getUserProfile(), isNull);

      await storageService.saveUserProfile(profile);
      final loaded = storageService.getUserProfile();

      expect(loaded, equals(profile));
      expect(loaded?.name, 'Kishore Kumar');
      expect(loaded?.primaryCrops, ['wheat', 'potato']);
      expect(loaded?.photoBackupOptIn, isFalse);

      // Clear profile
      await storageService.clearUserProfile();
      expect(storageService.getUserProfile(), isNull);
    });

    test('persists and retrieves offline diagnosis scans ordered by date', () async {
      final scan1 = DiagnosisResult(
        id: 'scan-1',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        diseaseNameEn: 'Tomato Early Blight',
        diseaseNameHi: 'टमाटर का अगेती झुलसा',
        confidenceScore: 0.91,
        severity: SeverityLevel.medium,
        timestamp: DateTime.utc(2026, 9, 8, 10, 0, 0),
        localImagePath: '/path/leaf1.jpg',
      );

      final scan2 = DiagnosisResult(
        id: 'scan-2',
        cropId: 'wheat',
        diseaseId: 'wheat_healthy',
        diseaseNameEn: 'Healthy Wheat',
        diseaseNameHi: 'स्वस्थ गेहूं',
        confidenceScore: 0.99,
        severity: SeverityLevel.healthy,
        timestamp: DateTime.utc(2026, 9, 9, 12, 0, 0), // Newer
        localImagePath: '/path/leaf2.jpg',
      );

      expect(storageService.getOfflineScans(), isEmpty);

      await storageService.saveOfflineScans([scan1, scan2]);
      final loaded = storageService.getOfflineScans();

      expect(loaded.length, 2);
      // scan2 has newer timestamp, so should be sorted first
      expect(loaded.first.id, 'scan-2');
      expect(loaded.last.id, 'scan-1');
      expect(loaded.first.confidenceCategory, ConfidenceCategory.likely);
    });

    test('addOfflineScan appends new scan and updates existing scan', () async {
      final scan = DiagnosisResult(
        id: 'scan-test',
        cropId: 'tomato',
        diseaseId: 'tomato_late_blight',
        diseaseNameEn: 'Late Blight',
        diseaseNameHi: 'पछेती झुलसा',
        confidenceScore: 0.88,
        severity: SeverityLevel.high,
        timestamp: DateTime.utc(2026, 9, 9, 14, 0, 0),
        localImagePath: '/path/late.jpg',
        isSynced: false,
      );

      await storageService.addOfflineScan(scan);
      expect(storageService.getOfflineScans().length, 1);
      expect(storageService.getOfflineScans().first.isSynced, isFalse);

      // Update same scan with isSynced = true
      final updatedScan = scan.copyWith(isSynced: true);
      await storageService.addOfflineScan(updatedScan);

      final scans = storageService.getOfflineScans();
      expect(scans.length, 1);
      expect(scans.first.isSynced, isTrue);
    });

    test('deleteOfflineScan removes designated scan', () async {
      final scan = DiagnosisResult(
        id: 'to-delete',
        cropId: 'potato',
        diseaseId: 'potato_healthy',
        diseaseNameEn: 'Healthy',
        diseaseNameHi: 'स्वस्थ',
        confidenceScore: 0.95,
        severity: SeverityLevel.healthy,
        timestamp: DateTime.utc(2026, 9, 9, 15, 0, 0),
        localImagePath: '/path/potato.jpg',
      );

      await storageService.addOfflineScan(scan);
      expect(storageService.getOfflineScans().length, 1);

      await storageService.deleteOfflineScan('to-delete');
      expect(storageService.getOfflineScans(), isEmpty);
    });

    test('handles corrupted JSON in storage gracefully without crashing', () async {
      SharedPreferences.setMockInitialValues({
        'planten_user_profile_json': '{invalid json',
        'planten_offline_scans_json': 'not a list',
      });
      final prefs = await SharedPreferences.getInstance();
      final resilientService = LocalStorageService(prefs: prefs);

      expect(resilientService.getUserProfile(), isNull);
      expect(resilientService.getOfflineScans(), isEmpty);
    });

    test('clearAll wipes all Planten cached entries', () async {
      await storageService.saveSelectedCrop('chili');
      await storageService.saveUserProfile(
        FarmerProfile(
          uid: 'uid-1',
          phoneNumber: '+919999999999',
          name: 'Test',
          village: 'V',
          district: 'D',
          state: 'S',
          createdAt: DateTime.now(),
        ),
      );

      expect(storageService.getSelectedCrop(), 'chili');
      expect(storageService.getUserProfile(), isNotNull);

      await storageService.clearAll();

      expect(storageService.getSelectedCrop(), isNull);
      expect(storageService.getUserProfile(), isNull);
      expect(storageService.getOfflineScans(), isEmpty);
    });
  });
}
