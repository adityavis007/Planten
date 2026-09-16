import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docsDir;
  late LocalStorageService localStorageService;
  late HistoryService historyService;

  /// Helper to create a test image file on disk.
  Future<File> createTestImageFile(String filename, {int width = 800, int height = 600}) async {
    final image = img.Image(width: width, height: height);
    // Draw simple pattern
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        image.setPixelRgba(x, y, (x % 255), (y % 255), 100, 255);
      }
    }
    final bytes = img.encodeJpg(image, quality: 90);
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorageService = LocalStorageService(prefs: prefs);

    tempDir = await Directory.systemTemp.createTemp('planten_history_test_');
    docsDir = Directory('${tempDir.path}/app_docs');
    await docsDir.create(recursive: true);

    historyService = HistoryService(
      localStorageService: localStorageService,
      documentsDirectoryProvider: () async => docsDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DiagnosisResult buildSampleScan({
    required String id,
    String cropId = 'tomato',
    String diseaseId = 'tomato_early_blight',
    String diseaseNameEn = 'Tomato Early Blight',
    String diseaseNameHi = 'टमाटर का अगेती झुलसा',
    double confidenceScore = 0.92,
    SeverityLevel severity = SeverityLevel.medium,
    DateTime? timestamp,
    String localImagePath = '',
    bool isSynced = false,
  }) {
    return DiagnosisResult(
      id: id,
      cropId: cropId,
      diseaseId: diseaseId,
      diseaseNameEn: diseaseNameEn,
      diseaseNameHi: diseaseNameHi,
      confidenceScore: confidenceScore,
      severity: severity,
      timestamp: timestamp ?? DateTime.now(),
      localImagePath: localImagePath,
      isSynced: isSynced,
      guidance: const TreatmentGuidance(
        diseaseId: 'tomato_early_blight',
        crop: 'tomato',
        nameEn: 'Tomato Early Blight',
        nameHi: 'टमाटर का अगेती झुलसा',
        symptomsEn: 'Dark concentric spots.',
        symptomsHi: 'काले छल्लेदार धब्बे।',
        culturalStepsEn: ['Prune lower leaves.'],
        culturalStepsHi: ['निचली पत्तियों को हटाएं।'],
        managementCategory: 'cultural',
        severityLevel: 'medium',
        disclaimerEn: 'Advisory only.',
        disclaimerHi: 'केवल सलाह हेतु।',
      ),
    );
  }

  group('HistoryService (Task 46) Offline-First Storage Tests', () {
    test('saveScan stores metadata and creates compressed JPEG thumbnail in app doc directory', () async {
      final sampleFile = await createTestImageFile('full_leaf.jpg', width: 1024, height: 768);

      final scan = buildSampleScan(
        id: 'scan-001',
        localImagePath: sampleFile.path,
      );

      await historyService.saveScan(scan);

      final allScans = await historyService.getAllScans();
      expect(allScans.length, 1);

      final saved = allScans.first;
      expect(saved.id, 'scan-001');
      expect(saved.cropId, 'tomato');
      expect(saved.diseaseNameEn, 'Tomato Early Blight');
      expect(saved.confidenceScore, 0.92);
      expect(saved.confidenceCategory, ConfidenceCategory.likely);
      expect(saved.isSynced, isFalse);

      // Verify thumbnail path points to app documents directory
      expect(saved.localImagePath, contains('thumb_scan-001.jpg'));
      final thumbFile = File(saved.localImagePath);
      expect(await thumbFile.exists(), isTrue);

      // Verify thumbnail image was compressed down to <= 320 max dimension
      final thumbBytes = await thumbFile.readAsBytes();
      final decodedThumb = img.decodeImage(thumbBytes);
      expect(decodedThumb, isNotNull);
      expect(decodedThumb!.width <= 320, isTrue);
      expect(decodedThumb.height <= 320, isTrue);
    });

    test('saveScan handles missing image file gracefully without throwing', () async {
      final scan = buildSampleScan(
        id: 'scan-missing-file',
        localImagePath: '${tempDir.path}/non_existent_leaf.jpg',
      );

      await historyService.saveScan(scan);

      final scans = await historyService.getAllScans();
      expect(scans.length, 1);
      expect(scans.first.id, 'scan-missing-file');
      expect(scans.first.localImagePath, scan.localImagePath);
    });

    test('getAllScans orders scans by timestamp descending (newest first)', () async {
      final now = DateTime.now();

      final scanOld = buildSampleScan(
        id: 'scan-old',
        timestamp: now.subtract(const Duration(days: 3)),
      );
      final scanMid = buildSampleScan(
        id: 'scan-mid',
        timestamp: now.subtract(const Duration(days: 1)),
      );
      final scanNew = buildSampleScan(
        id: 'scan-new',
        timestamp: now,
      );

      // Save in arbitrary order
      await historyService.saveScan(scanMid);
      await historyService.saveScan(scanOld);
      await historyService.saveScan(scanNew);

      final all = await historyService.getAllScans();
      expect(all.length, 3);
      expect(all[0].id, 'scan-new');
      expect(all[1].id, 'scan-mid');
      expect(all[2].id, 'scan-old');
    });

    test('getScansByCrop filters scans by cropId accurately and case-insensitively', () async {
      final now = DateTime.now();

      final tomatoScan1 = buildSampleScan(
        id: 'tomato-1',
        cropId: 'tomato',
        timestamp: now.subtract(const Duration(hours: 2)),
      );
      final tomatoScan2 = buildSampleScan(
        id: 'tomato-2',
        cropId: 'Tomato',
        timestamp: now,
      );
      final wheatScan = buildSampleScan(
        id: 'wheat-1',
        cropId: 'wheat',
        diseaseId: 'wheat_yellow_rust',
        diseaseNameEn: 'Wheat Yellow Rust',
      );

      await historyService.saveScan(tomatoScan1);
      await historyService.saveScan(wheatScan);
      await historyService.saveScan(tomatoScan2);

      // Query Tomato
      final tomatoScans = await historyService.getScansByCrop('tomato');
      expect(tomatoScans.length, 2);
      expect(tomatoScans[0].id, 'tomato-2'); // newest first
      expect(tomatoScans[1].id, 'tomato-1');

      // Query Wheat case-insensitively
      final wheatScans = await historyService.getScansByCrop('WHEAT');
      expect(wheatScans.length, 1);
      expect(wheatScans.first.id, 'wheat-1');

      // Query non-existent crop
      final emptyScans = await historyService.getScansByCrop('rice');
      expect(emptyScans, isEmpty);
    });

    test('getScanById returns matching scan or null if not found', () async {
      final scan = buildSampleScan(id: 'target-scan');
      await historyService.saveScan(scan);

      final found = await historyService.getScanById('target-scan');
      expect(found, isNotNull);
      expect(found?.id, 'target-scan');

      final notFound = await historyService.getScanById('unknown-id');
      expect(notFound, isNull);
    });

    test('deleteScan removes entry from local storage and deletes thumbnail file', () async {
      final sampleFile = await createTestImageFile('delete_me.jpg');
      final scan = buildSampleScan(
        id: 'scan-to-delete',
        localImagePath: sampleFile.path,
      );

      await historyService.saveScan(scan);
      final saved = await historyService.getScanById('scan-to-delete');
      expect(saved, isNotNull);

      final thumbFile = File(saved!.localImagePath);
      expect(await thumbFile.exists(), isTrue);

      // Perform deletion
      final deleted = await historyService.deleteScan('scan-to-delete');
      expect(deleted, isTrue);

      // Verify removed from metadata
      final afterDelete = await historyService.getAllScans();
      expect(afterDelete, isEmpty);

      // Verify thumbnail file cleaned up from disk
      expect(await thumbFile.exists(), isFalse);
    });

    test('markAsSynced updates sync flag and attaches remoteImageUrl', () async {
      final scan = buildSampleScan(id: 'sync-scan', isSynced: false);
      await historyService.saveScan(scan);

      final initial = await historyService.getScanById('sync-scan');
      expect(initial?.isSynced, isFalse);
      expect(initial?.remoteImageUrl, isNull);

      await historyService.markAsSynced(
        'sync-scan',
        remoteImageUrl: 'https://storage.googleapis.com/planten/scans/sync-scan.jpg',
      );

      final updated = await historyService.getScanById('sync-scan');
      expect(updated?.isSynced, isTrue);
      expect(
        updated?.remoteImageUrl,
        'https://storage.googleapis.com/planten/scans/sync-scan.jpg',
      );
    });

    test('getUnsyncedScans returns only scans with isSynced == false', () async {
      final scan1 = buildSampleScan(id: 'scan-unsynced-1', isSynced: false);
      final scan2 = buildSampleScan(id: 'scan-synced-2', isSynced: true);
      final scan3 = buildSampleScan(id: 'scan-unsynced-3', isSynced: false);

      await historyService.saveScan(scan1);
      await historyService.saveScan(scan2);
      await historyService.saveScan(scan3);

      final unsynced = await historyService.getUnsyncedScans();
      expect(unsynced.length, 2);
      expect(unsynced.map((s) => s.id), containsAll(['scan-unsynced-1', 'scan-unsynced-3']));
      expect(unsynced.map((s) => s.id), isNot(contains('scan-synced-2')));
    });

    test('clearAllScans deletes all records and removes thumbnail directory', () async {
      final file1 = await createTestImageFile('scan1.jpg');
      final file2 = await createTestImageFile('scan2.jpg');

      await historyService.saveScan(buildSampleScan(id: 'clear-1', localImagePath: file1.path));
      await historyService.saveScan(buildSampleScan(id: 'clear-2', localImagePath: file2.path));

      expect((await historyService.getAllScans()).length, 2);

      await historyService.clearAllScans();

      expect(await historyService.getAllScans(), isEmpty);
      final scansDir = Directory('${docsDir.path}/scans');
      expect(await scansDir.exists(), isFalse);
    });

    test('queries and thumbnail loading work offline in Airplane mode', () async {
      // Create local image simulating an on-device capture
      final leafCapture = await createTestImageFile('offline_capture.jpg', width: 640, height: 480);

      final scan = buildSampleScan(
        id: 'airplane-mode-scan',
        cropId: 'wheat',
        diseaseId: 'wheat_yellow_rust',
        confidenceScore: 0.88,
        localImagePath: leafCapture.path,
      );

      await historyService.saveScan(scan);

      // In airplane mode (no network connectivity), query local scans
      final offlineScans = await historyService.getAllScans();
      expect(offlineScans, isNotEmpty);

      final retrieved = offlineScans.first;
      expect(retrieved.id, 'airplane-mode-scan');

      // Verify the saved thumbnail can be opened directly from local disk
      final localFile = File(retrieved.localImagePath);
      expect(await localFile.exists(), isTrue);
      expect(await localFile.length(), greaterThan(0));

      final decoded = img.decodeImage(await localFile.readAsBytes());
      expect(decoded, isNotNull);
    });

    test('mergeRemoteScans deduplicates by scan ID and preserves local image paths', () async {
      final localCapture = await createTestImageFile('existing_local.jpg');
      final existingScan = buildSampleScan(
        id: 'scan-1',
        cropId: 'tomato',
        localImagePath: localCapture.path,
        isSynced: false,
      );
      await historyService.saveScan(existingScan);

      final remoteScans = [
        DiagnosisResult(
          id: 'scan-1',
          cropId: 'tomato',
          diseaseId: 'tomato_early_blight',
          diseaseNameEn: 'Early Blight',
          diseaseNameHi: 'अगेती झुलसा',
          confidenceScore: 0.95,
          severity: SeverityLevel.medium,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          localImagePath: '',
          remoteImageUrl: 'https://firebasestorage.googleapis.com/scan-1.jpg',
          isSynced: true,
        ),
        DiagnosisResult(
          id: 'scan-2',
          cropId: 'potato',
          diseaseId: 'potato_late_blight',
          diseaseNameEn: 'Late Blight',
          diseaseNameHi: 'पछेती झुलसा',
          confidenceScore: 0.91,
          severity: SeverityLevel.high,
          timestamp: DateTime.now(),
          localImagePath: '',
          remoteImageUrl: 'https://firebasestorage.googleapis.com/scan-2.jpg',
          isSynced: true,
        ),
      ];

      await historyService.mergeRemoteScans(remoteScans);

      final allScans = await historyService.getAllScans();
      expect(allScans.length, 2);

      // scan-2 is newer, should be first
      expect(allScans[0].id, 'scan-2');
      expect(allScans[0].isSynced, true);
      expect(allScans[0].remoteImageUrl, 'https://firebasestorage.googleapis.com/scan-2.jpg');

      // scan-1 was merged: retained local path, updated remoteImageUrl and isSynced
      final mergedScan1 = allScans.firstWhere((s) => s.id == 'scan-1');
      expect(mergedScan1.isSynced, true);
      expect(mergedScan1.remoteImageUrl, 'https://firebasestorage.googleapis.com/scan-1.jpg');
      expect(mergedScan1.localImagePath, isNotEmpty);
    });

    test('deleteScan adds scanId to tombstone list, and mergeRemoteScans strictly ignores tombstoned scans', () async {
      final sampleScan = buildSampleScan(id: 'tombstone-scan-1');
      await historyService.saveScan(sampleScan);

      expect(await historyService.getScanById('tombstone-scan-1'), isNotNull);
      expect(await historyService.getDeletedScanIds(), isEmpty);

      // Delete scan
      await historyService.deleteScan('tombstone-scan-1');

      // Check it was removed from local scans and added to deletedScanIds
      expect(await historyService.getScanById('tombstone-scan-1'), isNull);
      final deletedIds = await historyService.getDeletedScanIds();
      expect(deletedIds, contains('tombstone-scan-1'));

      // Now attempt to merge remote scans that include the deleted scan
      final remoteScans = [
        buildSampleScan(id: 'tombstone-scan-1', isSynced: true),
        buildSampleScan(id: 'valid-remote-scan-2', isSynced: true),
      ];

      await historyService.mergeRemoteScans(remoteScans);

      final scansAfterMerge = await historyService.getAllScans();
      expect(scansAfterMerge.length, 1);
      expect(scansAfterMerge.first.id, 'valid-remote-scan-2');
      expect(await historyService.getScanById('tombstone-scan-1'), isNull);
    });

    test('clearAllScans marks all existing scan IDs as deleted before clearing', () async {
      await historyService.saveScan(buildSampleScan(id: 'clear-1'));
      await historyService.saveScan(buildSampleScan(id: 'clear-2'));

      await historyService.clearAllScans();

      final deletedIds = await historyService.getDeletedScanIds();
      expect(deletedIds, containsAll(['clear-1', 'clear-2']));
      expect((await historyService.getAllScans()), isEmpty);
    });
  });
}

