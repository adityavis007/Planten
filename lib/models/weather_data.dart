import 'package:flutter/material.dart';

/// Represents weather condition metadata with localized descriptions and UI icon.
class WeatherConditionInfo {
  final String textEn;
  final String textHi;
  final IconData icon;

  const WeatherConditionInfo({
    required this.textEn,
    required this.textHi,
    required this.icon,
  });
}

/// Helper utility to map WMO Weather Interpretation Codes to localized strings and icons.
abstract final class WeatherConditionHelper {
  static WeatherConditionInfo getInfo(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return const WeatherConditionInfo(
          textEn: 'Clear Sky',
          textHi: 'साफ़ आसमान',
          icon: Icons.wb_sunny_rounded,
        );
      case 1:
        return const WeatherConditionInfo(
          textEn: 'Mainly Clear',
          textHi: 'मुख्यतः साफ़',
          icon: Icons.wb_sunny_rounded,
        );
      case 2:
        return const WeatherConditionInfo(
          textEn: 'Partly Cloudy',
          textHi: 'आंशिक बादल',
          icon: Icons.cloud_queue_rounded,
        );
      case 3:
        return const WeatherConditionInfo(
          textEn: 'Overcast',
          textHi: 'घने बादल',
          icon: Icons.cloud_rounded,
        );
      case 45:
        return const WeatherConditionInfo(
          textEn: 'Foggy',
          textHi: 'कोहरा',
          icon: Icons.cloud_rounded,
        );
      case 48:
        return const WeatherConditionInfo(
          textEn: 'Depositing Fog',
          textHi: 'सघन कोहरा',
          icon: Icons.cloud_rounded,
        );
      case 51:
      case 53:
      case 55:
        return const WeatherConditionInfo(
          textEn: 'Drizzle',
          textHi: 'बूंदाबांदी',
          icon: Icons.grain_rounded,
        );
      case 56:
      case 57:
        return const WeatherConditionInfo(
          textEn: 'Freezing Drizzle',
          textHi: 'बर्फीली बूंदाबांदी',
          icon: Icons.ac_unit_rounded,
        );
      case 61:
      case 63:
      case 65:
        return const WeatherConditionInfo(
          textEn: 'Rain',
          textHi: 'बारिश',
          icon: Icons.water_drop_rounded,
        );
      case 66:
      case 67:
        return const WeatherConditionInfo(
          textEn: 'Freezing Rain',
          textHi: 'बर्फीली बारिश',
          icon: Icons.water_drop_rounded,
        );
      case 71:
      case 73:
      case 75:
        return const WeatherConditionInfo(
          textEn: 'Snow',
          textHi: 'बर्फबारी',
          icon: Icons.ac_unit_rounded,
        );
      case 77:
        return const WeatherConditionInfo(
          textEn: 'Snow Grains',
          textHi: 'हिमपात',
          icon: Icons.ac_unit_rounded,
        );
      case 80:
      case 81:
      case 82:
        return const WeatherConditionInfo(
          textEn: 'Rain Showers',
          textHi: 'बारिश की बौछारें',
          icon: Icons.water_drop_rounded,
        );
      case 85:
      case 86:
        return const WeatherConditionInfo(
          textEn: 'Snow Showers',
          textHi: 'बर्फ की बौछारें',
          icon: Icons.ac_unit_rounded,
        );
      case 95:
        return const WeatherConditionInfo(
          textEn: 'Thunderstorm',
          textHi: 'आंधी-तूफ़ान',
          icon: Icons.thunderstorm_rounded,
        );
      case 96:
      case 99:
        return const WeatherConditionInfo(
          textEn: 'Thunderstorm with Hail',
          textHi: 'ओलावृष्टि के साथ तूफ़ान',
          icon: Icons.thunderstorm_rounded,
        );
      default:
        if (weatherCode > 0 && weatherCode < 50) {
          return const WeatherConditionInfo(
            textEn: 'Cloudy',
            textHi: 'बादल',
            icon: Icons.cloud_rounded,
          );
        } else if (weatherCode >= 50 && weatherCode < 70) {
          return const WeatherConditionInfo(
            textEn: 'Rainy',
            textHi: 'बारिश',
            icon: Icons.water_drop_rounded,
          );
        } else if (weatherCode >= 70 && weatherCode < 80) {
          return const WeatherConditionInfo(
            textEn: 'Snowy',
            textHi: 'बर्फबारी',
            icon: Icons.ac_unit_rounded,
          );
        } else if (weatherCode >= 90) {
          return const WeatherConditionInfo(
            textEn: 'Thunderstorm',
            textHi: 'आंधी-तूफ़ान',
            icon: Icons.thunderstorm_rounded,
          );
        }
        return const WeatherConditionInfo(
          textEn: 'Clear Sky',
          textHi: 'साफ़ आसमान',
          icon: Icons.wb_sunny_rounded,
        );
    }
  }

  static IconData getIcon(int weatherCode) => getInfo(weatherCode).icon;
  static String getTextEn(int weatherCode) => getInfo(weatherCode).textEn;
  static String getTextHi(int weatherCode) => getInfo(weatherCode).textHi;
}

/// Represents an individual hourly weather observation/forecast.
@immutable
class HourlyForecastItem {
  final DateTime time;
  final double temperature;
  final int rainProbability;
  final int weatherCode;
  final IconData icon;

  const HourlyForecastItem({
    required this.time,
    required this.temperature,
    required this.rainProbability,
    required this.weatherCode,
    required this.icon,
  });

  Map<String, dynamic> toMap() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'rain_probability': rainProbability,
        'weather_code': weatherCode,
      };

  factory HourlyForecastItem.fromMap(Map<String, dynamic> map) {
    final code = (map['weather_code'] as num?)?.toInt() ?? 0;
    return HourlyForecastItem(
      time: DateTime.tryParse(map['time'] as String? ?? '') ?? DateTime.now(),
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      rainProbability: (map['rain_probability'] as num?)?.toInt() ?? 0,
      weatherCode: code,
      icon: WeatherConditionHelper.getIcon(code),
    );
  }
}

/// Represents an individual day forecast item in the 7-day outlook.
@immutable
class DailyForecastItem {
  final DateTime date;
  final String dayNameEn;
  final String dayNameHi;
  final double minTemp;
  final double maxTemp;
  final int weatherCode;
  final int rainProbability;
  final IconData icon;

  const DailyForecastItem({
    required this.date,
    required this.dayNameEn,
    required this.dayNameHi,
    required this.minTemp,
    required this.maxTemp,
    required this.weatherCode,
    required this.rainProbability,
    required this.icon,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'day_name_en': dayNameEn,
        'day_name_hi': dayNameHi,
        'min_temp': minTemp,
        'max_temp': maxTemp,
        'weather_code': weatherCode,
        'rain_probability': rainProbability,
      };

  factory DailyForecastItem.fromMap(Map<String, dynamic> map) {
    final code = (map['weather_code'] as num?)?.toInt() ?? 0;
    return DailyForecastItem(
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      dayNameEn: (map['day_name_en'] as String?) ?? '',
      dayNameHi: (map['day_name_hi'] as String?) ?? '',
      minTemp: (map['min_temp'] as num?)?.toDouble() ?? 0.0,
      maxTemp: (map['max_temp'] as num?)?.toDouble() ?? 0.0,
      weatherCode: code,
      rainProbability: (map['rain_probability'] as num?)?.toInt() ?? 0,
      icon: WeatherConditionHelper.getIcon(code),
    );
  }

  String localizedDayName(String languageCode) {
    return languageCode.toLowerCase() == 'hi' ? dayNameHi : dayNameEn;
  }
}

/// Immutable domain model representing real-time weather observations and extended forecasts.
@immutable
class WeatherData {
  /// Current temperature in Celsius (°C).
  final double temperature;

  /// Human-readable English weather condition name (e.g. "Sunny", "Rain").
  final String conditionTextEn;

  /// Human-readable Hindi weather condition name (e.g. "साफ़ आसमान", "बारिश").
  final String conditionTextHi;

  /// WMO weather interpretation code.
  final int weatherCode;

  /// UI icon representation for the current weather condition.
  final IconData weatherIcon;

  /// Relative humidity percentage (0-100%).
  final int humidity;

  /// Wind speed in km/h.
  final double windSpeed;

  /// Rain/precipitation probability percentage (0-100%).
  final int rainProbability;

  /// Human-readable location or district name (e.g. "Patiala, Punjab").
  final String locationName;

  /// Timestamp when the weather observation was captured or updated.
  final DateTime lastUpdated;

  /// Indicates if this record was served from local offline cache.
  final bool isFromCache;

  /// 1 if daytime, 0 if nighttime.
  final int isDay;

  /// Today's minimum temperature in °C.
  final double? tempMin;

  /// Today's maximum temperature in °C.
  final double? tempMax;

  /// Apparent / feels-like temperature in °C.
  final double? feelsLike;

  /// Peak UV Index for the day.
  final double? uvIndex;

  /// Next 24 hours forecast list.
  final List<HourlyForecastItem> hourlyForecast;

  /// 7-day daily forecast list.
  final List<DailyForecastItem> dailyForecast;

  const WeatherData({
    required this.temperature,
    required this.conditionTextEn,
    required this.conditionTextHi,
    required this.weatherCode,
    required this.weatherIcon,
    required this.humidity,
    required this.windSpeed,
    required this.rainProbability,
    required this.locationName,
    required this.lastUpdated,
    this.isFromCache = false,
    this.isDay = 1,
    this.tempMin,
    this.tempMax,
    this.feelsLike,
    this.uvIndex,
    this.hourlyForecast = const [],
    this.dailyForecast = const [],
  });

  /// Factory constructor to build [WeatherData] directly from WMO weather code.
  factory WeatherData.fromWmoCode({
    required double temperature,
    required int weatherCode,
    required int humidity,
    required double windSpeed,
    required int rainProbability,
    required String locationName,
    required DateTime lastUpdated,
    bool isFromCache = false,
    int isDay = 1,
    double? tempMin,
    double? tempMax,
    double? feelsLike,
    double? uvIndex,
    List<HourlyForecastItem> hourlyForecast = const [],
    List<DailyForecastItem> dailyForecast = const [],
    String? customConditionEn,
    String? customConditionHi,
  }) {
    final info = WeatherConditionHelper.getInfo(weatherCode);
    return WeatherData(
      temperature: temperature,
      conditionTextEn: customConditionEn ?? info.textEn,
      conditionTextHi: customConditionHi ?? info.textHi,
      weatherCode: weatherCode,
      weatherIcon: info.icon,
      humidity: humidity,
      windSpeed: windSpeed,
      rainProbability: rainProbability,
      locationName: locationName,
      lastUpdated: lastUpdated,
      isFromCache: isFromCache,
      isDay: isDay,
      tempMin: tempMin,
      tempMax: tempMax,
      feelsLike: feelsLike ?? temperature,
      uvIndex: uvIndex,
      hourlyForecast: hourlyForecast,
      dailyForecast: dailyForecast,
    );
  }

  /// Calculates whether field spraying is favorable (wind <= 20 km/h and rain probability <= 40%).
  bool get isSprayFavorable => rainProbability <= 40 && windSpeed <= 20.0;

  /// Returns localized condition description based on [languageCode] ('hi' or 'en').
  String localizedCondition(String languageCode) {
    if (languageCode.toLowerCase() == 'hi') {
      return conditionTextHi;
    }
    return conditionTextEn;
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'condition_text_en': conditionTextEn,
      'condition_text_hi': conditionTextHi,
      'weather_code': weatherCode,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'rain_probability': rainProbability,
      'location_name': locationName,
      'last_updated': lastUpdated.toIso8601String(),
      'is_from_cache': isFromCache,
      'is_day': isDay,
      if (tempMin != null) 'temp_min': tempMin,
      if (tempMax != null) 'temp_max': tempMax,
      if (feelsLike != null) 'feels_like': feelsLike,
      if (uvIndex != null) 'uv_index': uvIndex,
      'hourly_forecast': hourlyForecast.map((h) => h.toMap()).toList(),
      'daily_forecast': dailyForecast.map((d) => d.toMap()).toList(),
    };
  }

  /// Alias for [toMap].
  Map<String, dynamic> toJson() => toMap();

  /// Deserializes [WeatherData] from a JSON-compatible map.
  factory WeatherData.fromMap(Map<String, dynamic> map) {
    final weatherCode = (map['weather_code'] as num?)?.toInt() ?? 0;
    final info = WeatherConditionHelper.getInfo(weatherCode);

    final rawHourly = map['hourly_forecast'] as List<dynamic>?;
    final hourly = (rawHourly != null)
        ? rawHourly
            .whereType<Map<String, dynamic>>()
            .map((item) => HourlyForecastItem.fromMap(item))
            .toList()
        : <HourlyForecastItem>[];

    final rawDaily = map['daily_forecast'] as List<dynamic>?;
    final daily = (rawDaily != null)
        ? rawDaily
            .whereType<Map<String, dynamic>>()
            .map((item) => DailyForecastItem.fromMap(item))
            .toList()
        : <DailyForecastItem>[];

    return WeatherData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      conditionTextEn: (map['condition_text_en'] as String?) ?? info.textEn,
      conditionTextHi: (map['condition_text_hi'] as String?) ?? info.textHi,
      weatherCode: weatherCode,
      weatherIcon: info.icon,
      humidity: (map['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (map['wind_speed'] as num?)?.toDouble() ?? 0.0,
      rainProbability: (map['rain_probability'] as num?)?.toInt() ?? 0,
      locationName: (map['location_name'] as String?) ?? '',
      lastUpdated: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'] as String) ?? DateTime.now()
          : DateTime.now(),
      isFromCache: (map['is_from_cache'] as bool?) ?? false,
      isDay: (map['is_day'] as num?)?.toInt() ?? 1,
      tempMin: (map['temp_min'] as num?)?.toDouble(),
      tempMax: (map['temp_max'] as num?)?.toDouble(),
      feelsLike: (map['feels_like'] as num?)?.toDouble(),
      uvIndex: (map['uv_index'] as num?)?.toDouble(),
      hourlyForecast: hourly,
      dailyForecast: daily,
    );
  }

  /// Alias for [fromMap].
  factory WeatherData.fromJson(Map<String, dynamic> json) =>
      WeatherData.fromMap(json);

  /// Creates a copy with specified fields updated.
  WeatherData copyWith({
    double? temperature,
    String? conditionTextEn,
    String? conditionTextHi,
    int? weatherCode,
    IconData? weatherIcon,
    int? humidity,
    double? windSpeed,
    int? rainProbability,
    String? locationName,
    DateTime? lastUpdated,
    bool? isFromCache,
    int? isDay,
    double? tempMin,
    double? tempMax,
    double? feelsLike,
    double? uvIndex,
    List<HourlyForecastItem>? hourlyForecast,
    List<DailyForecastItem>? dailyForecast,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      conditionTextEn: conditionTextEn ?? this.conditionTextEn,
      conditionTextHi: conditionTextHi ?? this.conditionTextHi,
      weatherCode: weatherCode ?? this.weatherCode,
      weatherIcon: weatherIcon ?? this.weatherIcon,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      rainProbability: rainProbability ?? this.rainProbability,
      locationName: locationName ?? this.locationName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
      isDay: isDay ?? this.isDay,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      feelsLike: feelsLike ?? this.feelsLike,
      uvIndex: uvIndex ?? this.uvIndex,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      dailyForecast: dailyForecast ?? this.dailyForecast,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherData &&
        other.temperature == temperature &&
        other.conditionTextEn == conditionTextEn &&
        other.conditionTextHi == conditionTextHi &&
        other.weatherCode == weatherCode &&
        other.humidity == humidity &&
        other.windSpeed == windSpeed &&
        other.rainProbability == rainProbability &&
        other.locationName == locationName &&
        other.isFromCache == isFromCache &&
        other.isDay == isDay &&
        other.tempMin == tempMin &&
        other.tempMax == tempMax;
  }

  @override
  int get hashCode => Object.hash(
        temperature,
        conditionTextEn,
        conditionTextHi,
        weatherCode,
        humidity,
        windSpeed,
        rainProbability,
        locationName,
        isFromCache,
        isDay,
        tempMin,
        tempMax,
      );

  @override
  String toString() =>
      'WeatherData(temp: $temperature°C, condition: $conditionTextEn, humidity: $humidity%, wind: $windSpeed km/h, rain: $rainProbability%, loc: $locationName, spray: $isSprayFavorable)';
}
