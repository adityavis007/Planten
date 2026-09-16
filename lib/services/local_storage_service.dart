import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnosis_result.dart';
import '../models/farmer_profile.dart';
import '../models/weather_data.dart';

/// Service providing local offline persistence for active crop, farmer profile, scan results, and weather.
class LocalStorageService {
  static const String _keySelectedCrop = 'planten_selected_crop_id';
  static const String _keyUserProfile = 'planten_user_profile_json';
  static const String _keyOfflineScans = 'planten_offline_scans_json';
  static const String _keyDeletedScanIds = 'planten_deleted_scan_ids_json';
  static const String _keyCachedWeather = 'planten_cached_weather_json';

  SharedPreferences? _prefs;

  LocalStorageService({SharedPreferences? prefs}) {
    _prefs = prefs;
  }

  /// Initializes the underlying [SharedPreferences] instance.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Crop Selection Persistence ---

  /// Persists the active crop ID (e.g. `'tomato'`).
  Future<bool> saveSelectedCrop(String cropId) async {
    final prefs = await _ensurePrefs();
    return prefs.setString(_keySelectedCrop, cropId);
  }

  /// Retrieves the persisted crop ID, or null if not yet selected.
  String? getSelectedCrop() {
    return _prefs?.getString(_keySelectedCrop);
  }

  // --- Farmer Profile Persistence ---

  /// Persists the farmer profile as a cached JSON string.
  Future<bool> saveUserProfile(FarmerProfile profile) async {
    final prefs = await _ensurePrefs();
    final jsonStr = jsonEncode(profile.toMap());
    return prefs.setString(_keyUserProfile, jsonStr);
  }

  /// Retrieves and deserializes the cached [FarmerProfile], or null if none exists.
  FarmerProfile? getUserProfile() {
    final jsonStr = _prefs?.getString(_keyUserProfile);
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FarmerProfile.fromMap(map);
    } catch (e) {
      debugPrint('Error decoding cached FarmerProfile: $e');
      return null;
    }
  }

  /// Removes the cached user profile (e.g. on logout).
  Future<bool> clearUserProfile() async {
    final prefs = await _ensurePrefs();
    return prefs.remove(_keyUserProfile);
  }

  // --- Offline Scans Cache ---

  /// Persists a list of offline [DiagnosisResult] scans.
  Future<bool> saveOfflineScans(List<DiagnosisResult> scans) async {
    final prefs = await _ensurePrefs();
    final jsonList = scans.map((s) => s.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    return prefs.setString(_keyOfflineScans, jsonStr);
  }

  /// Retrieves all cached offline [DiagnosisResult] scans ordered by timestamp descending.
  List<DiagnosisResult> getOfflineScans() {
    final jsonStr = _prefs?.getString(_keyOfflineScans);
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];

      final scans = decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => DiagnosisResult.fromJson(item))
          .toList();

      // Sort newest first
      scans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return scans;
    } catch (e) {
      debugPrint('Error decoding cached offline scans: $e');
      return [];
    }
  }

  /// Appends or updates a scan in the offline scan list.
  Future<bool> addOfflineScan(DiagnosisResult scan) async {
    final currentScans = getOfflineScans();
    final index = currentScans.indexWhere((s) => s.id == scan.id);

    if (index >= 0) {
      currentScans[index] = scan;
    } else {
      currentScans.insert(0, scan);
    }

    return saveOfflineScans(currentScans);
  }

  /// Removes a scan with the given [scanId] from offline storage.
  Future<bool> deleteOfflineScan(String scanId) async {
    final currentScans = getOfflineScans();
    currentScans.removeWhere((s) => s.id == scanId);
    return saveOfflineScans(currentScans);
  }

  // --- Deleted Scans Tombstones (Prevents Cloud Resurrections) ---

  /// Records a scanId into the tombstone set of deleted scans.
  Future<bool> markScanAsDeleted(String scanId) async {
    final deleted = getDeletedScanIds().toSet();
    deleted.add(scanId);
    final prefs = await _ensurePrefs();
    return prefs.setStringList(_keyDeletedScanIds, deleted.toList());
  }

  /// Retrieves the list of scan IDs that have been marked as deleted locally.
  List<String> getDeletedScanIds() {
    return _prefs?.getStringList(_keyDeletedScanIds) ?? [];
  }

  /// Removes a scanId from the tombstone set once permanently purged from cloud.
  Future<bool> unmarkScanAsDeleted(String scanId) async {
    final deleted = getDeletedScanIds().toSet();
    deleted.remove(scanId);
    final prefs = await _ensurePrefs();
    return prefs.setStringList(_keyDeletedScanIds, deleted.toList());
  }

  /// Clears the tombstone set.
  Future<bool> clearDeletedScanIds() async {
    final prefs = await _ensurePrefs();
    return prefs.remove(_keyDeletedScanIds);
  }

  // --- Real-time Weather Cache ---

  /// Persists the last-known [WeatherData] object to local storage.
  Future<bool> saveCachedWeather(WeatherData weather) async {
    final prefs = await _ensurePrefs();
    final jsonStr = jsonEncode(weather.toJson());
    return prefs.setString(_keyCachedWeather, jsonStr);
  }

  /// Retrieves and deserializes the cached [WeatherData], or returns null if none exists.
  WeatherData? getCachedWeather() {
    final jsonStr = _prefs?.getString(_keyCachedWeather);
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = WeatherData.fromJson(map);
      return data.copyWith(isFromCache: true);
    } catch (e) {
      debugPrint('Error decoding cached WeatherData: $e');
      return null;
    }
  }

  /// Clears the cached weather data.
  Future<bool> clearCachedWeather() async {
    final prefs = await _ensurePrefs();
    return prefs.remove(_keyCachedWeather);
  }

  /// Clears all Planten cached data from local storage.
  Future<bool> clearAll() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_keySelectedCrop);
    await prefs.remove(_keyUserProfile);
    await prefs.remove(_keyOfflineScans);
    await prefs.remove(_keyCachedWeather);
    return true;
  }
}
