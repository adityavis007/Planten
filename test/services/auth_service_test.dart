import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService (Task 25)', () {
    late AuthService service;

    setUp(() {
      service = AuthService();
    });

    test('initializes with unauthenticated state when Firebase is unconfigured', () {
      expect(service.currentUser, isNull);
      expect(service.currentUid, isNull);
      expect(service.isAuthenticated, false);
      expect(service.authOrNull, isNull);
    });

    test('authStateChanges stream is empty when auth client is unavailable', () async {
      final events = await service.authStateChanges.toList();
      expect(events, isEmpty);
    });

    test('verifyPhoneNumber calls verificationFailed gracefully when client unavailable', () async {
      bool failedCalled = false;
      String? errorCode;

      await service.verifyPhoneNumber(
        phoneNumber: '+919876543210',
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          failedCalled = true;
          errorCode = e.code;
        },
        codeSent: (verificationId, resendToken) {},
        codeAutoRetrievalTimeout: (verificationId) {},
      );

      expect(failedCalled, true);
      expect(errorCode, 'service-unavailable');
    });

    test('signInWithOtp throws FirebaseAuthException when client unavailable', () async {
      expect(
        () => service.signInWithOtp(
          verificationId: 'test-verification-id',
          smsCode: '123456',
        ),
        throwsA(isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'service-unavailable',
        )),
      );
    });

    test('signInWithEmailPassword throws FirebaseAuthException when client unavailable', () async {
      expect(
        () => service.signInWithEmailPassword(
          email: 'farmer@example.com',
          password: 'password123',
        ),
        throwsA(isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'service-unavailable',
        )),
      );
    });

    test('registerWithEmailPassword throws FirebaseAuthException when client unavailable', () async {
      expect(
        () => service.registerWithEmailPassword(
          email: 'farmer@example.com',
          password: 'password123',
        ),
        throwsA(isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'service-unavailable',
        )),
      );
    });

    test('signOut executes safely without throwing when client unavailable', () async {
      await expectLater(service.signOut(), completes);
    });

    group('getReadableErrorMessage', () {
      test('maps OTP and phone authentication errors accurately', () {
        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'invalid-phone-number'),
          ),
          'Please enter a valid 10-digit mobile number.',
        );

        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'invalid-verification-code'),
          ),
          'Incorrect OTP. Please check the code received on your phone.',
        );

        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'session-expired'),
          ),
          'The OTP has expired. Please request a new code.',
        );
      });

      test('maps email and credential errors accurately', () {
        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'user-not-found'),
          ),
          'No account found with this email.',
        );

        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'wrong-password'),
          ),
          'Incorrect password. Please verify your credentials.',
        );

        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'email-already-in-use'),
          ),
          'An account already exists with this email.',
        );

        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'weak-password'),
          ),
          'Password is too weak. Please use at least 6 characters.',
        );
      });

      test('maps network and generic errors accurately', () {
        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'network-request-failed'),
          ),
          'Network error. Please check your internet connection.',
        );

        expect(
          AuthService.getReadableErrorMessage(
            FirebaseAuthException(code: 'service-unavailable'),
          ),
          'Authentication service is unavailable. Please try again.',
        );

        expect(
          AuthService.getReadableErrorMessage('General string error'),
          'General string error',
        );
      });
    });
  });
}
