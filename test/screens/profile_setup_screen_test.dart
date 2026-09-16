import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/profile/profile_setup_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late AuthProvider authProvider;
  late LocalStorageService localStorage;
  late UserProfileService userProfileService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    userProfileService =
        UserProfileService(localStorageService: localStorage);
    localeProvider = LocaleProvider(prefs: prefs);
    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: userProfileService,
    );
  });

  tearDown(() {
    authProvider.dispose();
  });

  Widget buildTestableProfileSetupScreen({
    AuthProvider? customAuth,
    VoidCallback? onSaved,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<AuthProvider>.value(
            value: customAuth ?? authProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ProfileSetupScreen(
          authProvider: customAuth ?? authProvider,
          onSaved: onSaved,
        ),
      ),
    );
  }

  group('ProfileSetupScreen (Task 30)', () {
    testWidgets('renders all profile fields, crop chips, and default OFF privacy toggle',
        (tester) async {
      await tester.pumpWidget(buildTestableProfileSetupScreen());
      await tester.pump();

      // Verify Screen Header
      expect(find.text('Farmer Profile'), findsOneWidget);
      expect(find.text('Complete Your Farm Profile'), findsOneWidget);

      // Verify Text Form Fields
      expect(find.text('Farmer Name'), findsOneWidget);
      expect(find.text('Village'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);

      // Verify All 5 V1 Crop Chips
      expect(find.byKey(const ValueKey('crop_chip_tomato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_chip_potato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_chip_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_chip_chili')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_chip_cotton')), findsOneWidget);

      // Verify Privacy Toggle (Cloud Photo Backup) strictly defaults to false (OFF)
      final switchFinder = find.byKey(const ValueKey('photo_backup_switch'));
      expect(switchFinder, findsOneWidget);
      final Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);

      // Verify Save & Continue Button
      expect(find.byKey(const ValueKey('save_profile_button')), findsOneWidget);
    });

    testWidgets('displays validation errors when mandatory fields and crops are empty',
        (tester) async {
      await tester.pumpWidget(buildTestableProfileSetupScreen());
      await tester.pump();

      // Tap Save without entering any values
      final saveBtn = find.byKey(const ValueKey('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // Check field validation error messages
      expect(find.text('Please enter a valid farmer name (min 2 characters).'),
          findsOneWidget);
      expect(find.text('Please enter your village.'), findsOneWidget);
      expect(find.text('Please enter district.'), findsOneWidget);
      expect(find.text('Please enter state.'), findsOneWidget);
      expect(find.text('Please select at least one crop you cultivate.'),
          findsOneWidget);
    });

    testWidgets('allows multi-selecting and deselecting crop chips',
        (tester) async {
      await tester.pumpWidget(buildTestableProfileSetupScreen());
      await tester.pump();

      final tomatoChip = find.byKey(const ValueKey('crop_chip_tomato'));
      final wheatChip = find.byKey(const ValueKey('crop_chip_wheat'));

      // Initially 0 selected
      expect(find.text('0 selected'), findsOneWidget);

      // Tap Tomato
      await tester.ensureVisible(tomatoChip);
      await tester.tap(tomatoChip);
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      // Tap Wheat
      await tester.ensureVisible(wheatChip);
      await tester.tap(wheatChip);
      await tester.pump();
      expect(find.text('2 selected'), findsOneWidget);

      // Deselect Tomato
      await tester.tap(tomatoChip);
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('allows toggling cloud photo backup opt-in switch',
        (tester) async {
      await tester.pumpWidget(buildTestableProfileSetupScreen());
      await tester.pump();

      final switchFinder = find.byKey(const ValueKey('photo_backup_switch'));
      await tester.ensureVisible(switchFinder);

      // Initially false
      Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);

      // Toggle switch to true
      await tester.tap(switchFinder);
      await tester.pump();

      switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle switch back to false
      await tester.tap(switchFinder);
      await tester.pump();

      switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('pre-populates existing farmer profile data when editing',
        (tester) async {
      final existing = FarmerProfile(
        uid: 'farmer-100',
        phoneNumber: '+919876543210',
        name: 'Harish Patel',
        village: 'Kisan Nagar',
        district: 'Ahmedabad',
        state: 'Gujarat',
        primaryCrops: const ['cotton', 'wheat'],
        photoBackupOptIn: true,
        createdAt: DateTime.now(),
      );
      await authProvider.updateProfile(existing);

      await tester.pumpWidget(
        buildTestableProfileSetupScreen(customAuth: authProvider),
      );
      await tester.pump();

      // Verify pre-populated fields
      expect(find.text('Harish Patel'), findsOneWidget);
      expect(find.text('Kisan Nagar'), findsOneWidget);
      expect(find.text('Ahmedabad'), findsOneWidget);
      expect(find.text('Gujarat'), findsOneWidget);

      // Verify pre-populated crops count
      expect(find.text('2 selected'), findsOneWidget);

      // Verify pre-populated switch
      final switchFinder = find.byKey(const ValueKey('photo_backup_switch'));
      final Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('successfully saves profile and triggers onSaved callback',
        (tester) async {
      bool onSavedTriggered = false;

      await tester.pumpWidget(
        buildTestableProfileSetupScreen(
          onSaved: () {
            onSavedTriggered = true;
          },
        ),
      );
      await tester.pump();

      // Enter all fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(5));

      await tester.enterText(textFields.at(0), 'Aditya Verma');
      await tester.enterText(textFields.at(1), 'Rampur');
      await tester.enterText(textFields.at(2), 'Varanasi');
      await tester.enterText(textFields.at(3), 'Uttar Pradesh');
      await tester.enterText(textFields.at(4), '9876543210');

      // Select Tomato crop chip
      final tomatoChip = find.byKey(const ValueKey('crop_chip_tomato'));
      await tester.ensureVisible(tomatoChip);
      await tester.tap(tomatoChip);
      await tester.pump();

      // Tap Save & Continue
      final saveBtn = find.byKey(const ValueKey('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(onSavedTriggered, isTrue);

      // Check that profile was saved to local storage
      final savedProfile = localStorage.getUserProfile();
      expect(savedProfile, isNotNull);
      expect(savedProfile!.name, 'Aditya Verma');
      expect(savedProfile.village, 'Rampur');
      expect(savedProfile.district, 'Varanasi');
      expect(savedProfile.state, 'Uttar Pradesh');
      expect(savedProfile.primaryCrops, contains('tomato'));
      expect(savedProfile.photoBackupOptIn, isFalse);
    });

    testWidgets('navigates to AppRoutes.home with GoRouter upon successful profile save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: AppRoutes.profileSetup,
        routes: [
          GoRoute(
            path: AppRoutes.profileSetup,
            builder: (context, state) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                const Scaffold(body: Text('Home Dashboard Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
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

      // Fill in valid data
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Rajesh Kumar');
      await tester.enterText(textFields.at(1), 'Sitapur');
      await tester.enterText(textFields.at(2), 'Lucknow');
      await tester.enterText(textFields.at(3), 'Uttar Pradesh');
      await tester.enterText(textFields.at(4), '9876543210');

      // Select Wheat
      final wheatChip = find.byKey(const ValueKey('crop_chip_wheat'));
      await tester.ensureVisible(wheatChip);
      await tester.tap(wheatChip);
      await tester.pump();

      // Submit
      final saveBtn = find.byKey(const ValueKey('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Home Screen should now be displayed
      expect(find.text('Home Dashboard Screen'), findsOneWidget);
    });

    testWidgets('renders avatar picker and opens photo source bottom sheet with Camera and Gallery',
        (tester) async {
      await tester.pumpWidget(buildTestableProfileSetupScreen());
      await tester.pump();

      // Verify Avatar picker widget is present
      final avatarFinder = find.byKey(const Key('profile_avatar_picker'));
      expect(avatarFinder, findsOneWidget);
      expect(find.byKey(const Key('profile_camera_badge')), findsOneWidget);
      expect(find.text('Add Profile Photo'), findsOneWidget);

      // Tap Avatar picker to open modal
      await tester.ensureVisible(avatarFinder);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Verify bottom sheet title and both options: Camera & Gallery
      expect(find.text('Select Profile Photo'), findsOneWidget);
      expect(find.byKey(const Key('photo_picker_camera_tile')), findsOneWidget);
      expect(find.byKey(const Key('photo_picker_gallery_tile')), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Tap Camera tile
      await tester.tap(find.byKey(const Key('photo_picker_camera_tile')));
      await tester.pumpAndSettle();

      // Bottom sheet is dismissed
      expect(find.text('Select Profile Photo'), findsNothing);
    });

    testWidgets('pre-populates existing farmer profile photo and shows Change Photo label',
        (tester) async {
      final existing = FarmerProfile(
        uid: 'farmer-200',
        phoneNumber: '+919876543210',
        name: 'Suresh Kumar',
        village: 'Kisanpur',
        district: 'Varanasi',
        state: 'Uttar Pradesh',
        primaryCrops: const ['potato'],
        profilePhotoPath: '/non/existent/test/path.jpg',
        createdAt: DateTime.now(),
      );
      await authProvider.updateProfile(existing);

      await tester.pumpWidget(
        buildTestableProfileSetupScreen(customAuth: authProvider),
      );
      await tester.pump();

      // Verify profile values
      expect(find.text('Suresh Kumar'), findsOneWidget);
      expect(find.text('Kisanpur'), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
    });
  });
}
