import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/config/firebase_options.dart';
import 'package:planten/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DefaultFirebaseOptions (Task 24)', () {
    test('provides accurate credentials for Planten project', () {
      final android = DefaultFirebaseOptions.android;
      expect(android.projectId, 'planten-16301');
      expect(android.messagingSenderId, '504521081852');
      expect(android.storageBucket, 'planten-16301.firebasestorage.app');
      expect(android.appId, '1:504521081852:android:0a433c03a22c2579256879');
      expect(android.apiKey, 'AIzaSyAaGf9SbdFROmrPV5_A-xiW15axSXvT4KQ');
    });

    test('currentPlatform returns valid configuration', () {
      final options = DefaultFirebaseOptions.currentPlatform;
      expect(options.projectId, 'planten-16301');
      expect(options.apiKey.isNotEmpty, true);
    });
  });

  group('FirebaseService (Task 24)', () {
    late FirebaseService service;

    setUp(() {
      service = FirebaseService();
    });

    test('initializes with unready state by default', () {
      expect(service.isInitialized, false);
      expect(service.isAvailable, false);
      expect(service.initializationError, isNull);
      expect(service.firestore, isNull);
      expect(service.auth, isNull);
      expect(service.app, isNull);
    });

    test('gracefully falls back to offline mode when native channels are missing', () async {
      // In headless unit test environments, native Firebase channel throws MissingPluginException or similar.
      // FirebaseService must catch this and return false without throwing an unhandled exception.
      final result = await service.initialize();

      expect(result, false);
      expect(service.isInitialized, true);
      expect(service.isAvailable, false);
      expect(service.initializationError, isNotNull);
      expect(service.firestore, isNull);
      expect(service.auth, isNull);
    });

    test('singleton instance returns the same reference', () {
      final instance1 = FirebaseService.instance;
      final instance2 = FirebaseService.instance;
      expect(identical(instance1, instance2), true);
    });

    test('resetForTesting clears service state completely', () async {
      await service.initialize();
      expect(service.isInitialized, true);

      service.resetForTesting();
      expect(service.isInitialized, false);
      expect(service.isAvailable, false);
      expect(service.initializationError, isNull);
    });
  });
}
