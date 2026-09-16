import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/diagnosis_result.dart';
import 'local_storage_service.dart';

/// Service providing offline-first local persistence and retrieval of leaf scan history.
///
/// Features:
/// - Persists scan metadata as JSON in local storage via [LocalStorageService].
/// - Resizes and compresses leaf photographs into lightweight thumbnails (JPEG max 320px)
///   stored in the application documents directory (`path_provider`).
/// - Query scans sorted newest-first, filter by crop, manage sync state, and safely delete entries.
/// - Supports offline querying when device is in Airplane mode.
class HistoryService {
  final LocalStorageService _localStorageService;
  final Future<Directory> Function()? _documentsDirectoryProvider;

  HistoryService({
    LocalStorageService? localStorageService,
    this._documentsDirectoryProvider,
  }) : _localStorageService = localStorageService ?? LocalStorageService();

  /// Internal resolver for application documents directory.
  Future<Directory> _getDocumentsDirectory() async {
    if (_documentsDirectoryProvider != null) {
      return _documentsDirectoryProvider();
    }
    return getApplicationDocumentsDirectory();
  }

  /// Stores a [DiagnosisResult] scan locally.
  ///
  /// If [scan.localImagePath] points to an existing file on device, this method
  /// generates a compressed thumbnail in `<documentsDir>/scans/thumb_<id>.jpg`
  /// and updates [scan.localImagePath] with this reliable path before saving.
  Future<void> saveScan(DiagnosisResult scan) async {
    await _localStorageService.init();

    String effectiveImagePath = scan.localImagePath;

    if (scan.localImagePath.isNotEmpty) {
      final sourceFile = File(scan.localImagePath);
      if (sourceFile.existsSync()) {
        effectiveImagePath = await _generateAndSaveThumbnail(
          sourceFile,
          scan.id,
        );
      }
    }

    final updatedScan = scan.copyWith(localImagePath: effectiveImagePath);
    await _localStorageService.addOfflineScan(updatedScan);
  }

  /// Retrieves all cached offline scans sorted by timestamp descending (newest first).
  Future<List<DiagnosisResult>> getAllScans() async {
    await _localStorageService.init();
    final scans = _localStorageService.getOfflineScans();
    scans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return scans;
  }

  /// Retrieves scans for a specific crop ID (case-insensitive), sorted newest first.
  Future<List<DiagnosisResult>> getScansByCrop(String cropId) async {
    final allScans = await getAllScans();
    final normalizedCropId = cropId.trim().toLowerCase();
    return allScans
        .where((s) => s.cropId.trim().toLowerCase() == normalizedCropId)
        .toList();
  }

  /// Searches saved scan history by crop name, disease name, or ID.
  Future<List<DiagnosisResult>> searchScans(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final allScans = await getAllScans();
    return allScans.where((s) {
      return s.cropId.toLowerCase().contains(q) ||
          s.crop.nameEn.toLowerCase().contains(q) ||
          s.crop.nameHi.toLowerCase().contains(q) ||
          s.diseaseNameEn.toLowerCase().contains(q) ||
          s.diseaseNameHi.toLowerCase().contains(q) ||
          s.diseaseId.toLowerCase().contains(q);
    }).toList();
  }

  /// Looks up a single scan by its unique UUID. Returns null if not found.
  Future<DiagnosisResult?> getScanById(String scanId) async {
    final allScans = await getAllScans();
    try {
      return allScans.firstWhere((s) => s.id == scanId);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a scan entry from local storage, marks it as tombstoned, and cleans up its thumbnail file.
  Future<bool> deleteScan(String scanId) async {
    await _localStorageService.init();
    await _localStorageService.markScanAsDeleted(scanId);
    final scan = await getScanById(scanId);

    if (scan != null && scan.localImagePath.isNotEmpty) {
      try {
        final file = File(scan.localImagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('HistoryService: Error deleting thumbnail file: $e');
      }
    }

    return _localStorageService.deleteOfflineScan(scanId);
  }

  /// Updates a scan record's sync status to true, optionally attaching [remoteImageUrl].
  Future<void> markAsSynced(String scanId, {String? remoteImageUrl}) async {
    await _localStorageService.init();
    final scans = await getAllScans();
    final index = scans.indexWhere((s) => s.id == scanId);

    if (index >= 0) {
      final updated = scans[index].copyWith(
        isSynced: true,
        remoteImageUrl: remoteImageUrl,
      );
      scans[index] = updated;
      await _localStorageService.saveOfflineScans(scans);
    }
  }

  /// Returns all scans that have not yet been synced to cloud storage.
  Future<List<DiagnosisResult>> getUnsyncedScans() async {
    final allScans = await getAllScans();
    return allScans.where((s) => !s.isSynced).toList();
  }

  /// Merges remote scans downloaded from Cloud Firestore into local storage.
  ///
  /// Deduplicates by scan ID, respects locally deleted tombstones, preserves existing
  /// local thumbnail paths, marks records as synced, and maintains newest-first sort order.
  Future<void> mergeRemoteScans(List<DiagnosisResult> remoteScans) async {
    if (remoteScans.isEmpty) return;
    await _localStorageService.init();
    final deletedIds = _localStorageService.getDeletedScanIds().toSet();
    final activeRemoteScans = remoteScans
        .where((s) => !deletedIds.contains(s.id))
        .toList();

    final localScans = await getAllScans();
    final Map<String, DiagnosisResult> scanMap = {
      for (final scan in localScans) scan.id: scan,
    };

    for (final remote in activeRemoteScans) {
      if (scanMap.containsKey(remote.id)) {
        final existing = scanMap[remote.id]!;
        scanMap[remote.id] = existing.copyWith(
          isSynced: true,
          remoteImageUrl: remote.remoteImageUrl ?? existing.remoteImageUrl,
        );
      } else {
        scanMap[remote.id] = remote.copyWith(isSynced: true);
      }
    }

    // Explicitly guarantee no deleted tombstones survive
    for (final id in deletedIds) {
      scanMap.remove(id);
    }

    final merged = scanMap.values.toList();
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _localStorageService.saveOfflineScans(merged);
  }

  /// Clears all local scans from storage and deletes the local thumbnail directory.
  Future<void> clearAllScans() async {
    await _localStorageService.init();
    final existingScans = await getAllScans();
    for (final s in existingScans) {
      await _localStorageService.markScanAsDeleted(s.id);
    }
    try {
      final docDir = await _getDocumentsDirectory();
      final scansDir = Directory('${docDir.path}/scans');
      if (scansDir.existsSync()) {
        scansDir.deleteSync(recursive: true);
      }
    } catch (e) {
      debugPrint('HistoryService: Error clearing scans directory: $e');
    }
    await _localStorageService.saveOfflineScans([]);
  }

  /// Retrieves all scan IDs currently tombstoned as deleted locally.
  Future<List<String>> getDeletedScanIds() async {
    await _localStorageService.init();
    return _localStorageService.getDeletedScanIds();
  }

  /// Unmarks a scan ID from the tombstone set once purged from the cloud.
  Future<void> unmarkScanAsDeleted(String scanId) async {
    await _localStorageService.init();
    await _localStorageService.unmarkScanAsDeleted(scanId);
  }

  /// Generates a compressed JPEG thumbnail (max dimension 320px, 80% quality)
  /// and saves it under `<documentsDir>/scans/thumb_<scanId>.jpg`.
  Future<String> _generateAndSaveThumbnail(
    File sourceFile,
    String scanId,
  ) async {
    try {
      final docDir = await _getDocumentsDirectory();
      final scansDir = Directory('${docDir.path}/scans');
      if (!scansDir.existsSync()) {
        scansDir.createSync(recursive: true);
      }

      final targetFile = File('${scansDir.path}/thumb_$scanId.jpg');

      // If already pointing to the target file and exists, avoid redundant write
      if (sourceFile.path == targetFile.path && targetFile.existsSync()) {
        return targetFile.path;
      }

      final bytes = sourceFile.readAsBytesSync();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        const int maxDimension = 320;
        img.Image resizedImage;
        if (decodedImage.width > maxDimension ||
            decodedImage.height > maxDimension) {
          if (decodedImage.width >= decodedImage.height) {
            resizedImage = img.copyResize(decodedImage, width: maxDimension);
          } else {
            resizedImage = img.copyResize(decodedImage, height: maxDimension);
          }
        } else {
          resizedImage = decodedImage;
        }

        final jpgBytes = img.encodeJpg(resizedImage, quality: 80);
        targetFile.writeAsBytesSync(jpgBytes);
        return targetFile.path;
      } else {
        // Fallback: copy bytes directly if image decoder cannot parse format
        sourceFile.copySync(targetFile.path);
        return targetFile.path;
      }
    } catch (e) {
      debugPrint(
        'HistoryService: Failed to compress thumbnail for scan $scanId: $e',
      );
      return sourceFile.path;
    }
  }
}
