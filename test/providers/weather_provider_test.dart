import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/models/weather_data.dart';
import 'package:planten/providers/weather_provider.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/weather_service.dart';

class MockWeatherService extends WeatherService {
  WeatherData? mockData;
  Exception? mockError;
  int fetchCallCount = 0;

  MockWeatherService({this.mockData, this.mockError});

  @override
  Future<WeatherData> fetchWeather({
    FarmerProfile? profile,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    fetchCallCount++;
    if (mockError != null) {
      throw mockError!;
    }
    return mockData ??
        WeatherData.fromWmoCode(
          temperature: 28.0,
          weatherCode: 0,
          humidity: 50,
          windSpeed: 10.0,
          rainProbability: 5,
          locationName: locationName ?? 'Patiala, Punjab',
          lastUpdated: DateTime.now(),
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    storage = LocalStorageService(prefs: prefs);
  });

  group('WeatherProvider Unit Tests', () {
    test('initializes with null data and not loading when no cache', () {
      final provider = WeatherProvider(
        localStorageService: storage,
        weatherService: MockWeatherService(),
      );

      expect(provider.weatherData, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.hasData, isFalse);
      expect(provider.isOffline, isFalse);
    });

    test('immediately restores cached weather on startup', () async {
      final cachedWeather = WeatherData.fromWmoCode(
        temperature: 27.0,
        weatherCode: 2,
        humidity: 60,
        windSpeed: 12.0,
        rainProbability: 20,
        locationName: 'Varanasi, UP',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      await storage.saveCachedWeather(cachedWeather);

      final provider = WeatherProvider(
        localStorageService: storage,
        weatherService: MockWeatherService(),
      );

      expect(provider.weatherData, isNotNull);
      expect(provider.weatherData!.temperature, 27.0);
      expect(provider.weatherData!.isFromCache, isTrue);
      expect(provider.isOffline, isTrue);
    });

    test('fetchWeather updates weatherData and notifies listeners', () async {
      final mockService = MockWeatherService(
        mockData: WeatherData.fromWmoCode(
          temperature: 30.0,
          weatherCode: 0,
          humidity: 40,
          windSpeed: 15.0,
          rainProbability: 0,
          locationName: 'Patiala, Punjab',
          lastUpdated: DateTime.now(),
        ),
      );

      final provider = WeatherProvider(
        localStorageService: storage,
        weatherService: mockService,
      );

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.fetchWeather(forceRefresh: true);

      expect(provider.isLoading, isFalse);
      expect(provider.weatherData, isNotNull);
      expect(provider.weatherData!.temperature, 30.0);
      expect(provider.errorMessage, isNull);
      expect(notified, isTrue);
      expect(mockService.fetchCallCount, 1);
    });

    test('refreshWeather forces new fetch call', () async {
      final mockService = MockWeatherService();
      final provider = WeatherProvider(
        localStorageService: storage,
        weatherService: mockService,
      );

      await provider.refreshWeather();
      expect(mockService.fetchCallCount, 1);

      await provider.refreshWeather();
      expect(mockService.fetchCallCount, 2);
    });

    test('sets errorMessage on fetch failure when no data exists', () async {
      final mockService = MockWeatherService(
        mockError: http.ClientException('Network unreachable'),
      );

      final provider = WeatherProvider(
        localStorageService: storage,
        weatherService: mockService,
      );

      await provider.fetchWeather(forceRefresh: true);

      expect(provider.isLoading, isFalse);
      expect(provider.weatherData, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Network unreachable'));
    });
  });
}
