import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider (Task 27)', () {
    late LocalStorageService localStorage;
    late UserProfileService profileService;
    late AuthService authService;
    late AuthProvider authProvider;

    final sampleProfile = FarmerProfile(
      uid: 'farmer-777',
      phoneNumber: '+919876543210',
      name: 'Balwinder Singh',
      village: 'Samana',
      district: 'Patiala',
      state: 'Punjab',
      primaryCrops: ['wheat', 'potato'],
      photoBackupOptIn: false,
      createdAt: DateTime.utc(2026, 3, 1),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      localStorage = LocalStorageService(prefs: prefs);
      profileService = UserProfileService(localStorageService: localStorage);
      authService = AuthService();
      authProvider = AuthProvider(
        authService: authService,
        userProfileService: profileService,
      );
    });

    tearDown(() {
      authProvider.dispose();
    });

    test('initializes with clean unauthenticated state', () {
      expect(authProvider.user, isNull);
      expect(authProvider.profile, isNull);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.otpSent, false);
      expect(authProvider.verificationId, isNull);
      expect(authProvider.pendingPhoneNumber, isNull);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isProfileComplete, false);
    });

    test('loads cached profile from LocalStorageService on startup', () async {
      await localStorage.saveUserProfile(sampleProfile);

      final providerWithCache = AuthProvider(
        authService: authService,
        userProfileService: profileService,
      );

      expect(providerWithCache.profile, isNotNull);
      expect(providerWithCache.profile?.name, 'Balwinder Singh');
      expect(providerWithCache.isAuthenticated, true);
      expect(providerWithCache.isProfileComplete, true);

      providerWithCache.dispose();
    });

    test('sendOtp rejects invalid phone numbers (<10 digits)', () async {
      bool notified = false;
      authProvider.addListener(() => notified = true);

      final result = await authProvider.sendOtp('12345');
      expect(result, false);
      expect(notified, true);
      expect(authProvider.errorMessage, 'Please enter a valid phone number.');
      expect(authProvider.otpSent, false);
    });

    test('sendOtp handles client-unavailable failure gracefully', () async {
      final result = await authProvider.sendOtp('9876543210');
      expect(result, false);
      expect(authProvider.otpSent, false);
      expect(authProvider.errorMessage, contains('unavailable'));
    });

    test('verifyOtp fails if verification session is not initiated', () async {
      final result = await authProvider.verifyOtp('123456');
      expect(result, false);
      expect(authProvider.errorMessage, contains('session expired'));
    });

    test('updateProfile updates state and local storage', () async {
      final success = await authProvider.updateProfile(sampleProfile);
      expect(success, true);
      expect(authProvider.profile, isNotNull);
      expect(authProvider.profile?.name, 'Balwinder Singh');
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isProfileComplete, true);
    });

    test('clearError resets error message and notifies listeners', () async {
      await authProvider.sendOtp('123');
      expect(authProvider.errorMessage, isNotNull);

      bool notified = false;
      authProvider.addListener(() => notified = true);

      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
      expect(notified, true);
    });

    test('resetOtpState resets OTP flow state', () {
      authProvider.resetOtpState();
      expect(authProvider.otpSent, false);
      expect(authProvider.verificationId, isNull);
      expect(authProvider.pendingPhoneNumber, isNull);
      expect(authProvider.errorMessage, isNull);
    });

    test('loginWithEmail handles client-unavailable failure gracefully', () async {
      final result = await authProvider.loginWithEmail(
        'test@planten.org',
        'password123',
      );
      expect(result, false);
      expect(authProvider.errorMessage, contains('unavailable'));
    });

    test('registerWithEmail handles client-unavailable failure gracefully', () async {
      final result = await authProvider.registerWithEmail(
        'test@planten.org',
        'password123',
      );
      expect(result, false);
      expect(authProvider.errorMessage, contains('unavailable'));
    });

    test('loginWithGoogle handles client-unavailable failure gracefully', () async {
      final result = await authProvider.loginWithGoogle();
      expect(result, false);
      expect(authProvider.errorMessage, contains('unavailable'));
    });

    test('sendPasswordReset rejects empty email and notifies error', () async {
      final result = await authProvider.sendPasswordReset('   ');
      expect(result, false);
      expect(authProvider.errorMessage, 'Please enter your email address.');
    });

    test('logout clears user, profile, and cached storage', () async {
      await authProvider.updateProfile(sampleProfile);
      expect(authProvider.isAuthenticated, true);

      await authProvider.logout();
      expect(authProvider.user, isNull);
      expect(authProvider.profile, isNull);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.otpSent, false);
      expect(localStorage.getUserProfile(), isNull);
    });
  });
}
