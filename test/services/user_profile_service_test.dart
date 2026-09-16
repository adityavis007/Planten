import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfileService (Task 26)', () {
    late LocalStorageService localStorage;
    late UserProfileService profileService;

    final testProfile = FarmerProfile(
      uid: 'farmer-101',
      phoneNumber: '+919876543210',
      name: 'Ramesh Patel',
      village: 'Kheda',
      district: 'Anand',
      state: 'Gujarat',
      primaryCrops: ['tomato', 'wheat'],
      photoBackupOptIn: false,
      createdAt: DateTime.utc(2026, 3, 1),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      localStorage = LocalStorageService(prefs: prefs);
      profileService = UserProfileService(
        localStorageService: localStorage,
      );
    });

    test('cachedProfile is null initially', () {
      expect(profileService.cachedProfile, isNull);
    });

    test('createOrUpdateProfile saves profile to local cache immediately', () async {
      final success = await profileService.createOrUpdateProfile(testProfile);
      expect(success, true);

      final cached = profileService.cachedProfile;
      expect(cached, isNotNull);
      expect(cached?.uid, 'farmer-101');
      expect(cached?.name, 'Ramesh Patel');
      expect(cached?.village, 'Kheda');
      expect(cached?.district, 'Anand');
      expect(cached?.primaryCrops, ['tomato', 'wheat']);
    });

    test('getProfile returns cached profile directly without network call', () async {
      await profileService.createOrUpdateProfile(testProfile);

      final fetched = await profileService.getProfile('farmer-101');
      expect(fetched, isNotNull);
      expect(fetched?.uid, 'farmer-101');
      expect(fetched?.name, 'Ramesh Patel');
    });

    test('getProfile returns null when requested uid does not match cached profile', () async {
      await profileService.createOrUpdateProfile(testProfile);

      final fetched = await profileService.getProfile('different-uid');
      expect(fetched, isNull);
    });

    test('clearCachedProfile removes profile from local cache', () async {
      await profileService.createOrUpdateProfile(testProfile);
      expect(profileService.cachedProfile, isNotNull);

      final cleared = await profileService.clearCachedProfile();
      expect(cleared, true);
      expect(profileService.cachedProfile, isNull);
    });

    test('operates safely and returns true for local save when Firestore is null/offline', () async {
      expect(profileService.firestoreOrNull, isNull);

      final saved = await profileService.createOrUpdateProfile(testProfile);
      expect(saved, true);

      final fetched = await profileService.getProfile('farmer-101');
      expect(fetched, isNotNull);
      expect(fetched?.name, 'Ramesh Patel');
    });
  });
}
