import 'package:flutter/foundation.dart';

import '../services/firestore_sync_service.dart';
import '../services/history_service.dart';
import 'diagnosis_provider.dart';

/// State management provider for leaf diagnosis history, crop filtering, and sync status.
///
/// Features:
/// - Exposes the reactive list of scans [scans] honoring active crop filter [activeFilterCropId].
/// - Provides full list [allScans] and sync metrics ([unsyncedCount], [hasUnsyncedScans]).
/// - Automatically reloads history when an optional bound [DiagnosisProvider] completes a scan.
/// - Encapsulates loading state [isLoading] and error messaging [errorMessage].
class HistoryProvider extends ChangeNotifier {
  final HistoryService _historyService;
  final DiagnosisProvider? _diagnosisProvider;
  final FirestoreSyncService? _syncService;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _activeFilterCropId;
  String? _userId;
  String? _syncedUserId;
  List<DiagnosisResult> _allScans = const [];
  List<DiagnosisResult> _scans = const [];

  HistoryProvider({
    HistoryService? historyService,
    this._diagnosisProvider,
    this._syncService,
    this._userId,
    bool autoLoad = true,
  }) : _historyService = historyService ?? HistoryService() {
    if (_diagnosisProvider != null) {
      _diagnosisProvider.addListener(_onDiagnosisProviderUpdated);
    }
    if (autoLoad) {
      loadHistory();
    }
  }

  /// ID of user whose history has been synced with cloud.
  String? get syncedUserId => _syncedUserId;

  /// Updates current active user ID.
  void updateUserId(String? userId) {
    _userId = userId;
  }

  /// List of diagnosis scans currently displayed, reflecting [activeFilterCropId].
  List<DiagnosisResult> get scans => List.unmodifiable(_scans);

  /// Complete list of cached scans regardless of active filter.
  List<DiagnosisResult> get allScans => List.unmodifiable(_allScans);

  /// Active crop identifier filter (e.g. `'tomato'`, `'wheat'`). Null if showing all crops.
  String? get activeFilterCropId => _activeFilterCropId;

  /// Whether a history loading or mutation operation is actively in progress.
  bool get isLoading => _isLoading;

  /// Human-readable error message if an operation failed, or null if healthy.
  String? get errorMessage => _errorMessage;

  /// True if the currently filtered scan list is empty.
  bool get isEmpty => _scans.isEmpty;

  /// Number of scans in the currently filtered list.
  int get count => _scans.length;

  /// Total number of scans saved across all crops.
  int get totalCount => _allScans.length;

  /// Total count of scans that have not yet synced to the cloud.
  int get unsyncedCount => _allScans.where((s) => !s.isSynced).length;

  /// True if there are one or more scans waiting to be synced.
  bool get hasUnsyncedScans => unsyncedCount > 0;

  /// Loads scans from local storage via [HistoryService] and applies the active filter.
  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final loaded = await _historyService.getAllScans();
      if (_isDisposed) return;
      _allScans = loaded;
      _applyCropFilter();
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      if (_isDisposed) return;
      _isLoading = false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
    }
  }

  /// Sets the active crop filter and updates [scans].
  ///
  /// Passing `null`, `""`, or `"all"` clears the filter and displays all scans.
  void filterByCrop(String? cropId) {
    if (cropId == null ||
        cropId.trim().isEmpty ||
        cropId.trim().toLowerCase() == 'all') {
      _activeFilterCropId = null;
    } else {
      _activeFilterCropId = cropId.trim();
    }
    _applyCropFilter();
    _safeNotifyListeners();
  }

  /// Deletes a scan record by its ID and updates the active lists, purging it from the cloud.
  Future<bool> deleteScan(String scanId) async {
    try {
      final success = await _historyService.deleteScan(scanId);
      if (_isDisposed) return success;
      if (success) {
        _allScans = _allScans.where((s) => s.id != scanId).toList();
        _applyCropFilter();
        _safeNotifyListeners();

        // Concurrently purge from Cloud Firestore so sync never resurrects it
        final service = _syncService ?? FirestoreSyncService();
        service
            .deleteScanFromCloud(scanId: scanId, userId: _userId)
            .then((purged) {
              if (purged) {
                _historyService.unmarkScanAsDeleted(scanId);
              }
            })
            .catchError((e) {
              debugPrint(
                'HistoryProvider: Cloud delete error for scan $scanId: $e',
              );
            });
      }
      return success;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  /// Saves a scan to offline history and immediately reloads.
  Future<void> saveScan(DiagnosisResult scan) async {
    try {
      await _historyService.saveScan(scan);
      if (_isDisposed) return;
      await loadHistory();
    } catch (e) {
      if (_isDisposed) rethrow;
      _errorMessage = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Marks a specific scan as synced with optional remote cloud image URL.
  Future<void> markAsSynced(String scanId, {String? remoteImageUrl}) async {
    try {
      await _historyService.markAsSynced(
        scanId,
        remoteImageUrl: remoteImageUrl,
      );
      if (_isDisposed) return;
      await loadHistory();
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString();
      _safeNotifyListeners();
    }
  }

  /// Downloads all remote scans for [userId] from Cloud Firestore and merges them into local history.
  Future<void> syncWithCloud(String userId) async {
    if (userId.isEmpty) return;
    _userId = userId;
    _syncedUserId = userId;
    try {
      final service = _syncService ?? FirestoreSyncService();

      // First purge any pending locally deleted scans from the cloud
      final pendingDeletedIds = await _historyService.getDeletedScanIds();
      for (final deletedId in pendingDeletedIds) {
        final purged = await service.deleteScanFromCloud(
          scanId: deletedId,
          userId: userId,
        );
        if (purged) {
          await _historyService.unmarkScanAsDeleted(deletedId);
        }
      }

      await service.fetchUserScans(userId);
      if (_isDisposed) return;
      await loadHistory();
    } catch (e) {
      debugPrint('HistoryProvider: Error syncing with cloud: $e');
    }
  }

  /// Clears all scan history from local storage, memory, and Cloud Firestore.
  Future<void> clearHistory() async {
    try {
      await _historyService.clearAllScans();
      if (_isDisposed) return;
      _allScans = const [];
      _scans = const [];
      _safeNotifyListeners();

      if (_userId != null && _userId!.isNotEmpty) {
        final service = _syncService ?? FirestoreSyncService();
        service.clearAllUserScansFromCloud(_userId!).catchError((e) {
          debugPrint('HistoryProvider: Cloud clear error: $e');
          return false;
        });
      }
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString();
      _safeNotifyListeners();
    }
  }

  /// Internal listener reacting to [DiagnosisProvider] completion.
  void _onDiagnosisProviderUpdated() {
    if (_diagnosisProvider != null &&
        _diagnosisProvider.isSuccess &&
        _diagnosisProvider.currentDiagnosis != null) {
      loadHistory();
    }
  }

  /// Recomputes [_scans] based on [_activeFilterCropId].
  void _applyCropFilter() {
    if (_activeFilterCropId == null) {
      _scans = List.of(_allScans);
    } else {
      final filter = _activeFilterCropId!.toLowerCase();
      _scans = _allScans
          .where((s) => s.cropId.toLowerCase() == filter)
          .toList();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _diagnosisProvider?.removeListener(_onDiagnosisProviderUpdated);
    super.dispose();
  }
}
