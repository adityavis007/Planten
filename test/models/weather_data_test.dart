import 'package:flutter_test/flutter_test.dart';
import 'package:planten/models/weather_data.dart';

void main() {
  group('WeatherData Model Tests', () {
    test('constructs WeatherData correctly using fromWmoCode for Clear Sky (0)', () {
      final weather = WeatherData.fromWmoCode(
        temperature: 32.4,
        weatherCode: 0,
        humidity: 45,
        windSpeed: 12.0,
        rainProbability: 5,
        locationName: 'Patiala, Punjab',
        lastUpdated: DateTime.utc(2026, 4, 15, 10, 0),
      );

      expect(weather.temperature, 32.4);
      expect(weather.weatherCode, 0);
      expect(weather.humidity, 45);
      expect(weather.windSpeed, 12.0);
      expect(weather.rainProbability, 5);
      expect(weather.locationName, 'Patiala, Punjab');
      expect(weather.conditionTextEn, 'Clear Sky');
      expect(weather.conditionTextHi, 'साफ़ आसमान');
      expect(weather.localizedCondition('en'), 'Clear Sky');
      expect(weather.localizedCondition('hi'), 'साफ़ आसमान');
      expect(weather.isFromCache, isFalse);
    });

    test('maps various WMO codes correctly (Rain: 61, Thunderstorm: 95, Snow: 71)', () {
      final rain = WeatherData.fromWmoCode(
        temperature: 24.0,
        weatherCode: 61,
        humidity: 85,
        windSpeed: 18.5,
        rainProbability: 90,
        locationName: 'Varanasi, UP',
        lastUpdated: DateTime.utc(2026, 7, 10),
      );
      expect(rain.conditionTextEn, 'Rain');
      expect(rain.conditionTextHi, 'बारिश');

      final storm = WeatherData.fromWmoCode(
        temperature: 21.0,
        weatherCode: 95,
        humidity: 92,
        windSpeed: 35.0,
        rainProbability: 95,
        locationName: 'Lucknow, UP',
        lastUpdated: DateTime.utc(2026, 7, 10),
      );
      expect(storm.conditionTextEn, 'Thunderstorm');
      expect(storm.conditionTextHi, 'आंधी-तूफ़ान');

      final snow = WeatherData.fromWmoCode(
        temperature: -2.0,
        weatherCode: 71,
        humidity: 70,
        windSpeed: 8.0,
        rainProbability: 40,
        locationName: 'Shimla, HP',
        lastUpdated: DateTime.utc(2026, 1, 10),
      );
      expect(snow.conditionTextEn, 'Snow');
      expect(snow.conditionTextHi, 'बर्फबारी');
    });

    test('calculates isSprayFavorable accurately based on wind and rain thresholds', () {
      // Favorable: wind <= 20 and rain <= 40
      final favorable = WeatherData.fromWmoCode(
        temperature: 28.0,
        weatherCode: 1,
        humidity: 50,
        windSpeed: 15.0,
        rainProbability: 25,
        locationName: 'Patiala',
        lastUpdated: DateTime.now(),
      );
      expect(favorable.isSprayFavorable, isTrue);

      // Unfavorable due to high wind (> 20)
      final windy = WeatherData.fromWmoCode(
        temperature: 28.0,
        weatherCode: 1,
        humidity: 50,
        windSpeed: 24.5,
        rainProbability: 10,
        locationName: 'Patiala',
        lastUpdated: DateTime.now(),
      );
      expect(windy.isSprayFavorable, isFalse);

      // Unfavorable due to high rain (> 40)
      final rainy = WeatherData.fromWmoCode(
        temperature: 24.0,
        weatherCode: 61,
        humidity: 80,
        windSpeed: 12.0,
        rainProbability: 65,
        locationName: 'Patiala',
        lastUpdated: DateTime.now(),
      );
      expect(rainy.isSprayFavorable, isFalse);
    });

    test('serializes and deserializes HourlyForecastItem and DailyForecastItem', () {
      final hourly = HourlyForecastItem(
        time: DateTime.utc(2026, 9, 10, 14, 0),
        temperature: 29.5,
        rainProbability: 15,
        weatherCode: 1,
        icon: WeatherConditionHelper.getIcon(1),
      );

      final hourlyJson = hourly.toMap();
      final restoredHourly = HourlyForecastItem.fromMap(hourlyJson);
      expect(restoredHourly.temperature, 29.5);
      expect(restoredHourly.rainProbability, 15);
      expect(restoredHourly.weatherCode, 1);

      final daily = DailyForecastItem(
        date: DateTime.utc(2026, 9, 11),
        dayNameEn: 'Fri',
        dayNameHi: 'शुक्र',
        minTemp: 22.0,
        maxTemp: 34.0,
        weatherCode: 0,
        rainProbability: 5,
        icon: WeatherConditionHelper.getIcon(0),
      );

      final dailyJson = daily.toMap();
      final restoredDaily = DailyForecastItem.fromMap(dailyJson);
      expect(restoredDaily.dayNameEn, 'Fri');
      expect(restoredDaily.dayNameHi, 'शुक्र');
      expect(restoredDaily.minTemp, 22.0);
      expect(restoredDaily.maxTemp, 34.0);
      expect(restoredDaily.localizedDayName('hi'), 'शुक्र');
      expect(restoredDaily.localizedDayName('en'), 'Fri');
    });

    test('serializes to JSON and deserializes back faithfully with extended fields', () {
      final original = WeatherData.fromWmoCode(
        temperature: 28.5,
        weatherCode: 2,
        humidity: 55,
        windSpeed: 14.2,
        rainProbability: 15,
        locationName: 'Karnal, Haryana',
        lastUpdated: DateTime.utc(2026, 5, 20, 14, 30),
        isFromCache: true,
        isDay: 1,
        tempMin: 21.0,
        tempMax: 33.0,
        feelsLike: 29.0,
        uvIndex: 6.5,
        hourlyForecast: [
          HourlyForecastItem(
            time: DateTime.utc(2026, 5, 20, 15, 0),
            temperature: 30.0,
            rainProbability: 10,
            weatherCode: 1,
            icon: WeatherConditionHelper.getIcon(1),
          ),
        ],
        dailyForecast: [
          DailyForecastItem(
            date: DateTime.utc(2026, 5, 21),
            dayNameEn: 'Thu',
            dayNameHi: 'गुरु',
            minTemp: 20.0,
            maxTemp: 32.0,
            weatherCode: 2,
            rainProbability: 20,
            icon: WeatherConditionHelper.getIcon(2),
          ),
        ],
      );

      final json = original.toJson();
      expect(json['temperature'], 28.5);
      expect(json['weather_code'], 2);
      expect(json['humidity'], 55);
      expect(json['wind_speed'], 14.2);
      expect(json['rain_probability'], 15);
      expect(json['location_name'], 'Karnal, Haryana');
      expect(json['is_from_cache'], isTrue);
      expect(json['is_day'], 1);
      expect(json['temp_min'], 21.0);
      expect(json['temp_max'], 33.0);
      expect(json['feels_like'], 29.0);
      expect(json['uv_index'], 6.5);

      final restored = WeatherData.fromJson(json);
      expect(restored.temperature, original.temperature);
      expect(restored.weatherCode, original.weatherCode);
      expect(restored.humidity, original.humidity);
      expect(restored.windSpeed, original.windSpeed);
      expect(restored.rainProbability, original.rainProbability);
      expect(restored.locationName, original.locationName);
      expect(restored.isFromCache, original.isFromCache);
      expect(restored.isDay, 1);
      expect(restored.tempMin, 21.0);
      expect(restored.tempMax, 33.0);
      expect(restored.feelsLike, 29.0);
      expect(restored.uvIndex, 6.5);
      expect(restored.hourlyForecast.length, 1);
      expect(restored.hourlyForecast.first.temperature, 30.0);
      expect(restored.dailyForecast.length, 1);
      expect(restored.dailyForecast.first.dayNameEn, 'Thu');
    });

    test('copyWith updates specified fields only', () {
      final original = WeatherData.fromWmoCode(
        temperature: 25.0,
        weatherCode: 1,
        humidity: 50,
        windSpeed: 10.0,
        rainProbability: 0,
        locationName: 'Pune, MH',
        lastUpdated: DateTime.utc(2026, 3, 1),
      );

      final updated = original.copyWith(
        temperature: 29.0,
        isFromCache: true,
      );

      expect(updated.temperature, 29.0);
      expect(updated.isFromCache, isTrue);
      expect(updated.humidity, 50);
      expect(updated.locationName, 'Pune, MH');
    });
  });
}
