import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/farmer_profile.dart';
import '../models/weather_data.dart';
import 'local_storage_service.dart';

/// Typed callback signature for custom location resolution (useful for testing or platform mocks).
typedef PositionResolver = Future<Position?> Function();

/// Service providing real-time weather forecasts via Open-Meteo API (100% free, no API key).
///
/// Features:
/// - Fetches real-time temperature, humidity, wind speed, rain chance, and WMO condition codes.
/// - Prioritizes device GPS coordinates, with graceful fallback to farmer profile district/state.
/// - Caches last-known weather in [LocalStorageService] for offline-first reliability.
class WeatherService {
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  /// Standard fallback coordinates for major Indian states and agricultural districts.
  static const Map<String, (double, double)> indianRegionCoordinates = {
    'punjab': (30.9010, 75.8573),
    'patiala': (30.3398, 76.3869),
    'ludhiana': (30.9010, 75.8573),
    'amritsar': (31.6340, 74.8723),
    'jalandhar': (31.3260, 75.5762),
    'bathinda': (30.2110, 74.9455),
    'uttar pradesh': (26.8467, 80.9462),
    'varanasi': (25.3176, 82.9739),
    'lucknow': (26.8467, 80.9462),
    'kanpur': (26.4499, 80.3319),
    'agra': (27.1767, 78.0081),
    'prayagraj': (25.4358, 81.8463),
    'gorakhpur': (26.7606, 83.3732),
    'haryana': (29.0588, 76.0856),
    'karnal': (29.6857, 76.9905),
    'hisar': (29.1492, 75.7217),
    'ambala': (30.3782, 76.7767),
    'madhya pradesh': (22.9734, 78.6569),
    'indore': (22.7196, 75.8577),
    'bhopal': (23.2599, 77.4126),
    'rajasthan': (27.0238, 74.2179),
    'jaipur': (26.9124, 75.7873),
    'kota': (25.2138, 75.8648),
    'maharashtra': (19.7515, 75.7139),
    'pune': (18.5204, 73.8567),
    'nashik': (19.9975, 73.7898),
    'nagpur': (21.1458, 79.0882),
    'bihar': (25.0961, 85.3131),
    'patna': (25.5941, 85.1376),
    'gujarat': (22.2587, 71.1924),
    'ahmedabad': (23.0225, 72.5714),
    'surat': (21.1702, 72.8311),
    'delhi': (28.6139, 77.2090),
    'new delhi': (28.6139, 77.2090),
  };

  final http.Client _client;
  final LocalStorageService? localStorageService;
  final PositionResolver? positionResolver;

  WeatherService({
    http.Client? client,
    this.localStorageService,
    this.positionResolver,
  })  : _client = client ?? http.Client();

  /// Fetches real-time weather information from Open-Meteo.
  ///
  /// Resolves location through:
  /// 1. Explicit [latitude] and [longitude] if provided.
  /// 2. Device GPS coordinates via [Geolocator].
  /// 3. Farmer profile district/state geocoded via Open-Meteo Geocoding.
  /// 4. Built-in regional coordinates lookup table.
  ///
  /// When network is unavailable, returns cached data from [LocalStorageService]
  /// with [WeatherData.isFromCache] set to `true`.
  Future<WeatherData> fetchWeather({
    FarmerProfile? profile,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // 1. Resolve Location Coordinates
    final locationInfo = await _resolveLocation(
      profile: profile,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    final lat = locationInfo.lat;
    final lon = locationInfo.lon;
    final resolvedLocationName = locationInfo.name;

    final uri = Uri.parse(
      '$_forecastBaseUrl?latitude=${lat.toStringAsFixed(4)}&longitude=${lon.toStringAsFixed(4)}'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation,is_day'
      '&hourly=temperature_2m,precipitation_probability,weather_code'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max'
      '&timezone=auto',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw http.ClientException(
          'Open-Meteo returned status ${response.statusCode}: ${response.body}',
          uri,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = (json['current'] as Map<String, dynamic>?) ?? {};
      final daily = (json['daily'] as Map<String, dynamic>?) ?? {};
      final hourly = (json['hourly'] as Map<String, dynamic>?) ?? {};

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
      final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
      final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
      final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final isDay = (current['is_day'] as num?)?.toInt() ?? 1;

      // Extract precipitation probability from daily max or fallback to 0
      int rainProb = 0;
      final dailyRainProb = daily['precipitation_probability_max'];
      if (dailyRainProb is List && dailyRainProb.isNotEmpty) {
        rainProb = (dailyRainProb.first as num?)?.toInt() ?? 0;
      }

      // Extract today's min and max temperatures
      double? tempMin;
      final dailyMins = daily['temperature_2m_min'];
      if (dailyMins is List && dailyMins.isNotEmpty) {
        tempMin = (dailyMins.first as num?)?.toDouble();
      }

      double? tempMax;
      final dailyMaxs = daily['temperature_2m_max'];
      if (dailyMaxs is List && dailyMaxs.isNotEmpty) {
        tempMax = (dailyMaxs.first as num?)?.toDouble();
      }

      double? uvIndex;
      final dailyUv = daily['uv_index_max'];
      if (dailyUv is List && dailyUv.isNotEmpty) {
        uvIndex = (dailyUv.first as num?)?.toDouble();
      }

      // Parse next 24 hours
      final now = DateTime.now();
      final hourlyList = <HourlyForecastItem>[];
      final hourlyTimes = (hourly['time'] as List<dynamic>?) ?? [];
      final hourlyTemps = (hourly['temperature_2m'] as List<dynamic>?) ?? [];
      final hourlyRainProbs = (hourly['precipitation_probability'] as List<dynamic>?) ?? [];
      final hourlyCodes = (hourly['weather_code'] as List<dynamic>?) ?? [];

      int startIndex = 0;
      for (int i = 0; i < hourlyTimes.length; i++) {
        final t = DateTime.tryParse(hourlyTimes[i].toString());
        if (t != null && (t.isAfter(now.subtract(const Duration(minutes: 59))) || i == hourlyTimes.length - 1)) {
          startIndex = i;
          break;
        }
      }

      final endIndex = (startIndex + 24).clamp(0, hourlyTimes.length);
      for (int i = startIndex; i < endIndex; i++) {
        final t = DateTime.tryParse(hourlyTimes[i].toString()) ?? now.add(Duration(hours: i - startIndex));
        final tTemp = (hourlyTemps.length > i ? (hourlyTemps[i] as num?)?.toDouble() : null) ?? temp;
        final tProb = (hourlyRainProbs.length > i ? (hourlyRainProbs[i] as num?)?.toInt() : null) ?? 0;
        final tCode = (hourlyCodes.length > i ? (hourlyCodes[i] as num?)?.toInt() : null) ?? weatherCode;

        hourlyList.add(
          HourlyForecastItem(
            time: t,
            temperature: tTemp,
            rainProbability: tProb,
            weatherCode: tCode,
            icon: WeatherConditionHelper.getIcon(tCode),
          ),
        );
      }

      // Parse 7-day daily forecast
      final dailyList = <DailyForecastItem>[];
      final dailyTimes = (daily['time'] as List<dynamic>?) ?? [];
      final dailyCodes = (daily['weather_code'] as List<dynamic>?) ?? [];
      final weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weekdaysHi = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];

      final dailyCount = [
        dailyTimes.length,
        dailyCodes.length,
        (dailyMaxs is List ? dailyMaxs.length : 0),
        (dailyMins is List ? dailyMins.length : 0),
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < dailyCount.clamp(0, 7); i++) {
        final dDate = DateTime.tryParse(dailyTimes[i].toString()) ?? now.add(Duration(days: i));
        final dMin = (dailyMins[i] as num?)?.toDouble() ?? 0.0;
        final dMax = (dailyMaxs[i] as num?)?.toDouble() ?? 0.0;
        final dCode = (dailyCodes[i] as num?)?.toInt() ?? 0;
        final dProb = (dailyRainProb is List && dailyRainProb.length > i)
            ? (dailyRainProb[i] as num?)?.toInt() ?? 0
            : 0;

        final weekdayIdx = (dDate.weekday - 1).clamp(0, 6);
        final dayEn = i == 0 ? 'Today' : weekdaysEn[weekdayIdx];
        final dayHi = i == 0 ? 'आज' : weekdaysHi[weekdayIdx];

        dailyList.add(
          DailyForecastItem(
            date: dDate,
            dayNameEn: dayEn,
            dayNameHi: dayHi,
            minTemp: dMin,
            maxTemp: dMax,
            weatherCode: dCode,
            rainProbability: dProb,
            icon: WeatherConditionHelper.getIcon(dCode),
          ),
        );
      }

      final weatherData = WeatherData.fromWmoCode(
        temperature: temp,
        weatherCode: weatherCode,
        humidity: humidity,
        windSpeed: windSpeed,
        rainProbability: rainProb,
        locationName: resolvedLocationName,
        lastUpdated: DateTime.now(),
        isFromCache: false,
        isDay: isDay,
        tempMin: tempMin,
        tempMax: tempMax,
        feelsLike: temp,
        uvIndex: uvIndex,
        hourlyForecast: hourlyList,
        dailyForecast: dailyList,
      );

      // Persist to local offline cache
      final storage = localStorageService;
      if (storage != null) {
        await storage.saveCachedWeather(weatherData);
      }

      return weatherData;
    } catch (e) {
      debugPrint('WeatherService: Network fetch failed: $e. Falling back to cache...');

      // Attempt offline cache retrieval
      final storage = localStorageService;
      if (storage != null) {
        final cached = storage.getCachedWeather();
        if (cached != null) {
          return cached.copyWith(isFromCache: true);
        }
      }

      // If no cache exists, rethrow to let provider handle UI error state
      rethrow;
    }
  }

  /// Resolves the most accurate coordinates and location name available.
  Future<({double lat, double lon, String name})> _resolveLocation({
    FarmerProfile? profile,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    // A. Explicit coordinates supplied
    if (latitude != null && longitude != null) {
      final name = locationName ?? 'Current Location';
      return (lat: latitude, lon: longitude, name: name);
    }

    // B. Device Location Resolution
    try {
      Position? position;
      final customResolver = positionResolver;
      if (customResolver != null) {
        position = await customResolver();
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            position = await Geolocator.getLastKnownPosition();
            position ??= await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 4),
              ),
            );
          }
        }
      }

      if (position != null) {
        final name = locationName ?? 'Current Location';
        return (lat: position.latitude, lon: position.longitude, name: name);
      }
    } catch (e) {
      debugPrint('WeatherService: Device location error or skipped: $e');
    }

    // C. Fallback to Farmer Profile District/State Geocoding
    if (profile != null) {
      final district = profile.district.trim();
      final state = profile.state.trim();
      final targetQuery = district.isNotEmpty ? district : state;

      if (targetQuery.isNotEmpty) {
        // Try Open-Meteo Geocoding
        final geocoded = await _geocodeQuery(targetQuery);
        if (geocoded != null) {
          final display = locationName ?? 'Current Location';
          return (lat: geocoded.lat, lon: geocoded.lon, name: display);
        }

        // Try Static Regional Table
        final staticCoords = _lookupStaticCoords(district) ?? _lookupStaticCoords(state);
        if (staticCoords != null) {
          return (
            lat: staticCoords.$1,
            lon: staticCoords.$2,
            name: locationName ?? 'Current Location',
          );
        }
      }
    }

    // D. Static Default (Central / New Delhi)
    return (
      lat: 28.6139,
      lon: 77.2090,
      name: locationName ?? 'Current Location',
    );
  }

  /// Queries the Open-Meteo free geocoding API to obtain coordinates for a city or district.
  Future<({double lat, double lon, String name})?> _geocodeQuery(String query) async {
    try {
      final uri = Uri.parse(
        '$_geocodingBaseUrl?name=${Uri.encodeComponent(query)}&count=1&language=en&format=json',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final lat = (first['latitude'] as num?)?.toDouble();
          final lon = (first['longitude'] as num?)?.toDouble();
          final name = (first['name'] as String?) ?? query;

          if (lat != null && lon != null) {
            return (lat: lat, lon: lon, name: name);
          }
        }
      }
    } catch (e) {
      debugPrint('WeatherService: Geocoding failed for "$query": $e');
    }
    return null;
  }

  /// Looks up coordinates from the built-in regional table.
  (double, double)? _lookupStaticCoords(String query) {
    final normalized = query.toLowerCase().trim();
    return indianRegionCoordinates[normalized];
  }
}
