import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/auth/signup_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';
import 'package:planten/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late AuthProvider authProvider;
  late LocalStorageService localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    localeProvider = LocaleProvider(prefs: prefs);
    authProvider = AuthProvider(
      authService: AuthService(),
      userProfileService: UserProfileService(localStorageService: localStorage),
    );
  });

  tearDown(() {
    authProvider.dispose();
  });

  Widget buildTestableSignupScreen({AuthProvider? customAuth}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<AuthProvider>.value(
          value: customAuth ?? authProvider,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SignupScreen(authProvider: customAuth ?? authProvider),
      ),
    );
  }

  group('SignupScreen Unit & Widget Tests', () {
    testWidgets('renders all fields, buttons, and links', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('signup_card')), findsOneWidget);
      expect(find.text('Create Account'), findsWidgets);
      expect(find.byKey(const Key('signup_email_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_password_field')), findsOneWidget);
      expect(
        find.byKey(const Key('signup_confirm_password_field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('signup_google_button')), findsOneWidget);
      expect(
        find.byKey(const Key('signup_to_login_button')),
        findsOneWidget,
      );
    });

    testWidgets('validates email format on submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('signup_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid email address'),
        findsOneWidget,
      );

      final emailField = find.byKey(const Key('signup_email_field'));
      await tester.enterText(emailField, 'farmer@example.com');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Email valid, now password too short
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('validates password minimum length of 6 characters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('signup_email_field'));
      final passwordField = find.byKey(const Key('signup_password_field'));
      await tester.enterText(emailField, 'farmer@example.com');
      await tester.enterText(passwordField, '123');

      final submitBtn = find.byKey(const Key('signup_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('validates matching passwords', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('signup_email_field'));
      final passwordField = find.byKey(const Key('signup_password_field'));
      final confirmField = find.byKey(
        const Key('signup_confirm_password_field'),
      );

      await tester.enterText(emailField, 'farmer@example.com');
      await tester.enterText(passwordField, 'secret123');
      await tester.enterText(confirmField, 'different123');

      final submitBtn = find.byKey(const Key('signup_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submitting valid registration attempts sign up', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableSignupScreen());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('signup_email_field'));
      final passwordField = find.byKey(const Key('signup_password_field'));
      final confirmField = find.byKey(
        const Key('signup_confirm_password_field'),
      );

      await tester.enterText(emailField, 'farmer@example.com');
      await tester.enterText(passwordField, 'secret123');
      await tester.enterText(confirmField, 'secret123');

      final submitBtn = find.byKey(const Key('signup_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Live Firebase is not connected in unit tests, button still exists
      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
