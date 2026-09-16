import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/services/firestore_sync_service.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/knowledge_base_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/network_monitor_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Fake Connectivity for deterministic testing
class FakeConnectivity implements Connectivity {
  List<ConnectivityResult> currentResults;

  FakeConnectivity(this.currentResults);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(currentResults);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreSyncService (Task 50) Unit Tests', () {
    late LocalStorageService localStorage;
    late HistoryService historyService;
    late List<Map<String, dynamic>> writtenBatches;

    final sampleScan1 = DiagnosisResult(
      id: 'scan-001',
      cropId: 'tomato',
      diseaseId: 'tomato_early_blight',
      diseaseNameEn: 'Early Blight',
      diseaseNameHi: 'अगेती झुलसा',
      confidenceScore: 0.92,
      severity: SeverityLevel.medium,
      timestamp: DateTime.utc(2026, 9, 9, 10, 0, 0),
      localImagePath:
          '/data/user/0/com.planten/app_flutter/scans/thumb_001.jpg',
      remoteImageUrl: 'https://storage.googleapis.com/planten/001.jpg',
      isSynced: false,
    );

    final sampleScan2 = DiagnosisResult(
      id: 'scan-002',
      cropId: 'wheat',
      diseaseId: 'wheat_rust',
      diseaseNameEn: 'Stripe Rust',
      diseaseNameHi: 'पीला रतुआ',
      confidenceScore: 0.88,
      severity: SeverityLevel.high,
      timestamp: DateTime.utc(2026, 9, 9, 11, 0, 0),
      localImagePath:
          '/data/user/0/com.planten/app_flutter/scans/thumb_002.jpg',
      isSynced: false,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      localStorage = LocalStorageService(prefs: prefs);
      historyService = HistoryService(localStorageService: localStorage);
      writtenBatches = [];
    });

    test(
      'returns SyncStatus.offline when network monitor indicates offline',
      () async {
        final offlineConnectivity = FakeConnectivity([ConnectivityResult.none]);
        final networkMonitor = NetworkMonitorService(
          connectivity: offlineConnectivity,
        );
        await networkMonitor.initialize();

        final syncService = FirestoreSyncService(
          historyService: historyService,
          networkMonitorService: networkMonitor,
          localStorageService: localStorage,
          batchWriter: (records) async => writtenBatches.addAll(records),
        );

        final result = await syncService.syncPendingScans();

        expect(result.status, SyncStatus.offline);
        expect(result.errorMessage, contains('offline'));
        expect(writtenBatches, isEmpty);
      },
    );

    test('returns SyncStatus.unavailable when Firestore is null and no batch writer provided', () async {
      final onlineConnectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(
        connectivity: onlineConnectivity,
      );
      await networkMonitor.initialize();

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        firestore: null,
        batchWriter: null,
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.unavailable);
      expect(result.errorMessage, contains('Firestore is not available'));
    });

    test('returns SyncStatus.noPending when no unsynced scans exist', () async {
      final onlineConnectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(
        connectivity: onlineConnectivity,
      );
      await networkMonitor.initialize();

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async => writtenBatches.addAll(records),
      );

      // Save a scan that is already marked as synced
      await historyService.saveScan(sampleScan1.copyWith(isSynced: true));

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.noPending);
      expect(result.totalPending, 0);
      expect(result.syncedCount, 0);
      expect(writtenBatches, isEmpty);
    });

    test(
      'successfully writes metadata batch and marks local records as synced',
      () async {
        final onlineConnectivity = FakeConnectivity([ConnectivityResult.wifi]);
        final networkMonitor = NetworkMonitorService(
          connectivity: onlineConnectivity,
        );
        await networkMonitor.initialize();

        // Set user profile in local storage
        await localStorage.saveUserProfile(
          FarmerProfile(
            uid: 'farmer-999',
            phoneNumber: '+919876543210',
            name: 'Ramesh',
            village: 'Kheda',
            district: 'Anand',
            state: 'Gujarat',
            photoBackupOptIn: false, // Privacy: photo backup OFF
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

        // Save two unsynced scans
        await historyService.saveScan(sampleScan1);
        await historyService.saveScan(sampleScan2);

        final unsyncedBefore = await historyService.getUnsyncedScans();
        expect(unsyncedBefore.length, 2);

        final syncService = FirestoreSyncService(
          historyService: historyService,
          networkMonitorService: networkMonitor,
          localStorageService: localStorage,
          batchWriter: (records) async {
            writtenBatches.addAll(records);
          },
        );

        final result = await syncService.syncPendingScans();

        expect(result.status, SyncStatus.success);
        expect(result.totalPending, 2);
        expect(result.syncedCount, 2);
        expect(writtenBatches.length, 2);

        // Verify metadata payload structure
        final firstRecord = writtenBatches.firstWhere(
          (r) => r['id'] == 'scan-001',
        );
        expect(firstRecord['userId'], 'farmer-999');
        expect(firstRecord['cropId'], 'tomato');
        expect(firstRecord['diseaseId'], 'tomato_early_blight');
        expect(firstRecord['confidenceScore'], 0.92);
        expect(firstRecord['severity'], 'medium');
        expect(firstRecord['timestamp'], '2026-09-09T10:00:00.000Z');
        expect(firstRecord['isSynced'], isTrue);
        // Privacy guardrail: remoteImageUrl must be null when photoBackupOptIn is false
        expect(firstRecord['remoteImageUrl'], isNull);

        // Verify local storage isSynced flags updated
        final unsyncedAfter = await historyService.getUnsyncedScans();
        expect(unsyncedAfter, isEmpty);

        final allScans = await historyService.getAllScans();
        expect(allScans.every((s) => s.isSynced), isTrue);
      },
    );

    test('retains remoteImageUrl when photoBackupOptIn is true', () async {
      final onlineConnectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(
        connectivity: onlineConnectivity,
      );
      await networkMonitor.initialize();

      // Profile with photoBackupOptIn == true
      await localStorage.saveUserProfile(
        FarmerProfile(
          uid: 'farmer-backup',
          phoneNumber: '+919876543210',
          name: 'Suresh',
          village: 'Vasad',
          district: 'Anand',
          state: 'Gujarat',
          photoBackupOptIn: true,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await historyService.saveScan(sampleScan1);

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async => writtenBatches.addAll(records),
      );

      final result = await syncService.syncPendingScans();
      expect(result.status, SyncStatus.success);

      final record = writtenBatches.first;
      expect(
        record['remoteImageUrl'],
        'https://storage.googleapis.com/planten/001.jpg',
      );
    });

    test('handles batch write failures gracefully and preserves unsynced local records', () async {
      final onlineConnectivity = FakeConnectivity([ConnectivityResult.mobile]);
      final networkMonitor = NetworkMonitorService(
        connectivity: onlineConnectivity,
      );
      await networkMonitor.initialize();

      await historyService.saveScan(sampleScan1);

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async {
          throw Exception('Firestore quota exceeded / network drop');
        },
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.error);
      expect(result.syncedCount, 0);
      expect(result.errorMessage, contains('Firestore quota exceeded'));

      // Ensure local scan was NOT marked as synced
      final unsynced = await historyService.getUnsyncedScans();
      expect(unsynced.length, 1);
      expect(unsynced.first.isSynced, isFalse);
    });

    test('chunks large batches respecting maxBatchSize limit (500)', () async {
      final onlineConnectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(
        connectivity: onlineConnectivity,
      );
      await networkMonitor.initialize();

      // Generate 505 test scans
      final manyScans = List.generate(
        505,
        (i) => DiagnosisResult(
          id: 'bulk-scan-$i',
          cropId: 'potato',
          diseaseId: 'potato_blight',
          diseaseNameEn: 'Potato Blight',
          diseaseNameHi: 'आलू झुलसा',
          confidenceScore: 0.85,
          severity: SeverityLevel.high,
          timestamp: DateTime.utc(2026, 9, 9, 12, 0, i),
          localImagePath: '/dummy/path/$i.jpg',
          isSynced: false,
        ),
      );

      await localStorage.saveOfflineScans(manyScans);

      final batchSizes = <int>[];
      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async {
          batchSizes.add(records.length);
        },
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.success);
      expect(result.totalPending, 505);
      expect(result.syncedCount, 505);
      expect(batchSizes, [500, 5]);

      final remainingUnsynced = await historyService.getUnsyncedScans();
      expect(remainingUnsynced, isEmpty);
    });

    test(
      'registers and unregisters autoSync callback with NetworkMonitorService',
      () {
        final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
        final networkMonitor = NetworkMonitorService(
          connectivity: connectivity,
        );

        final syncService = FirestoreSyncService(
          historyService: historyService,
          networkMonitorService: networkMonitor,
          localStorageService: localStorage,
          batchWriter: (records) async {},
        );

        expect(syncService.isAutoSyncActive, isFalse);

        syncService.startAutoSync();
        expect(syncService.isAutoSyncActive, isTrue);

        syncService.stopAutoSync();
        expect(syncService.isAutoSyncActive, isFalse);

        syncService.dispose();
        expect(syncService.isAutoSyncActive, isFalse);
      },
    );

    test(
      'prevents overlapping parallel sync executions using isSyncing lock',
      () async {
        final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
        final networkMonitor = NetworkMonitorService(
          connectivity: connectivity,
        );
        await networkMonitor.initialize();

        await historyService.saveScan(sampleScan1);

        final completer = Completer<void>();
        final syncService = FirestoreSyncService(
          historyService: historyService,
          networkMonitorService: networkMonitor,
          localStorageService: localStorage,
          batchWriter: (records) async {
            await completer.future;
          },
        );

        final future1 = syncService.syncPendingScans();
        await Future<void>.delayed(Duration.zero);
        expect(syncService.isSyncing, isTrue);

        // Attempt second sync while first is in progress
        final result2 = await syncService.syncPendingScans();
        expect(result2.status, SyncStatus.noPending);
        expect(result2.errorMessage, contains('Sync already in progress'));

        // Release first sync
        completer.complete();
        final result1 = await future1;
        expect(result1.status, SyncStatus.success);
        expect(syncService.isSyncing, isFalse);
      },
    );
  });

  group('FirestoreSyncService (Task 51) Photo Backup Unit Tests', () {
    late LocalStorageService localStorage;
    late HistoryService historyService;
    late Directory tempDir;
    late File testImageFile;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      tempDir = Directory.systemTemp.createTempSync('planten_photo_test_');
      testImageFile = File('${tempDir.path}/test_leaf.jpg');

      localStorage = LocalStorageService(prefs: prefs);
      historyService = HistoryService(
        localStorageService: localStorage,
        documentsDirectoryProvider: () async => tempDir,
      );

      // Create a test image
      final testImg = img.Image(width: 800, height: 600);
      for (var y = 0; y < 600; y++) {
        for (var x = 0; x < 800; x++) {
          testImg.setPixelRgb(x, y, (x % 255), (y % 255), 100);
        }
      }
      final jpgBytes = img.encodeJpg(testImg, quality: 90);
      await testImageFile.writeAsBytes(jpgBytes);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('strictly skips photo upload when photoBackupOptIn is false', () async {
      final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(connectivity: connectivity);
      await networkMonitor.initialize();

      await localStorage.saveUserProfile(
        FarmerProfile(
          uid: 'farmer-optout',
          phoneNumber: '+919876543210',
          name: 'Gopal',
          village: 'Kheda',
          district: 'Anand',
          state: 'Gujarat',
          photoBackupOptIn: false, // Opt-out
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final scan = DiagnosisResult(
        id: 'scan-no-upload',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        diseaseNameEn: 'Early Blight',
        diseaseNameHi: 'अगेती झुलसा',
        confidenceScore: 0.94,
        severity: SeverityLevel.medium,
        timestamp: DateTime.utc(2026, 9, 9, 14, 0),
        localImagePath: testImageFile.path,
        isSynced: false,
      );
      await historyService.saveScan(scan);

      bool photoUploaderInvoked = false;
      final writtenBatches = <Map<String, dynamic>>[];

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async => writtenBatches.addAll(records),
        photoUploader:
            ({required userId, required scanId, required imageFile}) async {
              photoUploaderInvoked = true;
              return 'https://firebasestorage.googleapis.com/test.jpg';
            },
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.success);
      expect(
        photoUploaderInvoked,
        isFalse,
        reason:
            'Photo uploader must NOT be called when photoBackupOptIn is false',
      );
      expect(writtenBatches.first['remoteImageUrl'], isNull);

      final updatedScan = await historyService.getScanById('scan-no-upload');
      expect(updatedScan?.remoteImageUrl, isNull);
      expect(updatedScan?.isSynced, isTrue);
    });

    test('uploads photo and populates remoteImageUrl when photoBackupOptIn is true', () async {
      final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(connectivity: connectivity);
      await networkMonitor.initialize();

      await localStorage.saveUserProfile(
        FarmerProfile(
          uid: 'farmer-optin',
          phoneNumber: '+919876543210',
          name: 'Mahesh',
          village: 'Borsad',
          district: 'Anand',
          state: 'Gujarat',
          photoBackupOptIn: true, // Opt-in
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final scan = DiagnosisResult(
        id: 'scan-with-upload',
        cropId: 'potato',
        diseaseId: 'potato_late_blight',
        diseaseNameEn: 'Late Blight',
        diseaseNameHi: 'पछेती झुलसा',
        confidenceScore: 0.89,
        severity: SeverityLevel.high,
        timestamp: DateTime.utc(2026, 9, 9, 14, 30),
        localImagePath: testImageFile.path,
        isSynced: false,
      );
      await historyService.saveScan(scan);

      String? capturedUserId;
      String? capturedScanId;
      File? capturedFile;
      final writtenBatches = <Map<String, dynamic>>[];

      final expectedDownloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/planten/o/users%2Ffarmer-optin%2Fscans%2Fscan-with-upload.jpg';

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async => writtenBatches.addAll(records),
        photoUploader:
            ({required userId, required scanId, required imageFile}) async {
              capturedUserId = userId;
              capturedScanId = scanId;
              capturedFile = imageFile;
              return expectedDownloadUrl;
            },
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.success);
      expect(capturedUserId, 'farmer-optin');
      expect(capturedScanId, 'scan-with-upload');
      expect(capturedFile?.existsSync(), isTrue);
      expect(capturedFile?.path, contains('scan-with-upload'));

      expect(writtenBatches.first['remoteImageUrl'], expectedDownloadUrl);

      final updatedScan = await historyService.getScanById('scan-with-upload');
      expect(updatedScan?.remoteImageUrl, expectedDownloadUrl);
      expect(updatedScan?.isSynced, isTrue);
    });

    test('reuses existing remoteImageUrl and skips re-uploading', () async {
      final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(connectivity: connectivity);
      await networkMonitor.initialize();

      await localStorage.saveUserProfile(
        FarmerProfile(
          uid: 'farmer-optin',
          phoneNumber: '+919876543210',
          name: 'Mahesh',
          village: 'Borsad',
          district: 'Anand',
          state: 'Gujarat',
          photoBackupOptIn: true,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      const existingUrl = 'https://firebasestorage.googleapis.com/existing.jpg';
      final scan = DiagnosisResult(
        id: 'scan-already-uploaded',
        cropId: 'wheat',
        diseaseId: 'wheat_leaf_rust',
        diseaseNameEn: 'Leaf Rust',
        diseaseNameHi: 'भूरा रतुआ',
        confidenceScore: 0.91,
        severity: SeverityLevel.medium,
        timestamp: DateTime.utc(2026, 9, 9, 15, 0),
        localImagePath: testImageFile.path,
        remoteImageUrl: existingUrl,
        isSynced: false,
      );
      await historyService.saveScan(scan);

      bool photoUploaderInvoked = false;
      final writtenBatches = <Map<String, dynamic>>[];

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async => writtenBatches.addAll(records),
        photoUploader:
            ({required userId, required scanId, required imageFile}) async {
              photoUploaderInvoked = true;
              return 'https://new.url.jpg';
            },
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.success);
      expect(
        photoUploaderInvoked,
        isFalse,
        reason: 'Should not re-upload if remoteImageUrl is already present',
      );
      expect(writtenBatches.first['remoteImageUrl'], existingUrl);
    });

    test('handles missing local image file gracefully without failing metadata sync', () async {
      final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
      final networkMonitor = NetworkMonitorService(connectivity: connectivity);
      await networkMonitor.initialize();

      await localStorage.saveUserProfile(
        FarmerProfile(
          uid: 'farmer-optin',
          phoneNumber: '+919876543210',
          name: 'Mahesh',
          village: 'Borsad',
          district: 'Anand',
          state: 'Gujarat',
          photoBackupOptIn: true,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final scan = DiagnosisResult(
        id: 'scan-missing-image-file',
        cropId: 'cotton',
        diseaseId: 'cotton_bacterial_blight',
        diseaseNameEn: 'Bacterial Blight',
        diseaseNameHi: 'जीवाणु झुलसा',
        confidenceScore: 0.88,
        severity: SeverityLevel.high,
        timestamp: DateTime.utc(2026, 9, 9, 15, 30),
        localImagePath: '${tempDir.path}/does_not_exist.jpg',
        isSynced: false,
      );
      await historyService.saveScan(scan);

      final writtenBatches = <Map<String, dynamic>>[];
      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitor,
        localStorageService: localStorage,
        batchWriter: (records) async => writtenBatches.addAll(records),
        photoUploader: ({
          required userId,
          required scanId,
          required imageFile,
        }) async => 'https://storage.url',
      );

      final result = await syncService.syncPendingScans();

      expect(result.status, SyncStatus.success);
      expect(writtenBatches.first['remoteImageUrl'], isNull);

      final updatedScan = await historyService.getScanById(
        'scan-missing-image-file',
      );
      expect(updatedScan?.isSynced, isTrue);
    });

    test(
      'proceeds with metadata sync if photo upload throws an exception',
      () async {
        final connectivity = FakeConnectivity([ConnectivityResult.wifi]);
        final networkMonitor = NetworkMonitorService(
          connectivity: connectivity,
        );
        await networkMonitor.initialize();

        await localStorage.saveUserProfile(
          FarmerProfile(
            uid: 'farmer-optin',
            phoneNumber: '+919876543210',
            name: 'Mahesh',
            village: 'Borsad',
            district: 'Anand',
            state: 'Gujarat',
            photoBackupOptIn: true,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

        final scan = DiagnosisResult(
          id: 'scan-photo-fail',
          cropId: 'chili',
          diseaseId: 'chili_leaf_curl',
          diseaseNameEn: 'Leaf Curl',
          diseaseNameHi: 'पत्ती मरोड़',
          confidenceScore: 0.90,
          severity: SeverityLevel.medium,
          timestamp: DateTime.utc(2026, 9, 9, 16, 0),
          localImagePath: testImageFile.path,
          isSynced: false,
        );
        await historyService.saveScan(scan);

        final writtenBatches = <Map<String, dynamic>>[];
        final syncService = FirestoreSyncService(
          historyService: historyService,
          networkMonitorService: networkMonitor,
          localStorageService: localStorage,
          batchWriter: (records) async => writtenBatches.addAll(records),
          photoUploader:
              ({required userId, required scanId, required imageFile}) async {
                throw Exception(
                  'Firebase Storage: quota exceeded or network drop',
                );
              },
        );

        final result = await syncService.syncPendingScans();

        // Metadata sync succeeds even though photo upload failed
        expect(result.status, SyncStatus.success);
        expect(writtenBatches.first['remoteImageUrl'], isNull);

        final updatedScan = await historyService.getScanById('scan-photo-fail');
        expect(updatedScan?.isSynced, isTrue);
      },
    );

    test(
      'compressImageForBackup compresses oversized image strictly under 200KB',
      () async {
        final syncService = FirestoreSyncService(
          historyService: historyService,
          localStorageService: localStorage,
        );

        // Create a large 1200x1200 image
        final largeImg = img.Image(width: 1200, height: 1200);
        for (var y = 0; y < 1200; y++) {
          for (var x = 0; x < 1200; x++) {
            largeImg.setPixelRgb(
              x,
              y,
              (x * 7) % 255,
              (y * 11) % 255,
              (x + y) % 255,
            );
          }
        }
        final largeJpgBytes = img.encodeJpg(largeImg, quality: 100);
        final largeImageFile = File('${tempDir.path}/large_leaf.jpg');
        await largeImageFile.writeAsBytes(largeJpgBytes);

        expect(largeImageFile.lengthSync(), greaterThan(200 * 1024));

        final compressedBytes = await syncService.compressImageForBackup(
          largeImageFile,
        );

        expect(compressedBytes, isNotNull);
        expect(compressedBytes!.lengthInBytes, lessThanOrEqualTo(200 * 1024));
      },
    );

    test('fetchUserScans downloads remote records, rehydrates guidance, and merges into history', () async {
      final remoteRecords = [
        {
          'id': 'remote-scan-1',
          'userId': 'farmer-101',
          'cropId': 'tomato',
          'diseaseId': 'tomato_early_blight',
          'diseaseNameEn': 'Early Blight',
          'diseaseNameHi': 'अगेती झुलसा',
          'confidenceScore': 0.92,
          'severity': 'medium',
          'timestamp': DateTime.now().toIso8601String(),
          'remoteImageUrl': 'https://firebasestorage.googleapis.com/leaf.jpg',
          'isSynced': true,
        },
      ];

      const sampleGuidance = TreatmentGuidance(
        diseaseId: 'tomato_early_blight',
        crop: 'tomato',
        nameEn: 'Early Blight',
        nameHi: 'अगेती झुलसा',
        symptomsEn: 'Brown spots with concentric rings',
        symptomsHi: 'संकेंद्रित छल्लों वाले भूरे धब्बे',
        culturalStepsEn: ['Remove infected lower leaves'],
        culturalStepsHi: ['संक्रमित निचली पत्तियों को हटा दें'],
        managementCategory: 'fungal',
        severityLevel: 'medium',
        disclaimerEn: 'Advisory only',
        disclaimerHi: 'केवल सलाहकारी',
      );

      final syncService = FirestoreSyncService(
        historyService: historyService,
        localStorageService: localStorage,
        knowledgeBaseService: KnowledgeBaseService(
          initialGuidance: [sampleGuidance],
        ),
        scanFetcher: (userId) async {
          expect(userId, 'farmer-101');
          return remoteRecords;
        },
      );

      final scans = await syncService.fetchUserScans('farmer-101');

      expect(scans.length, 1);
      expect(scans.first.id, 'remote-scan-1');
      expect(scans.first.cropId, 'tomato');
      expect(scans.first.guidance, isNotNull);
      expect(
        scans.first.remoteImageUrl,
        'https://firebasestorage.googleapis.com/leaf.jpg',
      );

      // Verify merged into local history
      final localScans = await historyService.getAllScans();
      expect(localScans.length, 1);
      expect(localScans.first.id, 'remote-scan-1');
    });

    test(
      'deleteScanFromCloud calls scanDeleter and returns true on success',
      () async {
        String? deletedScanId;

        final syncService = FirestoreSyncService(
          historyService: historyService,
          localStorageService: localStorage,
          scanDeleter: (scanId) async {
            deletedScanId = scanId;
          },
        );

        final success = await syncService.deleteScanFromCloud(
          scanId: 'scan-to-delete',
          userId: 'farmer-99',
        );

        expect(success, isTrue);
        expect(deletedScanId, 'scan-to-delete');
      },
    );

    test(
      'deleteScanFromCloud returns false gracefully if scanDeleter throws',
      () async {
        final syncService = FirestoreSyncService(
          historyService: historyService,
          localStorageService: localStorage,
          scanDeleter: (scanId) async {
            throw Exception('Firestore network failure');
          },
        );

        final success = await syncService.deleteScanFromCloud(
          scanId: 'scan-fail',
          userId: 'farmer-99',
        );

        expect(success, isFalse);
      },
    );

    test('clearAllUserScansFromCloud calls allScansDeleter and returns true on success', () async {
      String? clearedUserId;

      final syncService = FirestoreSyncService(
        historyService: historyService,
        localStorageService: localStorage,
        allScansDeleter: (userId) async {
          clearedUserId = userId;
        },
      );

      final success = await syncService.clearAllUserScansFromCloud('farmer-99');

      expect(success, isTrue);
      expect(clearedUserId, 'farmer-99');
    });

    test('clearAllUserScansFromCloud returns false gracefully if allScansDeleter throws', () async {
      final syncService = FirestoreSyncService(
        historyService: historyService,
        localStorageService: localStorage,
        allScansDeleter: (userId) async {
          throw Exception('Firestore permission denied');
        },
      );

      final success = await syncService.clearAllUserScansFromCloud('farmer-99');

      expect(success, isFalse);
    });
  });
}
