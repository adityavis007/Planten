import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/diagnosis_result.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'history_service.dart';
import 'knowledge_base_service.dart';
import 'local_storage_service.dart';
import 'network_monitor_service.dart';

/// Function signature for writing batches of scan metadata records to Cloud Firestore.
typedef FirestoreBatchWriter = Future<void> Function(
  List<Map<String, dynamic>> records,
);

/// Function signature for querying remote scan records from Cloud Firestore.
typedef FirestoreScanFetcher = Future<List<Map<String, dynamic>>> Function(
  String userId,
);

/// Function signature for deleting an individual scan from Cloud Firestore.
typedef FirestoreScanDeleter = Future<void> Function(String scanId);

/// Function signature for clearing all scans for a user from Cloud Firestore.
typedef FirestoreAllScansDeleter = Future<void> Function(String userId);

/// Function signature for uploading compressed scan photos to Firebase Storage.
typedef PhotoUploader = Future<String?> Function({
  required String userId,
  required String scanId,
  required File imageFile,
});

/// Enum describing outcome status of a sync execution.
enum SyncStatus {
  /// All pending scans successfully synced to Firestore.
  success,

  /// Device is currently offline; sync aborted.
  offline,

  /// Cloud Firestore service is unconfigured or unavailable.
  unavailable,

  /// No unsynced scans are currently waiting in local storage.
  noPending,

  /// Some batches succeeded while one or more failed.
  partialError,

  /// Sync operation encountered an unhandled exception or failed completely.
  error,
}

/// Result object summarizing the outcome of a sync operation.
@immutable
class SyncResult {
  final SyncStatus status;
  final int totalPending;
  final int syncedCount;
  final String? errorMessage;

  const SyncResult({
    required this.status,
    this.totalPending = 0,
    this.syncedCount = 0,
    this.errorMessage,
  });

  bool get isSuccess =>
      status == SyncStatus.success || status == SyncStatus.noPending;

  @override
  String toString() =>
      'SyncResult(status: $status, pending: $totalPending, synced: $syncedCount, error: $errorMessage)';
}

/// Service managing offline-to-cloud metadata synchronization with Cloud Firestore (`scans/{scanId}`)
/// and optional photo backup to Firebase Storage (`users/{uid}/scans/{scanId}.jpg`).
///
/// Features & Architectural Guardrails:
/// - Spark Free Tier Optimization: Uses `WriteBatch` chunked up to 500 documents per batch.
/// - Strict Privacy & Bandwidth Protection (PRD Section 8): Photos are NEVER uploaded unless
///   the farmer explicitly opted in via `FarmerProfile.photoBackupOptIn`. When opted out,
///   image upload is completely bypassed, and `remoteImageUrl` is set to null.
/// - Image Compression (<200KB): When backup is enabled, photos are automatically scaled
///   and compressed under 200KB before transmission to preserve cloud storage and mobile data.
/// - Resilient Sync: Photo upload errors are non-fatal; metadata is still safely preserved.
/// - Two-way local state update: Once successfully committed to Firestore, local records are marked `isSynced = true`.
/// - Automatic & Manual Sync: Listens to [NetworkMonitorService] for offline-to-online transitions or executes on demand.
/// - Concurrency Lock: Prevents duplicate parallel sync executions.
class FirestoreSyncService {
  static const String scansCollection = 'scans';
  static const int maxBatchSize = 500;
  static const int maxPhotoBytes = 200 * 1024; // 200KB ceiling

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final HistoryService _historyService;
  final NetworkMonitorService? _networkMonitorService;
  final LocalStorageService _localStorageService;
  final AuthService? _authService;
  final FirestoreBatchWriter? _customBatchWriter;
  final PhotoUploader? _customPhotoUploader;
  final FirestoreScanFetcher? _customScanFetcher;
  final FirestoreScanDeleter? _customScanDeleter;
  final FirestoreAllScansDeleter? _customAllScansDeleter;
  final KnowledgeBaseService? _knowledgeBaseService;

  bool _isSyncing = false;
  bool _autoSyncStarted = false;

  FirestoreSyncService({
    this._firestore,
    this._storage,
    HistoryService? historyService,
    this._networkMonitorService,
    LocalStorageService? localStorageService,
    this._authService,
    FirestoreBatchWriter? batchWriter,
    PhotoUploader? photoUploader,
    FirestoreScanFetcher? scanFetcher,
    FirestoreScanDeleter? scanDeleter,
    FirestoreAllScansDeleter? allScansDeleter,
    this._knowledgeBaseService,
  }) : _historyService = historyService ?? HistoryService(),
       _localStorageService = localStorageService ?? LocalStorageService(),
       _customBatchWriter = batchWriter,
       _customPhotoUploader = photoUploader,
       _customScanFetcher = scanFetcher,
       _customScanDeleter = scanDeleter,
       _customAllScansDeleter = allScansDeleter;

  /// Whether a sync operation is actively in progress.
  bool get isSyncing => _isSyncing;

  /// Whether auto-sync listener is attached to [NetworkMonitorService].
  bool get isAutoSyncActive => _autoSyncStarted;

  /// Active [FirebaseFirestore] instance from injection, [FirebaseService], or null if offline.
  FirebaseFirestore? get firestoreOrNull {
    if (_firestore != null) return _firestore;
    if (FirebaseService.instance.isAvailable) {
      return FirebaseService.instance.firestore;
    }
    return null;
  }

  /// Active [FirebaseStorage] instance from injection, [FirebaseService], or null if offline.
  FirebaseStorage? get storageOrNull {
    if (_storage != null) return _storage;
    if (FirebaseService.instance.isAvailable) {
      return FirebaseService.instance.storage;
    }
    return null;
  }

  /// Begins listening to [NetworkMonitorService] to auto-trigger sync when connectivity restores.
  void startAutoSync() {
    if (_autoSyncStarted || _networkMonitorService == null) return;
    _networkMonitorService.registerSyncCallback(_autoSyncCallback);
    _autoSyncStarted = true;
  }

  /// Stops auto-sync listener from [NetworkMonitorService].
  void stopAutoSync() {
    if (!_autoSyncStarted || _networkMonitorService == null) return;
    _networkMonitorService.unregisterSyncCallback(_autoSyncCallback);
    _autoSyncStarted = false;
  }

  Future<void> _autoSyncCallback() async {
    await syncPendingScans();
  }

  /// Compresses an image file to strictly under [maxBytes] (default 200KB) for cloud backup.
  ///
  /// Resizes image dimensions if oversized and progressively applies JPEG compression.
  Future<Uint8List?> compressImageForBackup(
    File imageFile, {
    int maxBytes = maxPhotoBytes,
  }) async {
    try {
      if (!await imageFile.exists()) return null;

      final rawBytes = await imageFile.readAsBytes();
      if (rawBytes.lengthInBytes <= maxBytes) {
        return rawBytes;
      }

      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        return rawBytes.lengthInBytes <= maxBytes ? rawBytes : null;
      }

      const maxDimension = 1024;
      img.Image resized = decoded;
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        if (decoded.width >= decoded.height) {
          resized = img.copyResize(decoded, width: maxDimension);
        } else {
          resized = img.copyResize(decoded, height: maxDimension);
        }
      }

      for (var quality = 80; quality >= 40; quality -= 15) {
        final encoded = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );
        if (encoded.lengthInBytes <= maxBytes) {
          return encoded;
        }
      }

      final smaller = img.copyResize(resized, width: 640);
      final finalAttempt = Uint8List.fromList(
        img.encodeJpg(smaller, quality: 50),
      );
      return finalAttempt.lengthInBytes <= maxBytes ? finalAttempt : null;
    } catch (e) {
      debugPrint(
        'FirestoreSyncService: Error compressing image for backup: $e',
      );
      return null;
    }
  }

  /// Default photo uploader targeting Firebase Storage (`users/{uid}/scans/{scanId}.jpg`).
  Future<String?> _defaultPhotoUploader({
    required String userId,
    required String scanId,
    required File imageFile,
  }) async {
    final storage = storageOrNull;
    if (storage == null) return null;

    final compressedBytes = await compressImageForBackup(imageFile);
    if (compressedBytes == null) return null;

    final storageRef = storage.ref().child('users/$userId/scans/$scanId.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'scanId': scanId, 'userId': userId},
    );

    final uploadTask = storageRef.putData(compressedBytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Builds Firestore metadata document payload adhering to privacy constraints.
  ///
  /// Excludes raw image binary data. Only populates `remoteImageUrl` if provided.
  Map<String, dynamic> buildScanMetadataPayload({
    required DiagnosisResult scan,
    required String userId,
    String? remoteImageUrl,
  }) {
    return {
      'id': scan.id,
      'userId': userId,
      'user_id': userId,
      'cropId': scan.cropId,
      'crop_id': scan.cropId,
      'diseaseId': scan.diseaseId,
      'disease_id': scan.diseaseId,
      'diseaseNameEn': scan.diseaseNameEn,
      'disease_name_en': scan.diseaseNameEn,
      'diseaseNameHi': scan.diseaseNameHi,
      'disease_name_hi': scan.diseaseNameHi,
      'confidenceScore': scan.confidenceScore,
      'confidence_score': scan.confidenceScore,
      'severity': scan.severity.toJson(),
      'timestamp': scan.timestamp.toIso8601String(),
      'remoteImageUrl': remoteImageUrl,
      'remote_image_url': remoteImageUrl,
      'isSynced': true,
      'is_synced': true,
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
      if (scan.guidance != null) 'guidance': scan.guidance!.toJson(),
    };
  }

  /// Synchronizes all unsynced scans from local storage to Cloud Firestore.
  ///
  /// If [FarmerProfile.photoBackupOptIn] is true, also uploads compressed photo to Firebase Storage.
  Future<SyncResult> syncPendingScans() async {
    // 1. Concurrency lock
    if (_isSyncing) {
      return const SyncResult(
        status: SyncStatus.noPending,
        errorMessage: 'Sync already in progress',
      );
    }
    _isSyncing = true;

    try {
      // 2. Connectivity check
      if (_networkMonitorService != null && !_networkMonitorService.isOnline) {
        return const SyncResult(
          status: SyncStatus.offline,
          errorMessage: 'Device is offline',
        );
      }

      // 3. Firestore availability check
      final client = firestoreOrNull;
      if (client == null && _customBatchWriter == null) {
        return const SyncResult(
          status: SyncStatus.unavailable,
          errorMessage: 'Cloud Firestore is not available',
        );
      }

      // 4. Query unsynced scans
      final unsyncedScans = await _historyService.getUnsyncedScans();
      if (unsyncedScans.isEmpty) {
        return const SyncResult(
          status: SyncStatus.noPending,
          totalPending: 0,
          syncedCount: 0,
        );
      }

      // 5. Resolve user ID & photo backup opt-in status
      await _localStorageService.init();
      final cachedProfile = _localStorageService.getUserProfile();
      final userId =
          _authService?.currentUid ?? cachedProfile?.uid ?? 'anonymous_farmer';
      final photoBackupOptIn = cachedProfile?.photoBackupOptIn ?? false;

      // 6. Partition scans into chunks up to maxBatchSize (500)
      final totalPending = unsyncedScans.length;
      int syncedCount = 0;
      bool hasErrors = false;
      String? firstErrorMessage;

      for (var i = 0; i < unsyncedScans.length; i += maxBatchSize) {
        final end = (i + maxBatchSize < unsyncedScans.length)
            ? i + maxBatchSize
            : unsyncedScans.length;
        final batchScans = unsyncedScans.sublist(i, end);

        // Process photo backup if opted in
        final Map<String, String?> scanRemoteUrls = {};
        if (photoBackupOptIn) {
          for (final scan in batchScans) {
            if (scan.remoteImageUrl != null &&
                scan.remoteImageUrl!.isNotEmpty) {
              scanRemoteUrls[scan.id] = scan.remoteImageUrl;
            } else if (scan.localImagePath.isNotEmpty) {
              try {
                final imageFile = File(scan.localImagePath);
                if (await imageFile.exists()) {
                  final uploader =
                      _customPhotoUploader ?? _defaultPhotoUploader;
                  final uploadedUrl = await uploader(
                    userId: userId,
                    scanId: scan.id,
                    imageFile: imageFile,
                  );
                  scanRemoteUrls[scan.id] = uploadedUrl;
                } else {
                  scanRemoteUrls[scan.id] = null;
                }
              } catch (e) {
                debugPrint(
                  'FirestoreSyncService: Optional photo backup failed for scan ${scan.id}: $e',
                );
                scanRemoteUrls[scan.id] = null;
              }
            } else {
              scanRemoteUrls[scan.id] = null;
            }
          }
        }

        final records = batchScans.map((scan) {
          final remoteUrl = photoBackupOptIn ? scanRemoteUrls[scan.id] : null;
          return buildScanMetadataPayload(
            scan: scan,
            userId: userId,
            remoteImageUrl: remoteUrl,
          );
        }).toList();

        try {
          if (_customBatchWriter != null) {
            await _customBatchWriter(records);
          } else if (client != null) {
            await _writeBatchToFirestore(client, records);
          }

          // 7. Mark successfully committed scans as synced locally
          for (final scan in batchScans) {
            final effectiveRemoteUrl = photoBackupOptIn
                ? scanRemoteUrls[scan.id]
                : null;
            await _historyService.markAsSynced(
              scan.id,
              remoteImageUrl: effectiveRemoteUrl,
            );
            syncedCount++;
          }
        } catch (e) {
          debugPrint('FirestoreSyncService: Error committing batch: $e');
          hasErrors = true;
          firstErrorMessage ??= e.toString();
        }
      }

      if (hasErrors) {
        if (syncedCount > 0) {
          return SyncResult(
            status: SyncStatus.partialError,
            totalPending: totalPending,
            syncedCount: syncedCount,
            errorMessage: firstErrorMessage,
          );
        } else {
          return SyncResult(
            status: SyncStatus.error,
            totalPending: totalPending,
            syncedCount: 0,
            errorMessage: firstErrorMessage,
          );
        }
      }

      return SyncResult(
        status: SyncStatus.success,
        totalPending: totalPending,
        syncedCount: syncedCount,
      );
    } catch (e) {
      debugPrint('FirestoreSyncService: Unhandled sync exception: $e');
      return SyncResult(status: SyncStatus.error, errorMessage: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Default batch writer committing documents via Firestore `WriteBatch`.
  Future<void> _writeBatchToFirestore(
    FirebaseFirestore firestore,
    List<Map<String, dynamic>> records,
  ) async {
    final batch = firestore.batch();
    for (final record in records) {
      final docId = record['id'] as String;
      final docRef = firestore.collection(scansCollection).doc(docId);
      batch.set(docRef, record, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Fetches all scans for a specific [userId] from Cloud Firestore and merges them into local storage.
  ///
  /// This ensures that when a user logs in on a new device with the same account,
  /// their entire diagnosis history is restored immediately.
  Future<List<DiagnosisResult>> fetchUserScans(String userId) async {
    if (userId.isEmpty) return [];

    try {
      List<Map<String, dynamic>> rawRecords = [];

      if (_customScanFetcher != null) {
        rawRecords = await _customScanFetcher(userId);
      } else {
        final client = firestoreOrNull;
        if (client == null) {
          debugPrint(
            'FirestoreSyncService: Firestore client unavailable to fetch scans.',
          );
          return [];
        }

        // Query by 'userId' (or fallback to 'user_id')
        QuerySnapshot<Map<String, dynamic>> snapshot = await client
            .collection(scansCollection)
            .where('userId', isEqualTo: userId)
            .get();

        if (snapshot.docs.isEmpty) {
          snapshot = await client
              .collection(scansCollection)
              .where('user_id', isEqualTo: userId)
              .get();
        }

        rawRecords = snapshot.docs.map((d) => d.data()).toList();
      }

      if (rawRecords.isEmpty) {
        return [];
      }

      final List<DiagnosisResult> remoteScans = [];
      for (final data in rawRecords) {
        try {
          var scan = DiagnosisResult.fromJson(data);
          // Rehydrate guidance from knowledge base if null and disease exists
          if (scan.guidance == null &&
              scan.diseaseId.isNotEmpty &&
              !scan.isHealthy) {
            final kb = _knowledgeBaseService ?? KnowledgeBaseService();
            final guidance = kb.getGuidanceByDiseaseId(scan.diseaseId);
            if (guidance != null) {
              scan = scan.copyWith(guidance: guidance);
            }
          }
          remoteScans.add(scan);
        } catch (err) {
          debugPrint(
            'FirestoreSyncService: Error parsing remote scan doc: $err',
          );
        }
      }

      // Merge into local history
      await _historyService.mergeRemoteScans(remoteScans);
      return remoteScans;
    } catch (e) {
      debugPrint(
        'FirestoreSyncService: Error fetching scans for user $userId: $e',
      );
      return [];
    }
  }

  /// Permanently deletes a scan record from Cloud Firestore and optional photo from Firebase Storage.
  Future<bool> deleteScanFromCloud({
    required String scanId,
    String? userId,
  }) async {
    try {
      if (_customScanDeleter != null) {
        await _customScanDeleter(scanId);
        return true;
      }

      final client = firestoreOrNull;
      if (client != null) {
        await client.collection(scansCollection).doc(scanId).delete();
      }

      // Also clean up remote photo from Firebase Storage if exists
      final storage = storageOrNull;
      if (storage != null && userId != null && userId.isNotEmpty) {
        try {
          final photoRef = storage.ref().child(
            'users/$userId/scans/$scanId.jpg',
          );
          await photoRef.delete();
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint(
        'FirestoreSyncService: Error deleting scan $scanId from cloud: $e',
      );
      return false;
    }
  }

  /// Permanently deletes all scan records for a specific [userId] from Cloud Firestore.
  Future<bool> clearAllUserScansFromCloud(String userId) async {
    if (userId.isEmpty) return false;
    try {
      if (_customAllScansDeleter != null) {
        await _customAllScansDeleter(userId);
        return true;
      }

      final client = firestoreOrNull;
      if (client == null) return false;

      QuerySnapshot<Map<String, dynamic>> snapshot = await client
          .collection(scansCollection)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await client
            .collection(scansCollection)
            .where('user_id', isEqualTo: userId)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        final batch = client.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint(
        'FirestoreSyncService: Error clearing all scans from cloud: $e',
      );
      return false;
    }
  }

  /// Cleanup listeners.
  void dispose() {
    stopAutoSync();
  }
}
