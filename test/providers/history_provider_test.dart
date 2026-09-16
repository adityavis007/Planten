import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/models/crop.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/providers/diagnosis_provider.dart';
import 'package:planten/providers/history_provider.dart';
import 'package:planten/services/confidence_evaluation_engine.dart';
import 'package:planten/services/firestore_sync_service.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/inference_service.dart';
import 'package:planten/services/knowledge_base_service.dart';
import 'package:planten/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docsDir;
  late LocalStorageService localStorageService;
  late HistoryService historyService;

  DiagnosisResult buildSampleScan({
    required String id,
    String cropId = 'tomato',
    String diseaseId = 'tomato_early_blight',
    String diseaseNameEn = 'Tomato Early Blight',
    String diseaseNameHi = 'टमाटर का अगेती झुलसा',
    double confidenceScore = 0.90,
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
        symptomsEn: 'Concentric leaf rings.',
        symptomsHi: 'पत्तियों पर छल्लेदार धब्बे।',
        culturalStepsEn: ['Prune lower leaves.'],
        culturalStepsHi: ['निचली पत्तियों को हटाएं।'],
        managementCategory: 'cultural',
        severityLevel: 'medium',
        disclaimerEn: 'Advisory only.',
        disclaimerHi: 'केवल सलाह हेतु।',
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorageService = LocalStorageService(prefs: prefs);

    tempDir = await Directory.systemTemp.createTemp(
      'planten_history_prov_test_',
    );
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

  group('HistoryProvider (Task 47) Unit & State Tests', () {
    test('starts with empty scans and inactive crop filter', () async {
      final provider = HistoryProvider(
        historyService: historyService,
        autoLoad: false,
      );

      expect(provider.scans, isEmpty);
      expect(provider.allScans, isEmpty);
      expect(provider.activeFilterCropId, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.isEmpty, isTrue);
      expect(provider.unsyncedCount, 0);
      expect(provider.hasUnsyncedScans, isFalse);

      provider.dispose();
    });

    test('loadHistory fetches scans and updates sync metrics', () async {
      final scan1 = buildSampleScan(id: 'scan-1', isSynced: false);
      final scan2 = buildSampleScan(id: 'scan-2', isSynced: true);
      await historyService.saveScan(scan1);
      await historyService.saveScan(scan2);

      final provider = HistoryProvider(
        historyService: historyService,
        autoLoad: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.allScans.length, 2);
      expect(provider.scans.length, 2);
      expect(provider.unsyncedCount, 1);
      expect(provider.hasUnsyncedScans, isTrue);
      expect(provider.isLoading, isFalse);

      provider.dispose();
    });

    test(
      'filterByCrop filters visible scans while preserving allScans',
      () async {
        final now = DateTime.now();
        final tomatoScan1 = buildSampleScan(
          id: 'tomato-1',
          cropId: 'tomato',
          timestamp: now.subtract(const Duration(hours: 1)),
        );
        final tomatoScan2 = buildSampleScan(
          id: 'tomato-2',
          cropId: 'tomato',
          timestamp: now,
        );
        final wheatScan = buildSampleScan(
          id: 'wheat-1',
          cropId: 'wheat',
          diseaseId: 'wheat_yellow_rust',
          diseaseNameEn: 'Wheat Yellow Rust',
        );

        await historyService.saveScan(tomatoScan1);
        await historyService.saveScan(tomatoScan2);
        await historyService.saveScan(wheatScan);

        final provider = HistoryProvider(historyService: historyService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.allScans.length, 3);
        expect(provider.scans.length, 3);

        // Filter by Tomato
        provider.filterByCrop('tomato');
        expect(provider.activeFilterCropId, 'tomato');
        expect(provider.scans.length, 2);
        expect(provider.allScans.length, 3);
        expect(provider.scans.every((s) => s.cropId == 'tomato'), isTrue);

        // Filter by Wheat (case-insensitive)
        provider.filterByCrop('WHEAT');
        expect(provider.activeFilterCropId, 'WHEAT');
        expect(provider.scans.length, 1);
        expect(provider.scans.first.id, 'wheat-1');

        // Filter by non-existent crop
        provider.filterByCrop('rice');
        expect(provider.scans, isEmpty);
        expect(provider.isEmpty, isTrue);

        // Reset filter with 'all'
        provider.filterByCrop('all');
        expect(provider.activeFilterCropId, isNull);
        expect(provider.scans.length, 3);

        // Reset filter with null
        provider.filterByCrop('wheat');
        expect(provider.scans.length, 1);
        provider.filterByCrop(null);
        expect(provider.activeFilterCropId, isNull);
        expect(provider.scans.length, 3);

        provider.dispose();
      },
    );

    test(
      'deleteScan removes scan from both allScans and filtered scans',
      () async {
        final scan1 = buildSampleScan(id: 'del-1', cropId: 'tomato');
        final scan2 = buildSampleScan(id: 'del-2', cropId: 'wheat');
        await historyService.saveScan(scan1);
        await historyService.saveScan(scan2);

        final provider = HistoryProvider(historyService: historyService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.allScans.length, 2);

        // Filter to tomato
        provider.filterByCrop('tomato');
        expect(provider.scans.length, 1);

        // Delete the tomato scan
        final success = await provider.deleteScan('del-1');
        expect(success, isTrue);
        expect(provider.scans, isEmpty);
        expect(provider.allScans.length, 1);
        expect(provider.allScans.first.id, 'del-2');

        provider.dispose();
      },
    );

    test('saveScan persists new scan and updates reactive scan list', () async {
      final provider = HistoryProvider(historyService: historyService);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.scans, isEmpty);

      final scan = buildSampleScan(id: 'newly-saved-scan');
      await provider.saveScan(scan);

      expect(provider.scans.length, 1);
      expect(provider.scans.first.id, 'newly-saved-scan');
      expect(provider.allScans.length, 1);

      provider.dispose();
    });

    test(
      'markAsSynced updates sync status and decreases unsyncedCount',
      () async {
        final scan = buildSampleScan(id: 'sync-target', isSynced: false);
        await historyService.saveScan(scan);

        final provider = HistoryProvider(historyService: historyService);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.unsyncedCount, 1);
        expect(provider.hasUnsyncedScans, isTrue);

        await provider.markAsSynced(
          'sync-target',
          remoteImageUrl: 'https://cloud.storage/scans/sync-target.jpg',
        );

        expect(provider.unsyncedCount, 0);
        expect(provider.hasUnsyncedScans, isFalse);
        expect(provider.allScans.first.isSynced, isTrue);
        expect(
          provider.allScans.first.remoteImageUrl,
          'https://cloud.storage/scans/sync-target.jpg',
        );

        provider.dispose();
      },
    );

    test('clearHistory purges all scans from provider and storage', () async {
      await historyService.saveScan(buildSampleScan(id: 'c-1'));
      await historyService.saveScan(buildSampleScan(id: 'c-2'));

      final provider = HistoryProvider(historyService: historyService);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.totalCount, 2);

      await provider.clearHistory();

      expect(provider.totalCount, 0);
      expect(provider.scans, isEmpty);
      expect(provider.allScans, isEmpty);

      provider.dispose();
    });

    test(
      'automatically reloads when bound DiagnosisProvider completes a scan',
      () async {
        // Setup mock image for diagnosis
        final imgFile = File('${tempDir.path}/test_leaf.jpg');
        final image = img.Image(width: 224, height: 224);
        await imgFile.writeAsBytes(img.encodeJpg(image));

        final diagnosisProvider = DiagnosisProvider(
          inferenceService: InferenceService(),
          knowledgeBaseService: KnowledgeBaseService(),
          evaluationEngine: const ConfidenceEvaluationEngine(),
          historyService: historyService,
        );

        final historyProvider = HistoryProvider(
          historyService: historyService,
          diagnosisProvider: diagnosisProvider,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(historyProvider.totalCount, 0);

        // Perform diagnosis with auto-save to history
        const tomatoCrop = Crop(
          id: 'tomato',
          nameEn: 'Tomato',
          nameHi: 'टमाटर',
          iconAssetPath: 'assets/icons/crops/tomato.png',
        );

        await diagnosisProvider.diagnoseLeaf(
          imgFile,
          tomatoCrop,
          saveToHistory: true,
        );
        expect(diagnosisProvider.isSuccess, isTrue);

        // Allow async reload notification to settle
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(historyProvider.totalCount, 1);
        expect(historyProvider.scans.first.cropId, 'tomato');

        historyProvider.dispose();
        diagnosisProvider.dispose();
      },
    );

    test('dispose cleanly detaches listener without errors', () async {
      final diagnosisProvider = DiagnosisProvider();
      final historyProvider = HistoryProvider(
        historyService: historyService,
        diagnosisProvider: diagnosisProvider,
      );

      expect(() => historyProvider.dispose(), returnsNormally);
      diagnosisProvider.dispose();
    });

    test(
      'deleteScan deletes locally, notifies listeners, and calls cloud delete',
      () async {
        String? cloudDeletedScanId;

        final syncService = FirestoreSyncService(
          historyService: historyService,
          localStorageService: localStorageService,
          scanDeleter: (scanId) async {
            cloudDeletedScanId = scanId;
          },
        );

        final provider = HistoryProvider(
          historyService: historyService,
          syncService: syncService,
          userId: 'farmer-42',
        );

        final scan = buildSampleScan(id: 'cloud-del-1');
        await provider.saveScan(scan);
        expect(provider.allScans.length, 1);

        final success = await provider.deleteScan('cloud-del-1');
        expect(success, isTrue);
        expect(provider.allScans, isEmpty);

        // Wait for asynchronous cloud delete to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(cloudDeletedScanId, 'cloud-del-1');

        // Once deleted from cloud, tombstone is cleaned up
        final tombstoned = await historyService.getDeletedScanIds();
        expect(tombstoned, isEmpty);

        provider.dispose();
      },
    );

    test('syncWithCloud purges pending deleted scans before fetching remote scans', () async {
      final purgedScanIds = <String>[];

      final syncService = FirestoreSyncService(
        historyService: historyService,
        localStorageService: localStorageService,
        scanDeleter: (scanId) async {
          purgedScanIds.add(scanId);
        },
        scanFetcher: (userId) async => [],
      );

      final provider = HistoryProvider(
        historyService: historyService,
        syncService: syncService,
      );

      // Create a scan, then delete it while offline (no sync service on delete)
      await historyService.saveScan(buildSampleScan(id: 'offline-del-1'));
      await historyService.deleteScan('offline-del-1');

      // Verify it is in tombstone
      expect(
        await historyService.getDeletedScanIds(),
        contains('offline-del-1'),
      );

      // Now sync with cloud
      await provider.syncWithCloud('farmer-42');

      // Verify the tombstoned scan was purged from cloud and un-tombstoned
      expect(purgedScanIds, contains('offline-del-1'));
      expect(await historyService.getDeletedScanIds(), isEmpty);

      provider.dispose();
    });

    test(
      'clearHistory clears locally and triggers clearAllUserScansFromCloud',
      () async {
        String? clearedUserId;

        final syncService = FirestoreSyncService(
          historyService: historyService,
          localStorageService: localStorageService,
          allScansDeleter: (userId) async {
            clearedUserId = userId;
          },
        );

        final provider = HistoryProvider(
          historyService: historyService,
          syncService: syncService,
          userId: 'farmer-42',
        );

        await provider.saveScan(buildSampleScan(id: 'scan-to-clear'));
        expect(provider.allScans.length, 1);

        await provider.clearHistory();
        expect(provider.allScans, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(clearedUserId, 'farmer-42');

        provider.dispose();
      },
    );
  });
}
