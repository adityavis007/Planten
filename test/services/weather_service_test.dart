import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/models/weather_data.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/weather_service.dart';

class FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.fromIterable([response.bodyBytes]),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late SharedPreferences prefs;

  final sampleProfile = FarmerProfile(
    uid: 'farmer-123',
    phoneNumber: '+919876543210',
    name: 'Gurpreet Singh',
    village: 'Nabha',
    district: 'Patiala',
    state: 'Punjab',
    primaryCrops: ['wheat'],
    photoBackupOptIn: false,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    storage = LocalStorageService(prefs: prefs);
  });

  group('WeatherService Unit Tests', () {
    test('fetches weather forecast successfully and parses Open-Meteo payload', () async {
      final fakeClient = FakeHttpClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          final payload = {
            'current': {
              'temperature_2m': 29.4,
              'relative_humidity_2m': 62,
              'weather_code': 1,
              'wind_speed_10m': 14.8,
              'precipitation': 0.0,
            },
            'daily': {
              'precipitation_probability_max': [10, 20, 0],
            },
          };
          return http.Response(jsonEncode(payload), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = WeatherService(
        client: fakeClient,
        localStorageService: storage,
      );

      final result = await service.fetchWeather(
        profile: sampleProfile,
        latitude: 30.3398,
        longitude: 76.3869,
        locationName: 'Patiala, Punjab',
      );

      expect(result.temperature, 29.4);
      expect(result.humidity, 62);
      expect(result.weatherCode, 1);
      expect(result.windSpeed, 14.8);
      expect(result.rainProbability, 10);
      expect(result.locationName, 'Patiala, Punjab');
      expect(result.conditionTextEn, 'Mainly Clear');
      expect(result.conditionTextHi, 'मुख्यतः साफ़');
      expect(result.isFromCache, isFalse);

      // Verify cached in LocalStorageService
      final cached = storage.getCachedWeather();
      expect(cached, isNotNull);
      expect(cached!.temperature, 29.4);
      expect(cached.isFromCache, isTrue);
    });

    test('falls back to cached weather from LocalStorageService when network throws', () async {
      // Pre-populate cache
      final existing = WeatherData.fromWmoCode(
        temperature: 26.0,
        weatherCode: 0,
        humidity: 50,
        windSpeed: 10.0,
        rainProbability: 0,
        locationName: 'Patiala, Punjab',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await storage.saveCachedWeather(existing);

      final failingClient = FakeHttpClient((request) async {
        throw http.ClientException('Network down');
      });

      final service = WeatherService(
        client: failingClient,
        localStorageService: storage,
      );

      final result = await service.fetchWeather(
        profile: sampleProfile,
        latitude: 30.3398,
        longitude: 76.3869,
      );

      expect(result.temperature, 26.0);
      expect(result.isFromCache, isTrue);
    });

    test('geocodes farmer district and retrieves regional weather', () async {
      final fakeClient = FakeHttpClient((request) async {
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          final geoResponse = {
            'results': [
              {
                'name': 'Patiala',
                'latitude': 30.3398,
                'longitude': 76.3869,
              }
            ]
          };
          return http.Response(jsonEncode(geoResponse), 200);
        } else if (request.url.host == 'api.open-meteo.com') {
          final forecastResponse = {
            'current': {
              'temperature_2m': 31.0,
              'relative_humidity_2m': 40,
              'weather_code': 0,
              'wind_speed_10m': 11.5,
              'precipitation': 0.0,
            },
            'daily': {
              'precipitation_probability_max': [5],
            },
          };
          return http.Response(jsonEncode(forecastResponse), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = WeatherService(
        client: fakeClient,
        localStorageService: storage,
      );

      final result = await service.fetchWeather(profile: sampleProfile);

      expect(result.temperature, 31.0);
      expect(result.weatherCode, 0);
      expect(result.conditionTextEn, 'Clear Sky');
    });

    test('uses static Indian coordinates fallback when geocoding and device GPS fail', () async {
      final fakeClient = FakeHttpClient((request) async {
        // Geocoding fails
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          return http.Response('{"results":[]}', 200);
        }
        // Forecast succeeds for static coordinates
        if (request.url.host == 'api.open-meteo.com') {
          final forecastResponse = {
            'current': {
              'temperature_2m': 27.5,
              'relative_humidity_2m': 55,
              'weather_code': 3,
              'wind_speed_10m': 9.0,
            },
            'daily': {
              'precipitation_probability_max': [25],
            },
          };
          return http.Response(jsonEncode(forecastResponse), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = WeatherService(
        client: fakeClient,
        localStorageService: storage,
      );

      final profileWithKnownDistrict = sampleProfile.copyWith(district: 'Varanasi', state: 'Uttar Pradesh');
      final result = await service.fetchWeather(profile: profileWithKnownDistrict);

      expect(result.temperature, 27.5);
      expect(result.conditionTextEn, 'Overcast');
      expect(result.conditionTextHi, 'घने बादल');
    });

    test('parses extended hourly next-24-hours, daily 7-day, and spray advisory metrics', () async {
      final fakeClient = FakeHttpClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          final now = DateTime.now();
          final hourlyTimes = List.generate(30, (i) => now.add(Duration(hours: i)).toIso8601String());
          final dailyTimes = List.generate(7, (i) => now.add(Duration(days: i)).toIso8601String());

          final payload = {
            'current': {
              'temperature_2m': 28.0,
              'relative_humidity_2m': 50,
              'weather_code': 0,
              'wind_speed_10m': 12.0,
              'precipitation': 0.0,
              'is_day': 1,
            },
            'hourly': {
              'time': hourlyTimes,
              'temperature_2m': List.generate(30, (i) => 25.0 + i * 0.2),
              'precipitation_probability': List.generate(30, (i) => i * 2),
              'weather_code': List.generate(30, (i) => 0),
            },
            'daily': {
              'time': dailyTimes,
              'weather_code': [0, 1, 2, 3, 61, 0, 1],
              'temperature_2m_max': [34.0, 33.0, 32.0, 31.0, 29.0, 32.0, 33.0],
              'temperature_2m_min': [22.0, 21.0, 21.0, 20.0, 19.0, 21.0, 22.0],
              'precipitation_probability_max': [10, 15, 20, 45, 80, 5, 10],
              'uv_index_max': [7.2, 6.8, 7.0, 5.5, 4.0, 7.5, 7.1],
            },
          };
          return http.Response(jsonEncode(payload), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = WeatherService(
        client: fakeClient,
        localStorageService: storage,
      );

      final result = await service.fetchWeather(
        profile: sampleProfile,
        latitude: 30.3398,
        longitude: 76.3869,
      );

      expect(result.temperature, 28.0);
      expect(result.isDay, 1);
      expect(result.tempMin, 22.0);
      expect(result.tempMax, 34.0);
      expect(result.uvIndex, 7.2);
      expect(result.isSprayFavorable, isTrue);

      // Hourly forecast should cap to next 24 hours
      expect(result.hourlyForecast.length, 24);
      expect(result.hourlyForecast.first.temperature, 25.0);

      // Daily forecast should parse 7 days
      expect(result.dailyForecast.length, 7);
      expect(result.dailyForecast.first.dayNameEn, 'Today');
      expect(result.dailyForecast.first.dayNameHi, 'आज');
      expect(result.dailyForecast.first.maxTemp, 34.0);
      expect(result.dailyForecast.first.minTemp, 22.0);
    });
  });
}
