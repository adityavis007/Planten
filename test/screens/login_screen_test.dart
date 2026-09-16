import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/auth/login_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';
import 'package:planten/widgets/app_button.dart';
import 'package:planten/widgets/language_toggle_widget.dart';

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

  Widget buildTestableLoginScreen({AuthProvider? customAuth}) {
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
        home: LoginScreen(authProvider: customAuth ?? authProvider),
      ),
    );
  }

  group('LoginScreen (Email/Password & Google Sign-In)', () {
    testWidgets(
      'renders brand emblem, title, tagline, language toggle, email and password fields',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableLoginScreen());
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('app_logo_emblem')), findsOneWidget);
        expect(find.text('Planten'), findsOneWidget);
        expect(find.text('Your AI Crop Doctor'), findsOneWidget);
        expect(find.byType(LanguageToggleWidget), findsOneWidget);
        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);
        expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
        expect(find.byKey(const Key('login_google_button')), findsOneWidget);
        expect(
          find.byKey(const Key('login_forgot_password_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('login_to_signup_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows validation error when email is empty or invalid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      final loginBtn = find.byKey(const Key('login_submit_button'));
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid email address'),
        findsOneWidget,
      );

      final emailField = find.byKey(const Key('login_email_field'));
      await tester.enterText(emailField, 'notanemail');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid email address'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error when password is empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('login_email_field'));
      await tester.enterText(emailField, 'farmer@example.com');

      final loginBtn = find.byKey(const Key('login_submit_button'));
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('toggles password visibility with eye icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      final toggleBtn = find.byKey(
        const Key('login_password_visibility_toggle'),
      );
      expect(toggleBtn, findsOneWidget);

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('tapping forgot password opens reset dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      final forgotBtn = find.byKey(
        const Key('login_forgot_password_button'),
      );
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byKey(const Key('reset_email_field')), findsOneWidget);
      expect(
        find.byKey(const Key('submit_reset_password_button')),
        findsOneWidget,
      );
    });

    testWidgets('displays error banner when AuthProvider has error message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      await tester.enterText(emailField, 'farmer@example.com');
      await tester.enterText(passwordField, 'secret123');

      final loginBtn = find.byKey(const Key('login_submit_button'));
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Because live Firebase is not configured in tests, error is reported in banner
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders AppButton correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byType(AppButton), findsOneWidget);
    });
  });
}
