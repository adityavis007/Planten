import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/weather_data.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/weather_provider.dart';
import 'package:planten/screens/home/weather_detail_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late WeatherProvider weatherProvider;
  late AuthProvider authProvider;

  final sampleWeather = WeatherData.fromWmoCode(
    temperature: 29.0,
    weatherCode: 0,
    humidity: 55,
    windSpeed: 12.0,
    rainProbability: 15,
    locationName: 'Nabha, Patiala, Punjab',
    lastUpdated: DateTime.now(),
    isDay: 1,
    tempMin: 21.0,
    tempMax: 35.0,
    feelsLike: 30.0,
    uvIndex: 6.8,
    hourlyForecast: [
      HourlyForecastItem(
        time: DateTime.now().add(const Duration(hours: 1)),
        temperature: 30.0,
        rainProbability: 10,
        weatherCode: 0,
        icon: WeatherConditionHelper.getIcon(0),
      ),
      HourlyForecastItem(
        time: DateTime.now().add(const Duration(hours: 2)),
        temperature: 31.0,
        rainProbability: 20,
        weatherCode: 1,
        icon: WeatherConditionHelper.getIcon(1),
      ),
    ],
    dailyForecast: [
      DailyForecastItem(
        date: DateTime.now(),
        dayNameEn: 'Today',
        dayNameHi: 'आज',
        minTemp: 21.0,
        maxTemp: 35.0,
        weatherCode: 0,
        rainProbability: 15,
        icon: WeatherConditionHelper.getIcon(0),
      ),
      DailyForecastItem(
        date: DateTime.now().add(const Duration(days: 1)),
        dayNameEn: 'Fri',
        dayNameHi: 'शुक्र',
        minTemp: 22.0,
        maxTemp: 34.0,
        weatherCode: 1,
        rainProbability: 25,
        icon: WeatherConditionHelper.getIcon(1),
      ),
    ],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs: prefs);
    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: UserProfileService(localStorageService: storage),
    );
    weatherProvider = WeatherProvider(localStorageService: storage);
  });

  Widget buildTestableScreen({
    Locale locale = const Locale('en'),
    WeatherProvider? customWeather,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<WeatherProvider>.value(
          value: customWeather ?? weatherProvider,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: WeatherDetailScreen(
          weatherProvider: customWeather ?? weatherProvider,
          authProvider: authProvider,
        ),
      ),
    );
  }

  group('WeatherDetailScreen Tests', () {
    testWidgets('renders hero weather card, spray advisory, hourly, daily, and metrics in English', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pump();

      // App Bar title & subtitle
      expect(find.text('Nabha, Patiala, Punjab'), findsOneWidget);
      expect(find.text('Weather Details'), findsOneWidget);

      // Hero Card
      expect(find.byKey(const ValueKey('weather_hero_card')), findsOneWidget);
      expect(find.text('29°C'), findsOneWidget);
      expect(find.text('Clear Sky'), findsOneWidget);
      expect(find.text('Feels like 30°C'), findsOneWidget);
      expect(find.text('L: 21°C  •  H: 35°C'), findsOneWidget);

      // Smart Spray Advisory (Favorable because wind=12 <= 20 & rain=15 <= 40)
      expect(find.byKey(const ValueKey('weather_spray_advisory_card')), findsOneWidget);
      expect(find.text('Farming Spray Advisory'), findsOneWidget);
      expect(find.text('Favorable'), findsOneWidget);
      expect(find.text('Favorable conditions for field work & spraying'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // 24-Hour Forecast
      expect(find.text('24-Hour Forecast'), findsOneWidget);
      expect(find.byKey(const ValueKey('hourly_forecast_list')), findsOneWidget);

      // 7-Day Forecast
      expect(find.text('7-Day Forecast'), findsOneWidget);
      expect(find.byKey(const ValueKey('daily_forecast_list')), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);

      // 2x2 Agricultural Metrics
      expect(find.text('Agricultural Metrics'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('55%'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('12.0 km/h'), findsOneWidget);
      expect(find.text('Rain Chance'), findsOneWidget);
      expect(find.text('15%'), findsWidgets);
    });

    testWidgets('renders High Risk spray advisory when rain or wind exceeds threshold', (tester) async {
      final rainyWeather = sampleWeather.copyWith(
        rainProbability: 75,
        windSpeed: 24.0,
      );
      weatherProvider.setWeatherDataForTesting(rainyWeather);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pump();

      expect(find.text('High Risk'), findsOneWidget);
      expect(find.text('Avoid spraying chemicals today (High rain/wind risk)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders bilingual Hindi text in Hindi locale', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);

      await tester.pumpWidget(buildTestableScreen(locale: const Locale('hi')));
      await tester.pump();

      // Hindi App Bar & Condition
      expect(find.text('मौसम विवरण'), findsOneWidget);
      expect(find.text('साफ़ आसमान'), findsOneWidget);

      // Hindi Spray Advisory
      expect(find.text('कृषि छिड़काव सलाह'), findsOneWidget);
      expect(find.text('कीटनाशक छिड़काव और कृषि कार्य के लिए मौसम अनुकूल है'), findsOneWidget);

      // Hindi Sections
      expect(find.text('24 घंटे का पूर्वानुमान'), findsOneWidget);
      expect(find.text('7 दिनों का पूर्वानुमान'), findsOneWidget);
      expect(find.text('आज'), findsOneWidget);
      expect(find.text('शुक्र'), findsOneWidget);

      // Hindi Metrics
      expect(find.text('नमी'), findsOneWidget);
      expect(find.text('हवा'), findsOneWidget);
      expect(find.text('बारिश'), findsOneWidget);
    });

    testWidgets('refresh button triggers provider refresh', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pump();

      final refreshBtn = find.byKey(const ValueKey('weather_detail_refresh_button'));
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();
    });

    testWidgets('renders Current Location with pin icon in English and Hindi', (tester) async {
      final currentLocationWeather = sampleWeather.copyWith(
        locationName: 'Current Location',
      );
      weatherProvider.setWeatherDataForTesting(currentLocationWeather);

      // English
      await tester.pumpWidget(buildTestableScreen(locale: const Locale('en')));
      await tester.pump();

      expect(find.text('Current Location'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);

      // Hindi
      await tester.pumpWidget(buildTestableScreen(locale: const Locale('hi')));
      await tester.pump();

      expect(find.text('वर्तमान स्थान'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('renders long weather condition without overflow on hero card', (tester) async {
      final longConditionWeather = WeatherData.fromWmoCode(
        temperature: 31.0,
        weatherCode: 99,
        humidity: 80,
        windSpeed: 25.0,
        rainProbability: 90,
        locationName: 'Current Location',
        lastUpdated: DateTime.now(),
        isDay: 1,
        tempMin: 25.0,
        tempMax: 31.0,
        feelsLike: 31.0,
        customConditionEn: 'Thunderstorm with Heavy Hail and Strong Gusts',
        customConditionHi: 'भारी ओलावृष्टि और तेज हवाओं के साथ आंधी',
      );
      weatherProvider.setWeatherDataForTesting(longConditionWeather);

      // Render on a compact 360x640 mobile screen
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pump();

      // Verify widget rendered cleanly and no flutter exceptions were thrown
      expect(find.byKey(const ValueKey('weather_hero_card')), findsOneWidget);
      expect(find.text('L: 25°C  •  H: 31°C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
