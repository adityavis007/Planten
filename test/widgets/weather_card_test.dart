import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/weather_data.dart';
import 'package:planten/providers/weather_provider.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/widgets/weather_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late WeatherProvider weatherProvider;

  final sampleWeather = WeatherData.fromWmoCode(
    temperature: 28.0,
    weatherCode: 0,
    humidity: 65,
    windSpeed: 14.0,
    rainProbability: 25,
    locationName: 'Patiala, Punjab',
    lastUpdated: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs: prefs);
    weatherProvider = WeatherProvider(localStorageService: storage);
  });

  Widget buildTestableWidget({
    required Widget child,
    Locale locale = const Locale('en'),
    WeatherProvider? provider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WeatherProvider>.value(
          value: provider ?? weatherProvider,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('WeatherCard Widget Tests', () {
    testWidgets('renders temperature, condition badge, location, and 3 metrics in English', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);

      await tester.pumpWidget(buildTestableWidget(child: const WeatherCard()));
      await tester.pump();

      // Header location & title
      expect(find.text('Patiala, Punjab'), findsOneWidget);
      expect(find.text("Today's Weather"), findsOneWidget);

      // Temperature
      expect(find.text('28°C'), findsOneWidget);

      // Condition badge (Clear Sky)
      expect(find.text('Clear Sky'), findsOneWidget);

      // 3 Metrics: Humidity, Wind, Rain Chance
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('14 km/h'), findsOneWidget);
      expect(find.text('Rain Chance'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);

      // Refresh button
      expect(find.byKey(const ValueKey('weather_refresh_button')), findsOneWidget);
    });

    testWidgets('renders bilingual text correctly in Hindi locale', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('hi'),
          child: const WeatherCard(),
        ),
      );
      await tester.pump();

      // Header title in Hindi
      expect(find.text('आज का मौसम'), findsOneWidget);

      // Condition in Hindi
      expect(find.text('साफ़ आसमान'), findsOneWidget);

      // Metrics in Hindi
      expect(find.text('नमी'), findsOneWidget);
      expect(find.text('हवा'), findsOneWidget);
      expect(find.text('बारिश'), findsOneWidget);
    });

    testWidgets('displays cached badge when weather is from local offline cache', (tester) async {
      final cachedWeather = sampleWeather.copyWith(isFromCache: true);
      weatherProvider.setWeatherDataForTesting(cachedWeather);

      await tester.pumpWidget(buildTestableWidget(child: const WeatherCard()));
      await tester.pump();

      expect(find.text('Cached'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('renders loading state when provider isLoading and weatherData is null', (tester) async {
      weatherProvider.setLoadingForTesting(true);

      await tester.pumpWidget(buildTestableWidget(child: const WeatherCard()));
      await tester.pump();

      expect(find.byKey(const ValueKey('weather_card_loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with retry button when provider has error and no data', (tester) async {
      weatherProvider.setErrorForTesting('No network connection');

      await tester.pumpWidget(buildTestableWidget(child: const WeatherCard()));
      await tester.pump();

      expect(find.byKey(const ValueKey('weather_card_error')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping refresh button triggers onRefreshTap callback', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);
      bool refreshTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: WeatherCard(
            onRefreshTap: () {
              refreshTapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      final refreshBtn = find.byKey(const ValueKey('weather_refresh_button'));
      await tester.tap(refreshBtn);
      await tester.pump();

      expect(refreshTapped, isTrue);
    });

    testWidgets('tapping WeatherCard triggers onTap callback to navigate to WeatherDetailScreen', (tester) async {
      weatherProvider.setWeatherDataForTesting(sampleWeather);
      bool cardTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: WeatherCard(
            onTap: () {
              cardTapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      final cardFinder = find.byKey(const ValueKey('weather_card_container'));
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      await tester.pump();

      expect(cardTapped, isTrue);
    });

    testWidgets('renders Current Location in English and Hindi when locationName is Current Location', (tester) async {
      final currentLocationWeather = sampleWeather.copyWith(
        locationName: 'Current Location',
      );
      weatherProvider.setWeatherDataForTesting(currentLocationWeather);

      // English
      await tester.pumpWidget(buildTestableWidget(child: const WeatherCard()));
      await tester.pump();
      expect(find.text('Current Location'), findsOneWidget);

      // Hindi
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('hi'),
          child: const WeatherCard(),
        ),
      );
      await tester.pump();
      expect(find.text('वर्तमान स्थान'), findsOneWidget);
    });
  });
}
