import 'package:flutter/foundation.dart';

import '../models/farmer_profile.dart';
import '../models/weather_data.dart';
import '../services/local_storage_service.dart';
import '../services/weather_service.dart';

/// State management provider for real-time agricultural weather conditions.
///
/// Features:
/// - Reactive state for [weatherData], [isLoading], and [errorMessage].
/// - Instant offline rendering using cached weather from [LocalStorageService].
/// - Seamless background refreshes with zero UI flicker.
class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService;
  final LocalStorageService? _localStorageService;

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _weatherData?.isFromCache ?? false;
  bool get hasData => _weatherData != null;

  WeatherProvider({
    WeatherService? weatherService,
    LocalStorageService? localStorageService,
    bool autoFetch = false,
    FarmerProfile? initialProfile,
  }) : _weatherService =
           weatherService ??
           WeatherService(localStorageService: localStorageService),
       _localStorageService = localStorageService {
    // 1. Instantly restore last-known weather from offline cache
    _restoreFromCache();

    // 2. Fetch fresh weather in background if requested
    if (autoFetch) {
      fetchWeather(profile: initialProfile);
    }
  }

  /// Instantly loads cached weather from storage without triggering a network request.
  void _restoreFromCache() {
    if (_localStorageService != null) {
      final cached = _localStorageService.getCachedWeather();
      if (cached != null) {
        _weatherData = cached;
        _errorMessage = null;
        notifyListeners();
      }
    }
  }

  /// Fetches real-time weather from Open-Meteo.
  ///
  /// If [forceRefresh] is false and weather data is already present, avoids redundant calls.
  Future<void> fetchWeather({
    FarmerProfile? profile,
    bool forceRefresh = false,
    double? latitude,
    double? longitude,
  }) async {
    if (_isLoading) return;

    // If we already have fresh data and forceRefresh is false, keep it
    if (!forceRefresh && _weatherData != null && !_weatherData!.isFromCache) {
      final diff = DateTime.now().difference(_weatherData!.lastUpdated);
      // Data less than 30 minutes old is considered fresh
      if (diff.inMinutes < 30) {
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _weatherService.fetchWeather(
        profile: profile,
        latitude: latitude,
        longitude: longitude,
      );
      _weatherData = data;
      _errorMessage = null;
    } catch (e) {
      debugPrint('WeatherProvider: Fetch error: $e');
      // If we don't already have cached data loaded, set error message
      if (_weatherData == null) {
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Forces a fresh weather update from Open-Meteo.
  Future<void> refreshWeather({FarmerProfile? profile}) async {
    return fetchWeather(profile: profile, forceRefresh: true);
  }

  /// Manually sets weather data (convenient for widget tests).
  @visibleForTesting
  void setWeatherDataForTesting(WeatherData? data) {
    _weatherData = data;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Manually sets loading state (convenient for widget tests).
  @visibleForTesting
  void setLoadingForTesting(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Manually sets error message (convenient for widget tests).
  @visibleForTesting
  void setErrorForTesting(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
}
