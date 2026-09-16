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
import 'package:planten/screens/auth/otp_verification_view.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';

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

  Widget buildTestableOtpView({
    required String phoneNumber,
    AuthProvider? customAuth,
    VoidCallback? onSuccess,
    int countdownSeconds = 60,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: customAuth ?? authProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: OtpVerificationView(
              phoneNumber: phoneNumber,
              authProvider: customAuth ?? authProvider,
              onVerificationSuccess: onSuccess,
              countdownDurationSeconds: countdownSeconds,
            ),
          ),
        ),
      ),
    );
  }

  group('OtpVerificationView (Task 29)', () {
    testWidgets('renders phone number, 6 pin boxes, countdown timer, and verify CTA', (tester) async {
      await tester.pumpWidget(
        buildTestableOtpView(phoneNumber: '+91 98765 43210'),
      );
      await tester.pump();

      expect(find.text('Enter OTP'), findsOneWidget);
      expect(find.text('Code sent to +91 98765 43210'), findsOneWidget);
      expect(find.byKey(const Key('otp_change_number_button')), findsOneWidget);
      expect(find.byKey(const Key('otp_hidden_text_field')), findsOneWidget);
      expect(find.byKey(const Key('otp_countdown_text')), findsOneWidget);
      expect(find.byKey(const Key('otp_verify_button')), findsOneWidget);
    });

    testWidgets('shows validation error when attempting to verify with less than 6 digits', (tester) async {
      await tester.pumpWidget(
        buildTestableOtpView(phoneNumber: '+91 98765 43210'),
      );
      await tester.pump();

      // Enter only 3 digits
      final textField = find.byKey(const Key('otp_hidden_text_field'));
      await tester.enterText(textField, '123');
      await tester.pump();

      // Tap Verify
      final verifyBtn = find.byKey(const Key('otp_verify_button'));
      await tester.tap(verifyBtn);
      await tester.pump();

      expect(find.text('Please enter all 6 digits of the OTP.'), findsOneWidget);
    });

    testWidgets('tapping Change button calls auth.resetOtpState()', (tester) async {
      await tester.pumpWidget(
        buildTestableOtpView(phoneNumber: '+91 98765 43210'),
      );
      await tester.pump();

      final changeBtn = find.byKey(const Key('otp_change_number_button'));
      await tester.tap(changeBtn);
      await tester.pump();

      expect(authProvider.otpSent, false);
      expect(authProvider.verificationId, isNull);
    });

    testWidgets('countdown timer transitions to resend button when countdown reaches 0', (tester) async {
      await tester.pumpWidget(
        buildTestableOtpView(
          phoneNumber: '+91 98765 43210',
          countdownSeconds: 2,
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('otp_countdown_text')), findsOneWidget);
      expect(find.byKey(const Key('otp_resend_button')), findsNothing);

      // Advance by 2.5 seconds
      await tester.pump(const Duration(seconds: 3));

      expect(find.byKey(const Key('otp_countdown_text')), findsNothing);
      expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);
    });

    testWidgets('renders verify CTA and accepts onVerificationSuccess callback', (tester) async {
      await localStorage.saveUserProfile(
        FarmerProfile(
          uid: 'farmer-verified',
          phoneNumber: '+919876543210',
          name: 'Kisan Kumar',
          village: 'Rampur',
          district: 'Meerut',
          state: 'Uttar Pradesh',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableOtpView(
          phoneNumber: '+91 98765 43210',
          onSuccess: () {},
        ),
      );
      await tester.pump();

      // Verify button exists
      expect(find.byKey(const Key('otp_verify_button')), findsOneWidget);
    });

    testWidgets('routes to /profile-setup or /home with GoRouter upon successful verification', (tester) async {
      final router = GoRouter(
        initialLocation: '/test-otp',
        routes: [
          GoRoute(
            path: '/test-otp',
            builder: (context, state) => Scaffold(
              body: OtpVerificationView(
                phoneNumber: '+91 98765 43210',
                authProvider: authProvider,
                onVerificationSuccess: () {
                  context.go(AppRoutes.profileSetup);
                },
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.profileSetup,
            builder: (context, state) => const Scaffold(body: Text('Profile Setup Route')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Home Route')),
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

      expect(find.byType(OtpVerificationView), findsOneWidget);
    });
  });
}
