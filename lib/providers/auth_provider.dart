import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/farmer_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// State management provider managing authentication status, phone OTP lifecycle,
/// active farmer profile, and async operations.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserProfileService _userProfileService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  FarmerProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  // Phone OTP Flow State
  String? _verificationId;
  int? _resendToken;
  bool _otpSent = false;
  String? _pendingPhoneNumber;
  Future<void> Function(String userId, FarmerProfile? profile)?
  _onUserAuthenticated;

  AuthProvider({
    AuthService? authService,
    UserProfileService? userProfileService,
    this._onUserAuthenticated,
  }) : _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService() {
    _init();
  }

  /// Sets the callback triggered when a user is authenticated or refreshed.
  set onUserAuthenticated(
    Future<void> Function(String userId, FarmerProfile? profile)? callback,
  ) {
    _onUserAuthenticated = callback;
    if (_user != null && callback != null) {
      callback(_user!.uid, _profile);
    }
  }

  /// Active onUserAuthenticated callback.
  Future<void> Function(String userId, FarmerProfile? profile)?
  get onUserAuthenticated => _onUserAuthenticated;

  /// Initial setup: preloads local cached profile and begins listening to auth changes.
  void _init() {
    _user = _authService.currentUser;
    _profile = _userProfileService.cachedProfile;

    _authSubscription = _authService.authStateChanges.listen((newUser) async {
      _user = newUser;
      if (newUser != null) {
        await _fetchProfile(newUser.uid);
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  // --- Getters ---

  /// Currently authenticated Firebase [User], or null if unauthenticated.
  User? get user => _user;

  /// Active [FarmerProfile], or null if unauthenticated or profile setup not completed.
  FarmerProfile? get profile => _profile;

  /// Indicates if an asynchronous operation (e.g. OTP verification, profile save) is active.
  bool get isLoading => _isLoading;

  /// User-friendly error message, or null if no error has occurred.
  String? get errorMessage => _errorMessage;

  /// Whether an OTP has been dispatched and the UI should display the verification view.
  bool get otpSent => _otpSent;

  /// Active verification ID from Firebase Auth phone verification.
  String? get verificationId => _verificationId;

  /// The phone number pending verification.
  String? get pendingPhoneNumber => _pendingPhoneNumber;

  /// Whether an active user session exists (Firebase User or cached profile).
  bool get isAuthenticated => _user != null || _profile != null;

  /// Whether the farmer has completed their onboarding profile.
  bool get isProfileComplete => _profile?.isProfileComplete ?? false;

  // --- Actions ---

  /// Formats phone number (ensures `+91` prefix for 10-digit Indian numbers) and sends OTP.
  Future<bool> sendOtp(String phoneNumber) async {
    final formatted = _formatPhoneNumber(phoneNumber);
    if (formatted.length < 10) {
      _errorMessage = 'Please enter a valid phone number.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearErrorInternal();
    _pendingPhoneNumber = formatted;

    final completer = Completer<bool>();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: formatted,
        resendToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic SMS verification on Android
          try {
            final auth = _authService.authOrNull;
            if (auth != null) {
              final userCred = await auth.signInWithCredential(credential);
              _user = userCred.user;
              if (_user != null) {
                await _fetchProfile(_user!.uid);
              }
            }
            _otpSent = false;
            _setLoading(false);
            if (!completer.isCompleted) completer.complete(true);
          } catch (e) {
            _setError(AuthService.getReadableErrorMessage(e));
            if (!completer.isCompleted) completer.complete(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError(AuthService.getReadableErrorMessage(e));
          if (!completer.isCompleted) completer.complete(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _otpSent = true;
          _setLoading(false);
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return await completer.future;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      return false;
    }
  }

  /// Verifies the entered SMS code against the active [verificationId].
  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _setError('Verification session expired. Please request a new OTP.');
      return false;
    }

    final trimmedCode = smsCode.trim();
    if (trimmedCode.length != 6) {
      _setError('Please enter a valid 6-digit OTP code.');
      return false;
    }

    _setLoading(true);
    _clearErrorInternal();

    try {
      final userCred = await _authService.signInWithOtp(
        verificationId: _verificationId!,
        smsCode: trimmedCode,
      );

      _user = userCred.user;
      if (_user != null) {
        await _fetchProfile(_user!.uid);
      }

      _otpSent = false;
      _verificationId = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      return false;
    }
  }

  /// Signs in using email and password.
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearErrorInternal();

    try {
      final userCred = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      _user = userCred.user;
      if (_user != null) {
        await _fetchProfile(_user!.uid);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      return false;
    }
  }

  /// Alias for [signInWithEmailPassword].
  Future<bool> loginWithEmail(String email, String password) =>
      signInWithEmailPassword(email: email, password: password);

  /// Registers a new account with email and password.
  Future<bool> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearErrorInternal();

    try {
      final userCred = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
      );

      _user = userCred.user;
      if (_user != null) {
        await _fetchProfile(_user!.uid);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      return false;
    }
  }

  /// Alias for [registerWithEmailPassword].
  Future<bool> registerWithEmail(String email, String password) =>
      registerWithEmailPassword(email: email, password: password);

  /// Signs in using Google Sign-In and updates active profile session.
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearErrorInternal();

    try {
      final userCred = await _authService.signInWithGoogle();
      _user = userCred.user;
      if (_user != null) {
        await _fetchProfile(_user!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      return false;
    }
  }

  /// Dispatches a password reset link to [email].
  Future<bool> sendPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      _setError('Please enter your email address.');
      return false;
    }

    _setLoading(true);
    _clearErrorInternal();

    try {
      await _authService.sendPasswordResetEmail(email: trimmed);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.getReadableErrorMessage(e));
      return false;
    }
  }

  /// Updates or creates the farmer's profile, syncing locally and to Firestore.
  Future<bool> updateProfile(FarmerProfile updatedProfile) async {
    _setLoading(true);
    _clearErrorInternal();

    try {
      final success = await _userProfileService.createOrUpdateProfile(
        updatedProfile,
      );
      if (success) {
        _profile = updatedProfile;
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    }
  }

  /// Ends the active user session, signs out from Firebase, and clears local cached profile.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      await _userProfileService.clearCachedProfile();
      _user = null;
      _profile = null;
      _verificationId = null;
      _otpSent = false;
      _pendingPhoneNumber = null;
      _clearErrorInternal();
    } catch (e) {
      _setError('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clears active error message.
  void clearError() {
    _clearErrorInternal();
    notifyListeners();
  }

  /// Resets OTP state back to phone entry.
  void resetOtpState() {
    _otpSent = false;
    _verificationId = null;
    _pendingPhoneNumber = null;
    _clearErrorInternal();
    notifyListeners();
  }

  // --- Internal Helpers ---

  Future<void> _fetchProfile(String uid) async {
    try {
      _profile = await _userProfileService.getProfile(uid, forceRemote: true);
      if (_onUserAuthenticated != null) {
        await _onUserAuthenticated!(uid, _profile);
      }
    } catch (e) {
      debugPrint('AuthProvider: Error loading profile for UID $uid: $e');
    }
  }

  String _formatPhoneNumber(String rawNumber) {
    final cleaned = rawNumber.replaceAll(RegExp(r'\s+|-'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    return cleaned;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearErrorInternal() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
