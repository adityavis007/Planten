import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/diagnosis_provider.dart';
import 'providers/history_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/weather_provider.dart';
import 'services/firebase_service.dart';
import 'services/firestore_sync_service.dart';
import 'services/history_service.dart';
import 'services/local_storage_service.dart';
import 'services/network_monitor_service.dart';
import 'services/user_profile_service.dart';
import 'services/weather_service.dart';

/// Configures global error handling for Flutter framework and Dart runtime errors.
void setupGlobalErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Planten Global Error: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint('Planten Stack: ${details.stack}');
    }
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Planten Uncaught Platform Error: $error');
    debugPrint('Planten Async Stack: $stack');
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupGlobalErrorHandling();

  // Initialize Firebase (offline-first, non-blocking fallback if unconfigured)
  await FirebaseService.instance.initialize();

  // Initialize SharedPreferences & LocalStorageService
  final prefs = await SharedPreferences.getInstance();
  final localStorageService = LocalStorageService(prefs: prefs);
  await localStorageService.init();

  // Initialize NetworkMonitorService
  final networkMonitorService = NetworkMonitorService();
  await networkMonitorService.initialize();

  // Initialize FirestoreSyncService and start auto-sync on connectivity restoration
  final firestoreSyncService = FirestoreSyncService(
    localStorageService: localStorageService,
    networkMonitorService: networkMonitorService,
  );
  firestoreSyncService.startAutoSync();

  runApp(
    PlantenApp(
      prefs: prefs,
      localStorageService: localStorageService,
      networkMonitorService: networkMonitorService,
      syncService: firestoreSyncService,
    ),
  );
}

/// Root widget for the Planten (AI Crop Doctor) application.
///
/// Features:
/// - Configures [MultiProvider] hosting [LocaleProvider], [AuthProvider],
///   [CropProvider], [DiagnosisProvider], [HistoryProvider], and [NetworkMonitorService].
/// - Listens reactively to [LocaleProvider] to switch between English and Hindi.
/// - Wraps declarative [MaterialApp.router] with [AppTheme.lightTheme],
///   [AppLocalizations], and [AppRouter.router].
/// - Provides optional dependency injection parameters for frictionless testing.
class PlantenApp extends StatelessWidget {
  /// Custom router configuration override, useful for widget tests.
  final RouterConfig<Object>? routerConfig;

  /// Optional pre-configured [SharedPreferences] instance.
  final SharedPreferences? prefs;

  /// Optional injected [LocalStorageService] instance.
  final LocalStorageService? localStorageService;

  /// Optional injected [NetworkMonitorService] instance.
  final NetworkMonitorService? networkMonitorService;

  /// Optional injected [FirestoreSyncService] instance.
  final FirestoreSyncService? syncService;

  /// Optional injected [LocaleProvider] instance.
  final LocaleProvider? localeProvider;

  /// Optional injected [ThemeProvider] instance.
  final ThemeProvider? themeProvider;

  /// Optional injected [AuthProvider] instance.
  final AuthProvider? authProvider;

  /// Optional injected [CropProvider] instance.
  final CropProvider? cropProvider;

  /// Optional injected [DiagnosisProvider] instance.
  final DiagnosisProvider? diagnosisProvider;

  /// Optional injected [HistoryProvider] instance.
  final HistoryProvider? historyProvider;

  /// Optional injected [WeatherProvider] instance.
  final WeatherProvider? weatherProvider;

  const PlantenApp({
    super.key,
    this.routerConfig,
    this.prefs,
    this.localStorageService,
    this.networkMonitorService,
    this.syncService,
    this.localeProvider,
    this.themeProvider,
    this.authProvider,
    this.cropProvider,
    this.diagnosisProvider,
    this.historyProvider,
    this.weatherProvider,
  });

  @override
  Widget build(BuildContext context) {
    final storage = localStorageService ?? LocalStorageService(prefs: prefs);
    final userProfile = UserProfileService(localStorageService: storage);
    final history = HistoryService(localStorageService: storage);
    final sync = syncService ??
        FirestoreSyncService(
          localStorageService: storage,
          networkMonitorService: networkMonitorService,
        );

    return MultiProvider(
      providers: [
        // Connectivity Service
        Provider<NetworkMonitorService>.value(
          value: networkMonitorService ?? NetworkMonitorService(),
        ),

        // 1. Locale Provider (Language & Vernacular State)
        if (localeProvider != null)
          ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider!)
        else
          ChangeNotifierProvider<LocaleProvider>(
            create: (_) => LocaleProvider(prefs: prefs),
          ),

        // Theme Provider (Light/Dark Mode State)
        if (themeProvider != null)
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider!)
        else
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(prefs: prefs),
          ),

        // 2. Auth Provider (Phone OTP & Farmer Profile State)
        if (authProvider != null)
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider!)
        else
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(userProfileService: userProfile),
          ),

        // 3. Crop Provider (Active Crop & Multi-Crop Catalog)
        if (cropProvider != null)
          ChangeNotifierProvider<CropProvider>.value(value: cropProvider!)
        else
          ChangeNotifierProxyProvider<AuthProvider, CropProvider>(
            create: (_) => CropProvider(localStorageService: storage),
            update: (_, auth, previous) {
              final cp = previous ?? CropProvider(localStorageService: storage);
              if (auth.profile != null && auth.profile!.primaryCrops.isNotEmpty) {
                cp.syncWithProfile(auth.profile!.primaryCrops);
              }
              return cp;
            },
          ),

        // 4. Diagnosis Provider (LiteRT AI Leaf Inference & Confidence)
        if (diagnosisProvider != null)
          ChangeNotifierProvider<DiagnosisProvider>.value(value: diagnosisProvider!)
        else
          ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => DiagnosisProvider(
              localStorageService: storage,
              historyService: history,
              syncService: sync,
            ),
          ),

        // 5. History Provider (Diagnoses Caching & Auto-Sync)
        if (historyProvider != null)
          ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider!)
        else
          ChangeNotifierProxyProvider2<AuthProvider, DiagnosisProvider, HistoryProvider>(
            create: (ctx) {
              final auth = Provider.of<AuthProvider>(ctx, listen: false);
              final diag = Provider.of<DiagnosisProvider>(ctx, listen: false);
              final hp = HistoryProvider(
                historyService: history,
                diagnosisProvider: diag,
                syncService: sync,
                userId: auth.user?.uid,
              );
              if (auth.user != null) {
                hp.syncWithCloud(auth.user!.uid);
              }
              return hp;
            },
            update: (_, auth, diag, previous) {
              final hp = previous ??
                  HistoryProvider(
                    historyService: history,
                    diagnosisProvider: diag,
                    syncService: sync,
                    userId: auth.user?.uid,
                  );
              hp.updateUserId(auth.user?.uid);
              final uid = auth.user?.uid;
              if (uid != null && uid.isNotEmpty && uid != hp.syncedUserId) {
                hp.syncWithCloud(uid);
              }
              return hp;
            },
          ),

        // 6. Weather Provider (Open-Meteo Real-time Weather & Offline Cache)
        if (weatherProvider != null)
          ChangeNotifierProvider<WeatherProvider>.value(value: weatherProvider!)
        else
          ChangeNotifierProxyProvider<AuthProvider, WeatherProvider>(
            create: (ctx) {
              final auth = Provider.of<AuthProvider>(ctx, listen: false);
              final isTest =
                  WidgetsBinding.instance.runtimeType.toString().contains('Test');
              return WeatherProvider(
                localStorageService: storage,
                weatherService: WeatherService(localStorageService: storage),
                autoFetch: !isTest,
                initialProfile: auth.profile,
              );
            },
            update: (_, auth, previous) {
              final wp = previous ??
                  WeatherProvider(
                    localStorageService: storage,
                    weatherService: WeatherService(localStorageService: storage),
                  );
              final isTest =
                  WidgetsBinding.instance.runtimeType.toString().contains('Test');
              if (!isTest &&
                  auth.profile != null &&
                  wp.weatherData == null &&
                  !wp.isLoading) {
                wp.fetchWeather(profile: auth.profile);
              }
              return wp;
            },
          ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, activeLocaleProvider, activeThemeProvider, child) {
          return MaterialApp.router(
            title: 'Planten',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: activeThemeProvider.themeMode,
            locale: activeLocaleProvider.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: routerConfig ?? AppRouter.router,
          );
        },
      ),
    );
  }
}

/// Backward compatibility alias for [PlantenApp].
typedef MyApp = PlantenApp;
