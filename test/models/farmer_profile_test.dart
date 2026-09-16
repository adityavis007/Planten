import 'package:flutter_test/flutter_test.dart';
import 'package:planten/models/farmer_profile.dart';

class _FakeFirestoreTimestamp {
  final DateTime dateTime;
  _FakeFirestoreTimestamp(this.dateTime);
  DateTime toDate() => dateTime;
}

void main() {
  group('FarmerProfile Model (Task 14)', () {
    final now = DateTime.utc(2026, 9, 9, 10, 30, 0);
    final updated = DateTime.utc(2026, 9, 9, 11, 0, 0);

    final profile = FarmerProfile(
      uid: 'user-abc-123',
      phoneNumber: '+919876543210',
      name: 'Ramesh Patel',
      village: 'Rampur',
      district: 'Varanasi',
      state: 'Uttar Pradesh',
      primaryCrops: const ['tomato', 'wheat'],
      photoBackupOptIn: false,
      createdAt: now,
      updatedAt: updated,
    );

    test('serializes toMap/toJson and deserializes back identically', () {
      final map = profile.toMap();
      final fromMap = FarmerProfile.fromMap(map);

      expect(fromMap, equals(profile));
      expect(fromMap.uid, 'user-abc-123');
      expect(fromMap.phoneNumber, '+919876543210');
      expect(fromMap.name, 'Ramesh Patel');
      expect(fromMap.village, 'Rampur');
      expect(fromMap.district, 'Varanasi');
      expect(fromMap.state, 'Uttar Pradesh');
      expect(fromMap.primaryCrops, ['tomato', 'wheat']);
      expect(fromMap.photoBackupOptIn, isFalse);
      expect(fromMap.createdAt, now);
      expect(fromMap.updatedAt, updated);
    });

    test('enforces PRD privacy requirement: photoBackupOptIn defaults to false', () {
      final defaultProfile = FarmerProfile(
        uid: 'user-001',
        phoneNumber: '+919999999999',
        name: 'Sita Devi',
        village: 'Kisanpur',
        district: 'Meerut',
        state: 'Uttar Pradesh',
        createdAt: now,
      );

      expect(defaultProfile.photoBackupOptIn, isFalse);

      final map = defaultProfile.toMap();
      expect(map['photo_backup_opt_in'], isFalse);
    });

    test('handles camelCase and alternative timestamp formats', () {
      final camelMap = {
        'uid': 'user-camel',
        'phoneNumber': '+918888888888',
        'name': 'Anita Singh',
        'village': 'Chandpur',
        'district': 'Patna',
        'state': 'Bihar',
        'primaryCrops': ['potato', 'chili'],
        'photoBackupOptIn': true,
        'createdAt': '2026-09-09T10:30:00.000Z',
      };

      final fromCamel = FarmerProfile.fromMap(camelMap);
      expect(fromCamel.uid, 'user-camel');
      expect(fromCamel.phoneNumber, '+918888888888');
      expect(fromCamel.name, 'Anita Singh');
      expect(fromCamel.primaryCrops, ['potato', 'chili']);
      expect(fromCamel.photoBackupOptIn, isTrue);
      expect(fromCamel.createdAt, DateTime.utc(2026, 9, 9, 10, 30, 0));
    });

    test('handles fake Firestore Timestamp objects gracefully', () {
      final firestoreMap = {
        'uid': 'user-firestore',
        'phone_number': '+917777777777',
        'name': 'Gopal Kumar',
        'village': 'Sonpur',
        'district': 'Saran',
        'state': 'Bihar',
        'primary_crops': ['cotton'],
        'created_at': _FakeFirestoreTimestamp(now),
      };

      final profileFromFirestore = FarmerProfile.fromMap(firestoreMap);
      expect(profileFromFirestore.createdAt, now);
      expect(profileFromFirestore.primaryCrops, ['cotton']);
    });

    test('formats locationDisplay cleanly', () {
      expect(profile.locationDisplay, 'Rampur, Varanasi, Uttar Pradesh');

      final partialProfile = FarmerProfile(
        uid: 'user-partial',
        phoneNumber: '+919000000000',
        name: 'Vikram',
        village: 'Rampur',
        district: 'Varanasi',
        state: '',
        createdAt: now,
      );
      expect(partialProfile.locationDisplay, 'Rampur, Varanasi');
    });

    test('checks isProfileComplete', () {
      expect(profile.isProfileComplete, isTrue);

      final incomplete = profile.copyWith(village: '   ');
      expect(incomplete.isProfileComplete, isFalse);
    });

    test('copyWith creates modified clone', () {
      final modified = profile.copyWith(
        name: 'Ramesh Kumar Patel',
        photoBackupOptIn: true,
        primaryCrops: ['wheat'],
        profilePhotoPath: '/data/user/0/com.planten/app_flutter/profile.jpg',
      );

      expect(modified.name, 'Ramesh Kumar Patel');
      expect(modified.photoBackupOptIn, isTrue);
      expect(modified.primaryCrops, ['wheat']);
      expect(modified.uid, profile.uid);
      expect(modified.village, profile.village);
      expect(modified.profilePhotoPath, '/data/user/0/com.planten/app_flutter/profile.jpg');
    });

    test('serializes and deserializes profilePhotoPath correctly', () {
      final profileWithPhoto = profile.copyWith(
        profilePhotoPath: '/storage/emulated/0/Pictures/profile.jpg',
      );
      final map = profileWithPhoto.toMap();
      expect(map['profile_photo_path'], '/storage/emulated/0/Pictures/profile.jpg');

      final fromSnake = FarmerProfile.fromMap(map);
      expect(fromSnake.profilePhotoPath, '/storage/emulated/0/Pictures/profile.jpg');

      final fromCamel = FarmerProfile.fromMap({
        ...map,
        'profilePhotoPath': '/storage/emulated/0/Pictures/camel.jpg',
      }..remove('profile_photo_path'));
      expect(fromCamel.profilePhotoPath, '/storage/emulated/0/Pictures/camel.jpg');
    });
  });
}
