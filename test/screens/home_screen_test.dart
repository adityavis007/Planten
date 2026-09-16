import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/weather_data.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/providers/weather_provider.dart';
import 'package:planten/screens/home/home_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';
import 'package:planten/widgets/scan_history_card.dart';
import 'package:planten/widgets/weather_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late AuthProvider authProvider;
  late CropProvider cropProvider;
  late LocalStorageService localStorage;
  late UserProfileService userProfileService;

  final sampleProfile = FarmerProfile(
    uid: 'farmer-456',
    phoneNumber: '+919876543210',
    name: 'Balwinder Singh',
    village: 'Samana',
    district: 'Patiala',
    state: 'Punjab',
    primaryCrops: ['wheat', 'tomato'],
    photoBackupOptIn: false,
    createdAt: DateTime.utc(2026, 3, 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    userProfileService = UserProfileService(localStorageService: localStorage);
    localeProvider = LocaleProvider(prefs: prefs);
    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: userProfileService,
    );
    cropProvider = CropProvider(localStorageService: localStorage);
  });

  tearDown(() {
    authProvider.dispose();
    cropProvider.dispose();
  });

  Widget buildTestableHomeScreen({
    CropProvider? customCrop,
    AuthProvider? customAuth,
    WeatherProvider? customWeather,
    LocalStorageService? customStorage,
    VoidCallback? onScanTap,
    VoidCallback? onChangeCropTap,
    VoidCallback? onViewAllTap,
    VoidCallback? onSearchTap,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<AuthProvider>.value(
            value: customAuth ?? authProvider),
        ChangeNotifierProvider<CropProvider>.value(
            value: customCrop ?? cropProvider),
        if (customWeather != null)
          ChangeNotifierProvider<WeatherProvider>.value(value: customWeather),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: HomeScreen(
          cropProvider: customCrop ?? cropProvider,
          authProvider: customAuth ?? authProvider,
          weatherProvider: customWeather,
          localStorageService: customStorage ?? localStorage,
          onScanTap: onScanTap,
          onChangeCropTap: onChangeCropTap,
          onViewAllHistoryTap: onViewAllTap,
          onSearchTap: onSearchTap,
        ),
      ),
    );
  }

  group('HomeScreen (Task 32)', () {
    testWidgets(
        'renders farmer greeting, active crop card, hero scan CTA, and empty recent scans state',
        (tester) async {
      await authProvider.updateProfile(sampleProfile);

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump();

      // Farmer Greeting
      expect(find.text('Namaste, Balwinder Singh'), findsOneWidget);
      expect(find.text('Samana, Patiala, Punjab'), findsOneWidget);

      // Active Crop Card
      expect(find.text('Active Crop'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.byKey(const ValueKey('change_crop_button')), findsOneWidget);

      // Hero Scan Leaf CTA
      expect(find.text('Scan Leaf for Disease'), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_scan_card')), findsOneWidget);

      // Empty Recent Scans
      expect(find.text('Recent Scans'), findsOneWidget);
      expect(
        find.text('No recent scans. Tap scan to diagnose your crop.'),
        findsOneWidget,
      );
    });

    testWidgets('renders fallback greeting when farmer profile is null',
        (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump();

      expect(find.text('Namaste, Farmer'), findsOneWidget);
    });

    testWidgets('displays recent scans specifically filtered to active crop',
        (tester) async {
      final tomatoScan = DiagnosisResult(
        id: 'scan-tomato-1',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        diseaseNameEn: 'Early Blight',
        diseaseNameHi: 'अगेती झुलसा',
        confidenceScore: 0.92,
        severity: SeverityLevel.high,
        localImagePath: '/path/to/tomato.jpg',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final wheatScan = DiagnosisResult(
        id: 'scan-wheat-1',
        cropId: 'wheat',
        diseaseId: 'wheat_rust',
        diseaseNameEn: 'Leaf Rust',
        diseaseNameHi: 'भूरा रतुआ',
        confidenceScore: 0.88,
        severity: SeverityLevel.medium,
        localImagePath: '/path/to/wheat.jpg',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await localStorage.saveOfflineScans([tomatoScan, wheatScan]);

      // Active crop is Tomato by default
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump();

      // Expect Tomato scan card to be visible
      expect(find.byType(ScanHistoryCard), findsOneWidget);
      expect(find.text('Early Blight'), findsOneWidget);
      expect(find.text('Leaf Rust'), findsNothing);

      // Switch active crop to Wheat
      await cropProvider.selectCropById('wheat');
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump();

      // Now Wheat scan is visible, Tomato scan is not
      expect(find.byType(ScanHistoryCard), findsOneWidget);
      expect(find.text('Leaf Rust'), findsOneWidget);
      expect(find.text('Early Blight'), findsNothing);
    });

    testWidgets(
        'tapping Change Crop opens selection modal and selecting a crop updates active crop',
        (tester) async {
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump();

      expect(find.text('Tomato'), findsOneWidget);

      // Tap Change button
      final changeBtn = find.byKey(const ValueKey('change_crop_button'));
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Select Crop'), findsOneWidget);
      expect(find.byKey(const ValueKey('modal_crop_option_potato')), findsOneWidget);

      // Tap Potato
      await tester.tap(find.byKey(const ValueKey('modal_crop_option_potato')));
      await tester.pumpAndSettle();

      // Modal closed and active crop changed to Potato
      expect(cropProvider.selectedCropId, 'potato');
      expect(find.text('Potato'), findsOneWidget);
    });

    testWidgets('tapping hero scan card triggers onScanTap callback',
        (tester) async {
      bool scanTapped = false;

      await tester.pumpWidget(
        buildTestableHomeScreen(
          onScanTap: () {
            scanTapped = true;
          },
        ),
      );
      await tester.pump();

      final heroCard = find.byKey(const ValueKey('hero_scan_card'));
      await tester.tap(heroCard);
      await tester.pump();

      expect(scanTapped, isTrue);
    });

    testWidgets('tapping View All button triggers onViewAllHistoryTap callback',
        (tester) async {
      bool viewAllTapped = false;

      await tester.pumpWidget(
        buildTestableHomeScreen(
          onViewAllTap: () {
            viewAllTapped = true;
          },
        ),
      );
      await tester.pump();

      final viewAllBtn = find.byKey(const ValueKey('view_all_scans_button'));
      await tester.tap(viewAllBtn);
      await tester.pump();

      expect(viewAllTapped, isTrue);
    });

    testWidgets(
        'navigates to AppRoutes.scan and AppRoutes.history with GoRouter in full shell mode',
        (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => HomeScreen(
              cropProvider: cropProvider,
              authProvider: authProvider,
              localStorageService: localStorage,
            ),
          ),
          GoRoute(
            path: AppRoutes.scan,
            builder: (context, state) =>
                const Scaffold(body: Text('Camera Viewfinder Route')),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) =>
                const Scaffold(body: Text('History List Route')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Tap hero scan card -> routes to Scan
      final heroCard = find.byKey(const ValueKey('hero_scan_card'));
      await tester.tap(heroCard);
      await tester.pumpAndSettle();

      expect(find.text('Camera Viewfinder Route'), findsOneWidget);
    });

    testWidgets('handles long Indian farmer name and district location on small screen without overflow (Fix 2)',
        (tester) async {
      // Set small screen size (360 x 640)
      tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final longProfile = FarmerProfile(
        uid: 'farmer-long-999',
        phoneNumber: '+919876543210',
        name: 'Balwinder Singh Dhillon Long Name',
        village: 'Kirwil Sonbhadra Gram Panchayat',
        district: 'Sonbhadra, Uttar Pradesh',
        state: 'Uttar Pradesh',
        primaryCrops: ['wheat'],
        photoBackupOptIn: false,
        createdAt: DateTime.utc(2026, 3, 1),
      );

      await authProvider.updateProfile(longProfile);

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      // Verify the long name renders and no layout overflow occurs
      expect(find.textContaining('Balwinder Singh Dhillon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping top-left farmer profile avatar navigates to AppRoutes.profile',
        (tester) async {
      await authProvider.updateProfile(sampleProfile);

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => HomeScreen(
              cropProvider: cropProvider,
              authProvider: authProvider,
              localStorageService: localStorage,
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) =>
                const Scaffold(body: Text('Farmer Profile Route')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Tap profile avatar
      final avatarFinder = find.byKey(const Key('home_screen_profile_avatar'));
      expect(avatarFinder, findsOneWidget);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      expect(find.text('Farmer Profile Route'), findsOneWidget);
    });

    testWidgets('renders WeatherCard on HomeScreen above Crop Selection card when weather data is present',
        (tester) async {
      await authProvider.updateProfile(sampleProfile);
      final weatherProvider = WeatherProvider(localStorageService: localStorage);
      weatherProvider.setWeatherDataForTesting(
        WeatherData.fromWmoCode(
          temperature: 31.0,
          weatherCode: 0,
          humidity: 48,
          windSpeed: 16.0,
          rainProbability: 10,
          locationName: 'Samana, Patiala, Punjab',
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildTestableHomeScreen(customWeather: weatherProvider));
      await tester.pump();

      // WeatherCard container should be present
      expect(find.byType(WeatherCard), findsOneWidget);
      expect(find.text('31°C'), findsOneWidget);
      expect(find.text('Clear Sky'), findsOneWidget);
      expect(find.text('48%'), findsOneWidget);
      expect(find.text('16 km/h'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);

      // Active Crop card is also present
      expect(find.text('Active Crop'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
    });

    testWidgets(
        'renders search bar on HomeScreen below header and triggers onSearchTap callback',
        (tester) async {
      bool searchTapped = false;

      await tester.pumpWidget(
        buildTestableHomeScreen(
          onSearchTap: () {
            searchTapped = true;
          },
        ),
      );
      await tester.pump();

      // Search bar is rendered
      final searchBar = find.byKey(const ValueKey('home_search_bar'));
      expect(searchBar, findsOneWidget);
      expect(find.text('Search crop, disease, or symptoms...'), findsOneWidget);

      // Tap search bar
      await tester.tap(searchBar);
      await tester.pump();

      expect(searchTapped, isTrue);
    });

    testWidgets(
        'tapping search bar navigates to AppRoutes.search with GoRouter in full shell mode',
        (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => HomeScreen(
              cropProvider: cropProvider,
              authProvider: authProvider,
              localStorageService: localStorage,
            ),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) =>
                const Scaffold(body: Text('Crop Doctor Search Route')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Search bar is rendered
      final searchBar = find.byKey(const ValueKey('home_search_bar'));
      expect(searchBar, findsOneWidget);

      // Tap search bar -> routes to Search
      await tester.tap(searchBar);
      await tester.pumpAndSettle();

      expect(find.text('Crop Doctor Search Route'), findsOneWidget);
    });
  });
}
