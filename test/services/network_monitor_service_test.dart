import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planten/services/network_monitor_service.dart';

/// Test double simulating [Connectivity] without platform channels.
class FakeConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> currentResults;

  FakeConnectivity({this.currentResults = const [ConnectivityResult.none]});

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return currentResults;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeConnectivity fakeConnectivity;
  late NetworkMonitorService networkService;

  setUp(() {
    fakeConnectivity = FakeConnectivity();
    networkService = NetworkMonitorService(connectivity: fakeConnectivity);
  });

  tearDown(() {
    networkService.dispose();
    fakeConnectivity.dispose();
  });

  group('NetworkMonitorService (Task 49) Unit Tests', () {
    test('isOnlineFromResults evaluates connectivity combinations accurately', () {
      expect(NetworkMonitorService.isOnlineFromResults([ConnectivityResult.wifi]), isTrue);
      expect(NetworkMonitorService.isOnlineFromResults([ConnectivityResult.mobile]), isTrue);
      expect(NetworkMonitorService.isOnlineFromResults([ConnectivityResult.ethernet]), isTrue);
      expect(NetworkMonitorService.isOnlineFromResults([ConnectivityResult.vpn]), isTrue);
      expect(NetworkMonitorService.isOnlineFromResults([ConnectivityResult.other]), isTrue);
      expect(NetworkMonitorService.isOnlineFromResults([ConnectivityResult.none]), isFalse);
      expect(NetworkMonitorService.isOnlineFromResults([]), isFalse);
      expect(
        NetworkMonitorService.isOnlineFromResults([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });

    test('initializes with online status when connected to WiFi', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.wifi];
      networkService = NetworkMonitorService(connectivity: fakeConnectivity);

      expect(networkService.isInitialized, isFalse);
      await networkService.initialize();

      expect(networkService.isInitialized, isTrue);
      expect(networkService.isOnline, isTrue);
    });

    test('initializes with offline status when no connectivity', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.none];
      networkService = NetworkMonitorService(connectivity: fakeConnectivity);

      await networkService.initialize();

      expect(networkService.isInitialized, isTrue);
      expect(networkService.isOnline, isFalse);
    });

    test('emits connectivity changes via isOnlineStream', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.none];
      networkService = NetworkMonitorService(connectivity: fakeConnectivity);
      await networkService.initialize();

      final emittedStates = <bool>[];
      final subscription = networkService.isOnlineStream.listen(emittedStates.add);

      // Offline -> Online (WiFi)
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Online -> Offline (None)
      fakeConnectivity.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Offline -> Online (Cellular Mobile)
      fakeConnectivity.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emittedStates, [true, false, true]);
      expect(networkService.isOnline, isTrue);

      await subscription.cancel();
    });

    test('triggers sync callback specifically on offline to online transition', () async {
      int syncTriggerCount = 0;
      fakeConnectivity.currentResults = [ConnectivityResult.none];

      networkService = NetworkMonitorService(
        connectivity: fakeConnectivity,
        onSyncCallback: () async {
          syncTriggerCount++;
        },
      );
      await networkService.initialize();
      expect(syncTriggerCount, 0);

      // Transition 1: Offline -> Online (Triggers sync)
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncTriggerCount, 1);

      // Transition 2: Online -> Online (Switching from WiFi to Mobile, should NOT trigger sync)
      fakeConnectivity.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncTriggerCount, 1);

      // Transition 3: Online -> Offline (Disconnect, should NOT trigger sync)
      fakeConnectivity.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncTriggerCount, 1);

      // Transition 4: Offline -> Online (Reconnection, Triggers sync again)
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncTriggerCount, 2);
    });

    test('unregisterSyncCallback successfully removes callback', () async {
      int callbackCalls = 0;
      Future<void> callback() async => callbackCalls++;

      fakeConnectivity.currentResults = [ConnectivityResult.none];
      networkService = NetworkMonitorService(connectivity: fakeConnectivity);
      networkService.registerSyncCallback(callback);
      await networkService.initialize();

      // Trigger 1
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(callbackCalls, 1);

      // Unregister
      networkService.unregisterSyncCallback(callback);

      // Go offline then online again
      fakeConnectivity.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Count remains 1
      expect(callbackCalls, 1);
    });

    test('triggerSyncNow runs callbacks immediately when online', () async {
      int syncCount = 0;
      fakeConnectivity.currentResults = [ConnectivityResult.wifi];

      networkService = NetworkMonitorService(
        connectivity: fakeConnectivity,
        onSyncCallback: () async => syncCount++,
      );
      await networkService.initialize();

      await networkService.triggerSyncNow();
      expect(syncCount, 1);
    });

    test('triggerSyncNow does not run callbacks when offline', () async {
      int syncCount = 0;
      fakeConnectivity.currentResults = [ConnectivityResult.none];

      networkService = NetworkMonitorService(
        connectivity: fakeConnectivity,
        onSyncCallback: () async => syncCount++,
      );
      await networkService.initialize();

      await networkService.triggerSyncNow();
      expect(syncCount, 0);
    });

    test('error in one sync callback does not prevent subsequent callbacks from executing', () async {
      bool secondCallbackExecuted = false;

      fakeConnectivity.currentResults = [ConnectivityResult.none];
      networkService = NetworkMonitorService(
        connectivity: fakeConnectivity,
        onSyncCallback: () async {
          throw Exception('Sync failed network error');
        },
      );
      networkService.registerSyncCallback(() async {
        secondCallbackExecuted = true;
      });

      await networkService.initialize();

      // Offline -> Online transition
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(secondCallbackExecuted, isTrue);
    });
  });
}
