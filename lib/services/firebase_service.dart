import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../core/config/firebase_options.dart';

/// Centralized service managing Firebase Core initialization, offline Firestore
/// caching persistence, authentication provider, and cloud storage references.
///
/// Designed with an offline-first philosophy: if Firebase is unavailable
/// (e.g. no internet connectivity, unconfigured platform channels, or mock testing),
/// initialization succeeds gracefully with [isAvailable] set to `false`, allowing
/// the app to function with 100% offline features.
class FirebaseService {
  static FirebaseService _instance = FirebaseService._internal();

  /// Singleton access to [FirebaseService].
  static FirebaseService get instance => _instance;

  FirebaseApp? _app;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  FirebaseStorage? _storage;

  bool _isInitialized = false;
  bool _isAvailable = false;
  String? _initializationError;

  /// Internal constructor for singleton.
  FirebaseService._internal();

  /// Constructor allowing dependency injection for unit and integration testing.
  FirebaseService({
    FirebaseApp? app,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) {
    _app = app;
    _firestore = firestore;
    _auth = auth;
    _storage = storage;
  }

  /// Whether [initialize] has been invoked.
  bool get isInitialized => _isInitialized;

  /// Whether Firebase initialized successfully and services are available.
  bool get isAvailable => _isAvailable;

  /// Error message if initialization failed or was degraded to offline-only.
  String? get initializationError => _initializationError;

  /// Underlying [FirebaseApp] instance, or null if Firebase is unavailable.
  FirebaseApp? get app => _isAvailable ? _app : null;

  /// Configured [FirebaseFirestore] instance with offline persistence enabled,
  /// or null if Firebase is unavailable.
  FirebaseFirestore? get firestore => _isAvailable ? _firestore : null;

  /// Configured [FirebaseAuth] instance, or null if Firebase is unavailable.
  FirebaseAuth? get auth => _isAvailable ? _auth : null;

  /// Configured [FirebaseStorage] instance, or null if Firebase is unavailable.
  FirebaseStorage? get storage => _isAvailable ? _storage : null;

  /// Initializes Firebase and configures Firestore offline cache persistence.
  ///
  /// Returns `true` if Firebase is initialized and available, `false` if the app
  /// safely fell back to offline mode. Never throws unhandled exceptions.
  Future<bool> initialize({
    FirebaseOptions? options,
    FirebaseApp? app,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) async {
    if (_isInitialized && _isAvailable) {
      return true;
    }

    // Injected dependencies for testing take priority
    if (app != null) _app = app;
    if (firestore != null) _firestore = firestore;
    if (auth != null) _auth = auth;
    if (storage != null) _storage = storage;

    try {
      if (_app == null) {
        final configOptions = options ?? DefaultFirebaseOptions.currentPlatform;
        _app = await Firebase.initializeApp(options: configOptions);
      }

      // Configure Firestore with offline persistence
      _firestore ??= FirebaseFirestore.instance;
      try {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (settingsError) {
        // In certain test environments or if settings were already locked, ignore
        debugPrint('FirebaseService: Firestore settings note: $settingsError');
      }

      _auth ??= FirebaseAuth.instance;
      _storage ??= FirebaseStorage.instance;

      _isAvailable = true;
      _isInitialized = true;
      _initializationError = null;
      debugPrint('FirebaseService: Firebase initialized successfully with offline persistence.');
      return true;
    } catch (e, stack) {
      _isAvailable = false;
      _isInitialized = true;
      _initializationError = e.toString();
      debugPrint('FirebaseService: Firebase initialization degraded to offline mode: $e\n$stack');
      return false;
    }
  }

  /// Resets instance state for testing purposes.
  @visibleForTesting
  static void setMockInstance(FirebaseService mockService) {
    _instance = mockService;
  }

  /// Resets this service instance state.
  @visibleForTesting
  void resetForTesting({
    FirebaseApp? app,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) {
    _app = app;
    _firestore = firestore;
    _auth = auth;
    _storage = storage;
    _isInitialized = false;
    _isAvailable = false;
    _initializationError = null;
  }
}
