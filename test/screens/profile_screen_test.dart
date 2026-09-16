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
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/history_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/providers/theme_provider.dart';
import 'package:planten/screens/profile/profile_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/firestore_sync_service.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';
import 'package:planten/widgets/language_toggle_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late ThemeProvider themeProvider;
  late AuthProvider authProvider;
  late HistoryProvider historyProvider;
  late CropProvider cropProvider;
  late LocalStorageService localStorage;
  late UserProfileService userProfileService;
  late HistoryService historyService;

  final sampleProfile = FarmerProfile(
    uid: 'farmer-456',
    phoneNumber: '+919876543210',
    name: 'Ramesh Patel',
    village: 'Kheda',
    district: 'Anand',
    state: 'Gujarat',
    primaryCrops: ['tomato', 'wheat'],
    photoBackupOptIn: false,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    userProfileService = UserProfileService(localStorageService: localStorage);
    historyService = HistoryService(localStorageService: localStorage);
    localeProvider = LocaleProvider(prefs: prefs);
    themeProvider = ThemeProvider(prefs: prefs);

    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: userProfileService,
    );
    await authProvider.updateProfile(sampleProfile);

    historyProvider = HistoryProvider(
      historyService: historyService,
      autoLoad: true,
    );

    cropProvider = CropProvider(localStorageService: localStorage);
  });

  tearDown(() {
    authProvider.dispose();
    historyProvider.dispose();
    cropProvider.dispose();
    themeProvider.dispose();
  });

  Widget buildTestableProfileScreen({
    AuthProvider? customAuth,
    HistoryProvider? customHistory,
    CropProvider? customCrop,
    ThemeProvider? customTheme,
    FirestoreSyncService? customSync,
    VoidCallback? onEditDetailsTap,
    VoidCallback? onLoggedOut,
    Locale locale = const Locale('en'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(
            value: customTheme ?? themeProvider),
        ChangeNotifierProvider<AuthProvider>.value(
            value: customAuth ?? authProvider),
        ChangeNotifierProvider<HistoryProvider>.value(
            value: customHistory ?? historyProvider),
        ChangeNotifierProvider<CropProvider>.value(
            value: customCrop ?? cropProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: ProfileScreen(
          authProvider: customAuth ?? authProvider,
          historyProvider: customHistory ?? historyProvider,
          cropProvider: customCrop ?? cropProvider,
          themeProvider: customTheme ?? themeProvider,
          syncService: customSync,
          onEditDetailsTap: onEditDetailsTap,
          onLoggedOut: onLoggedOut,
        ),
      ),
    );
  }

  group('ProfileScreen (Task 52) Unit & Widget Tests', () {
    testWidgets('renders farmer details, name, phone, and location', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Farmer Profile'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('Kheda, Anand, Gujarat'), findsOneWidget);
      expect(find.byKey(const Key('edit_profile_button')), findsOneWidget);
    });

    testWidgets('tapping Edit Details invokes onEditDetailsTap callback', (tester) async {
      bool editTapped = false;
      await tester.pumpWidget(buildTestableProfileScreen(
        onEditDetailsTap: () => editTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });

    testWidgets('renders all primary crop chips with selected states matching profile', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('My Primary Crops'), findsOneWidget);

      // Verify all 5 launch crops appear
      expect(find.byKey(const Key('crop_chip_tomato')), findsOneWidget);
      expect(find.byKey(const Key('crop_chip_wheat')), findsOneWidget);
      expect(find.byKey(const Key('crop_chip_potato')), findsOneWidget);
      expect(find.byKey(const Key('crop_chip_chili')), findsOneWidget);
      expect(find.byKey(const Key('crop_chip_cotton')), findsOneWidget);

      // Verify selected state
      final tomatoChip = tester.widget<FilterChip>(find.byKey(const Key('crop_chip_tomato')));
      final wheatChip = tester.widget<FilterChip>(find.byKey(const Key('crop_chip_wheat')));
      final potatoChip = tester.widget<FilterChip>(find.byKey(const Key('crop_chip_potato')));

      expect(tomatoChip.selected, isTrue);
      expect(wheatChip.selected, isTrue);
      expect(potatoChip.selected, isFalse);
    });

    testWidgets('tapping a crop chip toggles selection and updates profile', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      // Tap Potato to add it
      await tester.tap(find.byKey(const Key('crop_chip_potato')));
      await tester.pumpAndSettle();

      expect(authProvider.profile?.primaryCrops, contains('potato'));

      // Tap Potato again to remove it
      await tester.tap(find.byKey(const Key('crop_chip_potato')));
      await tester.pumpAndSettle();

      expect(authProvider.profile?.primaryCrops.contains('potato'), isFalse);
    });

    testWidgets('attempting to deselect the only crop displays validation message', (tester) async {
      // Set profile with only one crop
      final singleCropProfile = sampleProfile.copyWith(primaryCrops: ['tomato']);
      await authProvider.updateProfile(singleCropProfile);

      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      // Attempt to deselect tomato
      await tester.tap(find.byKey(const Key('crop_chip_tomato')));
      await tester.pumpAndSettle();

      expect(find.text('At least one primary crop must be selected.'), findsOneWidget);
      expect(authProvider.profile?.primaryCrops, contains('tomato'));
    });

    testWidgets('deselecting active crop switches CropProvider to remaining primary crop', (tester) async {
      // Profile has tomato and wheat. Active crop is tomato.
      await cropProvider.selectCropById('tomato');
      expect(cropProvider.selectedCropId, 'tomato');

      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      // Deselect tomato
      await tester.tap(find.byKey(const Key('crop_chip_tomato')));
      await tester.pumpAndSettle();

      // Remaining crop is wheat
      expect(authProvider.profile?.primaryCrops, equals(['wheat']));
      expect(cropProvider.selectedCropId, 'wheat');
    });

    testWidgets('renders App Theme tile and profile_theme_toggle switcher', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('App Theme'), findsOneWidget);
      expect(find.byKey(const Key('profile_theme_toggle')), findsOneWidget);
      expect(find.text('Light mode active'), findsOneWidget);

      // Verify toggling to Dark mode
      await tester.tap(find.byKey(const Key('theme_dark_btn')));
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, isTrue);
      expect(find.text('Dark mode active'), findsOneWidget);

      // Verify toggling back to Light mode
      await tester.tap(find.byKey(const Key('theme_light_btn')));
      await tester.pumpAndSettle();

      expect(themeProvider.isLightMode, isTrue);
      expect(find.text('Light mode active'), findsOneWidget);

      // Verify LanguageToggleWidget is only rendered in AppBar header, not duplicated in body
      expect(find.byType(LanguageToggleWidget), findsOneWidget);
    });

    testWidgets('toggling photo backup switch updates profile privacy setting', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('photo_backup_switch'));
      expect(switchFinder, findsOneWidget);

      final initialSwitch = tester.widget<Switch>(switchFinder);
      expect(initialSwitch.value, isFalse);

      // Toggle switch ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(authProvider.profile?.photoBackupOptIn, isTrue);

      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, isTrue);
    });

    testWidgets('renders all scans synced state when unsyncedCount is 0', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('All scans synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      expect(find.byKey(const Key('profile_sync_now_button')), findsNothing);
    });

    testWidgets('renders pending sync state and Sync Now CTA when unsynced scans exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Save an unsynced scan
      await historyService.saveScan(DiagnosisResult(
        id: 'scan-pending-1',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        diseaseNameEn: 'Early Blight',
        diseaseNameHi: 'अगेती झुलसा',
        confidenceScore: 0.90,
        severity: SeverityLevel.medium,
        timestamp: DateTime.now(),
        localImagePath: '',
        isSynced: false,
      ));
      await historyProvider.loadHistory();

      bool syncTriggered = false;
      final testSyncService = FirestoreSyncService(
        historyService: historyService,
        batchWriter: (records) async {
          syncTriggered = true;
        },
      );

      await tester.pumpWidget(buildTestableProfileScreen(
        customSync: testSyncService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 scan(s) waiting for internet'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);

      final syncBtn = find.byKey(const Key('profile_sync_now_button'));
      expect(syncBtn, findsOneWidget);
      await tester.tap(syncBtn);
      await tester.pumpAndSettle();

      expect(syncTriggered, isTrue);
    });

    testWidgets('tapping disclaimer tile opens disclaimer dialog', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      // Scroll down if necessary
      await tester.scrollUntilVisible(
        find.byKey(const Key('disclaimer_tile')),
        100.0,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('disclaimer_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('disclaimer_dialog')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('disclaimer_dialog')),
          matching: find.text('Legal Disclaimer & Advisory'),
        ),
        findsOneWidget,
      );
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('disclaimer_dialog')), findsNothing);
    });

    testWidgets('tapping Log Out shows confirmation dialog, cancelling dismisses dialog', (tester) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      // Scroll to logout button
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout_button')),
        100.0,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('logout_dialog')), findsOneWidget);

      // Tap cancel
      await tester.tap(find.byKey(const Key('cancel_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('logout_dialog')), findsNothing);
      expect(authProvider.profile, isNotNull);
    });

    testWidgets('confirming Log Out executes logout and invokes callback', (tester) async {
      bool loggedOutCalled = false;
      await tester.pumpWidget(buildTestableProfileScreen(
        onLoggedOut: () => loggedOutCalled = true,
      ));
      await tester.pumpAndSettle();

      // Scroll to logout button
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout_button')),
        100.0,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();

      // Confirm logout
      await tester.tap(find.byKey(const Key('confirm_logout_button')));
      await tester.pumpAndSettle();

      expect(loggedOutCalled, isTrue);
      expect(authProvider.profile, isNull);
    });

    testWidgets('renders Hindi vernacular localization properly', (tester) async {
      await localeProvider.setLocale(const Locale('hi'));
      await tester.pumpWidget(buildTestableProfileScreen(
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('किसान प्रोफाइल'), findsOneWidget);
      expect(find.text('मेरी मुख्य फसलें'), findsOneWidget);
      expect(find.text('टमाटर'), findsOneWidget);
      expect(find.text('गेहूं'), findsOneWidget);
      expect(find.text('आलू'), findsOneWidget);
      expect(find.text('मिर्च'), findsOneWidget);
      expect(find.text('कपास'), findsOneWidget);
      expect(find.text('ऐप थीम'), findsOneWidget);
      expect(find.text('क्लाउड फोटो बैकअप'), findsOneWidget);
      expect(find.text('सभी जांच सिंक हैं'), findsOneWidget);
      expect(find.text('कानूनी अस्वीकरण व सलाह'), findsOneWidget);
    });

    testWidgets('integrates with GoRouter at AppRoutes.profile', (tester) async {
      final testRouter = GoRouter(
        initialLocation: AppRoutes.profile,
        routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => ProfileScreen(
              authProvider: authProvider,
              historyProvider: historyProvider,
              cropProvider: cropProvider,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farmer Profile'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
    });
  });
}
