import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service monitoring internet connectivity state and coordinating offline-to-online background sync.
///
/// Features:
/// - Wraps `connectivity_plus` to detect WiFi, Cellular, Ethernet, or None states.
/// - Exposes reactive broadcast stream [isOnlineStream] and synchronous boolean getter [isOnline].
/// - Automatically invokes registered background sync callbacks when transitioning from offline to online.
/// - Allows manual sync trigger via [triggerSyncNow] when connected.
class NetworkMonitorService {
  final Connectivity _connectivity;
  final List<Future<void> Function()> _syncCallbacks = [];
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = false;
  bool _isInitialized = false;

  NetworkMonitorService({
    Connectivity? connectivity,
    Future<void> Function()? onSyncCallback,
  }) : _connectivity = connectivity ?? Connectivity() {
    if (onSyncCallback != null) {
      registerSyncCallback(onSyncCallback);
    }
  }

  /// Whether device currently has an active internet connection.
  bool get isOnline => _isOnline;

  /// Whether the initial connectivity query has completed.
  bool get isInitialized => _isInitialized;

  /// Broadcast stream emitting connectivity boolean flags whenever connection status changes.
  Stream<bool> get isOnlineStream => _controller.stream;

  /// Helper evaluating whether a list of [ConnectivityResult] represents an online status.
  static bool isOnlineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Initializes the service by querying current connectivity and listening to changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final initialResults = await _connectivity.checkConnectivity();
      _isOnline = isOnlineFromResults(initialResults);
    } catch (e) {
      debugPrint('NetworkMonitorService: Error checking initial connectivity: $e');
      _isOnline = false;
    }

    _isInitialized = true;
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChanged);
  }

  /// Handles incoming connectivity updates from platform stream.
  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    final currentlyOnline = isOnlineFromResults(results);

    _isOnline = currentlyOnline;

    if (wasOnline != currentlyOnline) {
      _controller.add(currentlyOnline);

      // Trigger sync callback specifically when transitioning from offline to online
      if (!wasOnline && currentlyOnline) {
        triggerSyncNow();
      }
    }
  }

  /// Registers a background sync callback to run on reconnection.
  void registerSyncCallback(Future<void> Function() callback) {
    if (!_syncCallbacks.contains(callback)) {
      _syncCallbacks.add(callback);
    }
  }

  /// Removes a previously registered sync callback.
  void unregisterSyncCallback(Future<void> Function() callback) {
    _syncCallbacks.remove(callback);
  }

  /// Manually triggers all registered sync callbacks if device is online.
  Future<void> triggerSyncNow() async {
    if (!_isOnline) return;

    for (final callback in List.of(_syncCallbacks)) {
      try {
        await callback();
      } catch (e) {
        debugPrint('NetworkMonitorService: Error executing sync callback: $e');
      }
    }
  }

  /// Disposes stream subscriptions and controller resources.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
    _syncCallbacks.clear();
  }
}
