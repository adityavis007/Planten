import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';

/// Service managing user authentication operations including Email/Password sign in,
/// Google Sign-In, password resets, session management, and auth state streaming.
class AuthService {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  /// Creates an [AuthService]. Optional [FirebaseAuth] and [GoogleSignIn] can be injected for testing.
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn}) {
    _auth = auth;
    _googleSignIn = googleSignIn;
  }

  /// Returns active [FirebaseAuth] instance from injected dependency, [FirebaseService],
  /// or null if unavailable.
  FirebaseAuth? get authOrNull {
    if (_auth != null) return _auth;
    if (FirebaseService.instance.isAvailable) {
      return FirebaseService.instance.auth;
    }
    return null;
  }

  /// Stream emitting the current authenticated [User] on sign in, sign out, or token changes.
  Stream<User?> get authStateChanges {
    final client = authOrNull;
    if (client == null) {
      return const Stream.empty();
    }
    return client.authStateChanges();
  }

  /// Currently authenticated [User], or null if unauthenticated or offline.
  User? get currentUser => authOrNull?.currentUser;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => currentUser != null;

  /// UID of the current user, or null if unauthenticated.
  String? get currentUid => currentUser?.uid;

  /// Initiates Phone Number verification by sending an SMS OTP.
  /// (Deprecated: authentication now prefers Email/Password and Google Sign-In).
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final client = authOrNull;
    if (client == null) {
      verificationFailed(
        FirebaseAuthException(
          code: 'service-unavailable',
          message: 'Firebase Authentication is currently unavailable.',
        ),
      );
      return;
    }

    await client.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: timeout,
    );
  }

  /// Completes Phone Number sign-in using the received OTP and verification ID.
  /// (Deprecated: authentication now prefers Email/Password and Google Sign-In).
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final client = authOrNull;
    if (client == null) {
      throw FirebaseAuthException(
        code: 'service-unavailable',
        message: 'Firebase Authentication is currently unavailable.',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );

    return client.signInWithCredential(credential);
  }

  /// Signs in a user using email and password.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final client = authOrNull;
    if (client == null) {
      throw FirebaseAuthException(
        code: 'service-unavailable',
        message: 'Firebase Authentication is currently unavailable.',
      );
    }

    return client.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new user account with email and password.
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final client = authOrNull;
    if (client == null) {
      throw FirebaseAuthException(
        code: 'service-unavailable',
        message: 'Firebase Authentication is currently unavailable.',
      );
    }

    return client.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in a user using Google Sign-In and Firebase Authentication.
  Future<UserCredential> signInWithGoogle() async {
    final client = authOrNull;
    if (client == null) {
      throw FirebaseAuthException(
        code: 'service-unavailable',
        message: 'Firebase Authentication is currently unavailable.',
      );
    }

    try {
      _googleSignIn ??= GoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-canceled',
          message: 'Google Sign-In was canceled by user.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await client.signInWithCredential(credential);
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign-in failed: $e',
      );
    }
  }

  /// Sends a password reset email to the given [email] address.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final client = authOrNull;
    if (client == null) {
      throw FirebaseAuthException(
        code: 'service-unavailable',
        message: 'Firebase Authentication is currently unavailable.',
      );
    }

    await client.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs out the current user and clears active authentication session.
  Future<void> signOut() async {
    final client = authOrNull;
    if (client != null) {
      await client.signOut();
    }
    if (_googleSignIn != null) {
      try {
        await _googleSignIn!.signOut();
      } catch (_) {}
    }
  }

  /// Translates standard Firebase authentication error codes into outdoor/farmer-friendly messages.
  static String getReadableErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Please enter a valid 10-digit mobile number.';
        case 'invalid-verification-code':
          return 'Incorrect OTP. Please check the code received on your phone.';
        case 'session-expired':
          return 'The OTP has expired. Please request a new code.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few minutes and try again.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please verify your credentials.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'sign-in-canceled':
          return 'Google sign-in was canceled.';
        case 'google-sign-in-failed':
          return 'Google sign-in failed. Please try again or use email.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'service-unavailable':
          return 'Authentication service is unavailable. Please try again.';
        default:
          return error.message ?? 'Authentication error. Please try again.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
