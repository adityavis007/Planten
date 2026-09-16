import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/core/router/app_router.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/main.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/diagnosis_provider.dart';
import 'package:planten/providers/history_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/profile/disclaimer_screen.dart';
import 'package:planten/screens/splash_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/network_monitor_service.dart';
import 'package:planten/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorageService localStorage;
  late NetworkMonitorService networkMonitor;
  late LocaleProvider localeProvider;
  late AuthProvider authProvider;
  late CropProvider cropProvider;
  late DiagnosisProvider diagnosisProvider;
  late HistoryProvider historyProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    await localStorage.init();

    networkMonitor = NetworkMonitorService();
    localeProvider = LocaleProvider(prefs: prefs, initialLocale: const Locale('en'));
    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: UserProfileService(localStorageService: localStorage),
    );
    cropProvider = CropProvider(localStorageService: localStorage);
    diagnosisProvider = DiagnosisProvider(localStorageService: localStorage);
    historyProvider = HistoryProvider(diagnosisProvider: diagnosisProvider);
  });

  tearDown(() {
    authProvider.dispose();
    cropProvider.dispose();
    diagnosisProvider.dispose();
    historyProvider.dispose();
  });

  group('PlantenApp Main Assembly (Task 55)', () {
    testWidgets('boots smoothly into SplashScreen with brand emblem and title',
        (WidgetTester tester) async {
      final testRouter = AppRouter.createRouter(initialLocation: AppRoutes.splash);

      await tester.pumpWidget(
        PlantenApp(
          routerConfig: testRouter,
          prefs: prefs,
          localStorageService: localStorage,
          networkMonitorService: networkMonitor,
          localeProvider: localeProvider,
          authProvider: authProvider,
          cropProvider: cropProvider,
          diagnosisProvider: diagnosisProvider,
          historyProvider: historyProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Planten'), findsOneWidget);
      expect(find.text('Your AI Crop Doctor'), findsOneWidget);
      expect(find.byKey(const ValueKey('app_logo_emblem')), findsOneWidget);

      // Drain splash duration timer
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
    });

    testWidgets('provides all 5 core providers and NetworkMonitorService in widget tree',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final resolvedLocale = Provider.of<LocaleProvider>(context, listen: false);
              final resolvedAuth = Provider.of<AuthProvider>(context, listen: false);
              final resolvedCrop = Provider.of<CropProvider>(context, listen: false);
              final resolvedDiagnosis =
                  Provider.of<DiagnosisProvider>(context, listen: false);
              final resolvedHistory =
                  Provider.of<HistoryProvider>(context, listen: false);
              final resolvedNetwork =
                  Provider.of<NetworkMonitorService>(context, listen: false);

              final allPresent = resolvedLocale.currentLocale.languageCode.isNotEmpty &&
                  resolvedCrop.supportedCrops.isNotEmpty &&
                  resolvedDiagnosis.errorMessage == null &&
                  resolvedHistory.errorMessage == null &&
                  resolvedAuth.errorMessage == null &&
                  (resolvedNetwork.isOnline || !resolvedNetwork.isOnline);

              return Scaffold(
                body: Center(
                  child: Text(allPresent ? 'ALL_PROVIDERS_READY' : 'MISSING_PROVIDERS'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        PlantenApp(
          routerConfig: testRouter,
          prefs: prefs,
          localStorageService: localStorage,
          networkMonitorService: networkMonitor,
          localeProvider: localeProvider,
          authProvider: authProvider,
          cropProvider: cropProvider,
          diagnosisProvider: diagnosisProvider,
          historyProvider: historyProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALL_PROVIDERS_READY'), findsOneWidget);
    });

    testWidgets('reactively switches language between English and Hindi',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text('APP_TAGLINE: ${l10n.appTagline}'),
                    Text('LOGIN_TEXT: ${l10n.login}'),
                  ],
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        PlantenApp(
          routerConfig: testRouter,
          prefs: prefs,
          localStorageService: localStorage,
          networkMonitorService: networkMonitor,
          localeProvider: localeProvider,
          authProvider: authProvider,
          cropProvider: cropProvider,
          diagnosisProvider: diagnosisProvider,
          historyProvider: historyProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Initial English verification
      expect(find.text('APP_TAGLINE: Your AI Crop Doctor'), findsOneWidget);
      expect(find.text('LOGIN_TEXT: Login'), findsOneWidget);

      // Switch to Hindi
      await localeProvider.setLocale(const Locale('hi'));
      await tester.pumpAndSettle();

      // Vernacular Hindi verification
      expect(find.text('APP_TAGLINE: आपका डिजिटल फसल डॉक्टर'), findsOneWidget);
      expect(find.text('LOGIN_TEXT: लॉग इन करें'), findsOneWidget);
    });

    testWidgets('navigates route lifecycle to in-app disclaimer screen',
        (WidgetTester tester) async {
      final testRouter = AppRouter.createRouter(initialLocation: AppRoutes.disclaimer);

      await tester.pumpWidget(
        PlantenApp(
          routerConfig: testRouter,
          prefs: prefs,
          localStorageService: localStorage,
          networkMonitorService: networkMonitor,
          localeProvider: localeProvider,
          authProvider: authProvider,
          cropProvider: cropProvider,
          diagnosisProvider: diagnosisProvider,
          historyProvider: historyProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DisclaimerScreen), findsOneWidget);
      expect(find.text('Legal Disclaimer & Advisory'), findsOneWidget);
    });

    testWidgets('supports instantiation with default parameters',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('DEFAULT_BOOT_SUCCESS'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        PlantenApp(
          routerConfig: testRouter,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DEFAULT_BOOT_SUCCESS'), findsOneWidget);
    });

    testWidgets('MyApp alias functions identically for backward compatibility',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('MYAPP_ALIAS_SUCCESS'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MyApp(
          routerConfig: testRouter,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MYAPP_ALIAS_SUCCESS'), findsOneWidget);
    });

    test('setupGlobalErrorHandling registers FlutterError.onError handler', () {
      setupGlobalErrorHandling();

      expect(FlutterError.onError, isNotNull);

      // Verify invocation doesn't throw
      final details = FlutterErrorDetails(
        exception: Exception('Test Global Planten Error Boundary'),
        stack: StackTrace.current,
      );

      expect(() => FlutterError.onError!(details), returnsNormally);
    });
  });
}
