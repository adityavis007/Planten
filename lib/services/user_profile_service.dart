import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/farmer_profile.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';

/// Service managing CRUD operations for [FarmerProfile] data in Cloud Firestore (`farmers/{uid}`)
/// with dual-layer caching in [LocalStorageService] for offline-first resilience and Spark free-tier optimization.
class UserProfileService {
  static const String collectionPath = 'farmers';

  FirebaseFirestore? _firestore;
  final LocalStorageService _localStorageService;

  /// Creates a [UserProfileService] with optional injected dependencies for testing.
  UserProfileService({
    FirebaseFirestore? firestore,
    LocalStorageService? localStorageService,
  }) : _localStorageService = localStorageService ?? LocalStorageService() {
    _firestore = firestore;
  }

  /// Returns active [FirebaseFirestore] instance from injection, [FirebaseService], or null if offline.
  FirebaseFirestore? get firestoreOrNull {
    if (_firestore != null) return _firestore;
    if (FirebaseService.instance.isAvailable) {
      return FirebaseService.instance.firestore;
    }
    return null;
  }

  /// Synchronously returns the currently cached [FarmerProfile] from local storage.
  FarmerProfile? get cachedProfile => _localStorageService.getUserProfile();

  /// Saves or updates the farmer profile.
  ///
  /// Always persists to [LocalStorageService] immediately for instant offline responsiveness.
  /// If [syncToRemote] is true and Firestore is available, writes to `farmers/{uid}` with merge.
  Future<bool> createOrUpdateProfile(
    FarmerProfile profile, {
    bool syncToRemote = true,
  }) async {
    // 1. Immediately cache in local storage
    await _localStorageService.init();
    final localSuccess = await _localStorageService.saveUserProfile(profile);

    // 2. Sync to Cloud Firestore if requested and available
    if (syncToRemote) {
      final client = firestoreOrNull;
      if (client != null) {
        try {
          final docRef = client.collection(collectionPath).doc(profile.uid);
          await docRef.set(profile.toMap(), SetOptions(merge: true));
          debugPrint('UserProfileService: Profile synced to Cloud Firestore for UID: ${profile.uid}');
        } catch (e) {
          debugPrint('UserProfileService: Cloud Firestore write failed ($e). Preserved in local cache.');
        }
      }
    }

    return localSuccess;
  }

  /// Retrieves the farmer profile by [uid].
  ///
  /// Optimization for Spark Free Tier:
  /// - Unless [forceRemote] is true, checks local cache first. If a cached profile
  ///   exists matching [uid], returns it immediately with zero Firestore read cost.
  /// - If not in cache or [forceRemote] is true, queries Firestore `farmers/{uid}`
  ///   and updates local cache upon receipt.
  Future<FarmerProfile?> getProfile(
    String uid, {
    bool forceRemote = false,
  }) async {
    await _localStorageService.init();

    // 1. Check local cache first unless forced remote
    if (!forceRemote) {
      final cached = _localStorageService.getUserProfile();
      if (cached != null && cached.uid == uid) {
        return cached;
      }
    }

    // 2. Fetch from Firestore if available
    final client = firestoreOrNull;
    if (client != null) {
      try {
        final docRef = client.collection(collectionPath).doc(uid);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final profile = FarmerProfile.fromMap(docSnapshot.data()!);
          // Refresh local cache
          await _localStorageService.saveUserProfile(profile);
          return profile;
        }
      } catch (e) {
        debugPrint('UserProfileService: Error fetching profile from Firestore ($e).');
      }
    }

    // 3. Fallback: if remote fetch failed or returned null, return local cache if matching
    final fallbackCached = _localStorageService.getUserProfile();
    if (fallbackCached != null && fallbackCached.uid == uid) {
      return fallbackCached;
    }

    return null;
  }

  /// Clears the cached user profile from local storage (e.g. during logout).
  Future<bool> clearCachedProfile() async {
    await _localStorageService.init();
    return _localStorageService.clearUserProfile();
  }
}
