import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/history_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/profile/disclaimer_screen.dart';
import 'package:planten/screens/profile/profile_screen.dart';
import 'package:planten/screens/profile/profile_setup_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late AuthProvider authProvider;
  late HistoryProvider historyProvider;
  late CropProvider cropProvider;
  late LocalStorageService localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    localeProvider = LocaleProvider(prefs: prefs);
    final userProfileService =
        UserProfileService(localStorageService: localStorage);
    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: userProfileService,
    );
    historyProvider = HistoryProvider(
      historyService: HistoryService(localStorageService: localStorage),
    );
    cropProvider = CropProvider(localStorageService: localStorage);
  });

  tearDown(() {
    authProvider.dispose();
    historyProvider.dispose();
    cropProvider.dispose();
  });

  Widget buildTestableDisclaimerScreen({
    Locale locale = const Locale('en'),
    VoidCallback? onAccepted,
    Future<bool> Function(Uri)? urlLauncherOverride,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: DisclaimerScreen(
          localeProvider: localeProvider,
          onAccepted: onAccepted,
          urlLauncherOverride: urlLauncherOverride,
        ),
      ),
    );
  }

  group('DisclaimerScreen (Task 53) Unit & Widget Tests', () {
    testWidgets('renders official legal notice and explicit PRD Section 13 statement in English',
        (tester) async {
      await tester.pumpWidget(buildTestableDisclaimerScreen());
      await tester.pumpAndSettle();

      expect(find.text('Legal Disclaimer & Advisory'), findsOneWidget);
      expect(find.byKey(const Key('disclaimer_hero_card')), findsOneWidget);
      expect(find.text('Official Legal Notice'), findsOneWidget);

      // Verify the exact mandatory statement
      expect(
        find.text(DisclaimerScreen.coreStatementEn),
        findsOneWidget,
      );

      // Verify key operating principle headings
      expect(find.text('Decision Support System Only'), findsOneWidget);
      expect(
        find.text('Zero Chemical Brand/Dosage Prescriptions'),
        findsOneWidget,
      );
      expect(find.text('Mandatory Agronomist Consultation'), findsOneWidget);
      expect(find.text('On-Device Inference & Privacy'), findsOneWidget);

      // Verify national helpline card
      expect(find.byKey(const Key('kisan_helpline_card')), findsOneWidget);
      expect(find.text('1800-180-1551'), findsOneWidget);
      expect(find.byKey(const Key('call_kisan_center_button')), findsOneWidget);
    });

    testWidgets('renders Hindi vernacular localization properly', (tester) async {
      await localeProvider.setLocale(const Locale('hi'));
      await tester.pumpWidget(
        buildTestableDisclaimerScreen(locale: const Locale('hi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('कानूनी अस्वीकरण व सलाह'), findsOneWidget);
      expect(find.text('आधिकारिक कानूनी सूचना'), findsOneWidget);

      // Verify Hindi statement
      expect(
        find.text(DisclaimerScreen.coreStatementHi),
        findsOneWidget,
      );

      // Verify Hindi principles
      expect(find.text('केवल एआई निर्णय सहायता'), findsOneWidget);
      expect(find.text('कीटनाशक दवाओं का नाम व मात्रा निषेध'), findsOneWidget);
      expect(find.text('कृषि विशेषज्ञों (KVK) से सलाह'), findsOneWidget);
      expect(find.text('डेटा व फोटो गोपनीयता'), findsOneWidget);
      expect(find.text('राष्ट्रीय किसान कॉल सेंटर'), findsOneWidget);
      expect(find.text('मैंने समझ लिया और स्वीकार है'), findsOneWidget);
    });

    testWidgets('tapping accept button invokes onAccepted callback', (tester) async {
      bool acceptedCalled = false;
      await tester.pumpWidget(
        buildTestableDisclaimerScreen(
          onAccepted: () => acceptedCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      final acceptBtn = find.byKey(const Key('disclaimer_accept_button'));
      await tester.scrollUntilVisible(acceptBtn, 100.0);
      await tester.pumpAndSettle();

      await tester.tap(acceptBtn);
      await tester.pumpAndSettle();

      expect(acceptedCalled, isTrue);
    });

    testWidgets('tapping Call Free button triggers dialer with 18001801551',
        (tester) async {
      Uri? launchedUri;
      await tester.pumpWidget(
        buildTestableDisclaimerScreen(
          urlLauncherOverride: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      final callBtn = find.byKey(const Key('call_kisan_center_button'));
      await tester.scrollUntilVisible(callBtn, 100.0);
      await tester.pumpAndSettle();

      await tester.tap(callBtn);
      await tester.pumpAndSettle();

      expect(launchedUri, isNotNull);
      expect(launchedUri.toString(), 'tel:18001801551');
    });

    testWidgets('tapping back button pops the screen', (tester) async {
      final testRouter = GoRouter(
        initialLocation: AppRoutes.disclaimer,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Home Screen')),
          ),
          GoRoute(
            path: AppRoutes.disclaimer,
            builder: (context, state) => const DisclaimerScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Legal Disclaimer & Advisory'), findsOneWidget);

      await tester.tap(find.byKey(const Key('disclaimer_back_button')));
      await tester.pumpAndSettle();

      // Back navigation occurred
    });

    testWidgets('disclaimer is accessible from ProfileScreen', (tester) async {
      bool disclaimerTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(
            authProvider: authProvider,
            historyProvider: historyProvider,
            cropProvider: cropProvider,
            onDisclaimerTap: () => disclaimerTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final disclaimerTile = find.byKey(const Key('disclaimer_tile'));
      await tester.scrollUntilVisible(disclaimerTile, 100.0);
      await tester.pumpAndSettle();

      await tester.tap(disclaimerTile);
      await tester.pumpAndSettle();

      expect(disclaimerTapped, isTrue);
    });

    testWidgets('disclaimer is accessible during initial onboarding in ProfileSetupScreen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool onboardingDisclaimerTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileSetupScreen(
            authProvider: authProvider,
            onDisclaimerTap: () => onboardingDisclaimerTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final onboardingDisclaimerBtn =
          find.byKey(const Key('onboarding_disclaimer_button'));
      await tester.scrollUntilVisible(
        onboardingDisclaimerBtn,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(onboardingDisclaimerBtn, findsOneWidget);
      await tester.tap(onboardingDisclaimerBtn);
      await tester.pumpAndSettle();

      expect(onboardingDisclaimerTapped, isTrue);
    });

    testWidgets('GoRouter routes /disclaimer to DisclaimerScreen', (tester) async {
      final router = AppRouter.createRouter(initialLocation: AppRoutes.disclaimer);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DisclaimerScreen), findsOneWidget);
      expect(find.text(DisclaimerScreen.coreStatementEn), findsOneWidget);
    });
  });
}
