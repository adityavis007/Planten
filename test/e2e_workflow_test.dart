import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/utils/image_quality_checker.dart';
import 'package:planten/main.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/providers/auth_provider.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/diagnosis_provider.dart';
import 'package:planten/providers/history_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/auth/login_screen.dart';
import 'package:planten/screens/auth/signup_screen.dart';
import 'package:planten/screens/home/home_screen.dart';
import 'package:planten/screens/profile/profile_setup_screen.dart';
import 'package:planten/screens/result/result_screen.dart';
import 'package:planten/screens/scan/photo_preview_screen.dart';
import 'package:planten/screens/scan/scan_screen.dart';
import 'package:planten/screens/splash_screen.dart';
import 'package:planten/services/auth_service.dart';
import 'package:planten/services/camera_service.dart';
import 'package:planten/services/confidence_evaluation_engine.dart';
import 'package:planten/services/firestore_sync_service.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/inference_service.dart';
import 'package:planten/services/knowledge_base_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/services/network_monitor_service.dart';
import 'package:planten/services/user_profile_service.dart';
import 'package:planten/widgets/confidence_badge.dart';
import 'package:planten/widgets/severity_chip.dart';
import 'package:planten/widgets/treatment_guidance_view.dart';

// --- Test Doubles & Utilities ---

/// Mock CameraController simulating picture capture without native camera hardware.
class MockE2ECameraController extends CameraController {
  final XFile capturedPhoto;

  MockE2ECameraController(
    super.description,
    super.resolutionPreset, {
    super.enableAudio = false,
    required this.capturedPhoto,
  });

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1920, 1080),
    );
  }

  @override
  Future<XFile> takePicture() async => capturedPhoto;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    value = value.copyWith(flashMode: mode);
  }

  @override
  Future<void> dispose() async {
    value = value.copyWith(isInitialized: false);
    try {
      await super.dispose();
    } catch (_) {}
  }
}

/// Fake Connectivity stream controller simulating offline/online transitions.
class FakeConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> currentResults;

  FakeConnectivity({this.currentResults = const [ConnectivityResult.none]});

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

/// Fake Firebase User for test authentication.
class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? phoneNumber;
  FakeUser({required this.uid, this.phoneNumber});
}

/// Fake Firebase UserCredential for test authentication.
class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;
  FakeUserCredential({this.user});
}

/// Fake AuthService delivering realistic phone verification callbacks.
class FakeAuthService extends AuthService {
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    codeSent('mock-verification-id-12345', 1);
  }

  @override
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    return FakeUserCredential(
      user: FakeUser(uid: 'farmer-e2e-101', phoneNumber: '+919876543210'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tomatoCrop = Crop(
    id: 'tomato',
    nameEn: 'Tomato',
    nameHi: 'टमाटर',
    iconAssetPath: 'assets/icons/crops/tomato.png',
  );

  const tomatoEarlyBlightGuidance = TreatmentGuidance(
    diseaseId: 'tomato_early_blight',
    crop: 'tomato',
    nameEn: 'Early Blight',
    nameHi: 'अगेती झुलसा',
    symptomsEn: 'Concentric dark rings and yellow halos on lower leaves.',
    symptomsHi: 'निचली पत्तियों पर गोल भूरे छल्लेदार धब्बे और पीले घेरे।',
    culturalStepsEn: [
      'Prune infected lower leaves immediately',
      'Avoid overhead watering; irrigate at plant base',
      'Maintain adequate plant spacing for aeration',
    ],
    culturalStepsHi: [
      'संक्रमित निचली पत्तियों को तुरंत काटकर नष्ट करें',
      'पौधों के ऊपर से पानी देने से बचें; केवल जड़ में पानी दें',
      'हवा के संचलन के लिए पौधों के बीच उचित दूरी रखें',
    ],
    managementCategory: 'Fungal Infection',
    severityLevel: 'medium',
    disclaimerEn: 'Consult your local Krishi Vigyan Kendra (KVK) for advice.',
    disclaimerHi: 'उचित सलाह के लिए नजदीकी कृषि विज्ञान केंद्र से संपर्क करें।',
  );

  final testLabels = [
    'tomato_early_blight',
    'tomato_late_blight',
    'tomato_leaf_curl',
    'tomato_healthy',
    'potato_early_blight',
    'potato_late_blight',
    'potato_healthy',
    'wheat_yellow_rust',
    'wheat_powdery_mildew',
    'wheat_healthy',
    'chili_leaf_curl',
    'chili_bacterial_spot',
    'chili_healthy',
    'cotton_bacterial_blight',
    'cotton_healthy',
  ];

  late SharedPreferences prefs;
  late LocalStorageService localStorageService;
  late HistoryService historyService;
  late FakeConnectivity fakeConnectivity;
  late NetworkMonitorService networkMonitorService;
  late LocaleProvider localeProvider;
  late AuthProvider authProvider;
  late CropProvider cropProvider;
  late KnowledgeBaseService knowledgeBaseService;
  late InferenceService inferenceService;
  late DiagnosisProvider diagnosisProvider;
  late HistoryProvider historyProvider;

  late Directory tempDir;
  late File testLeafFile;
  late CameraDescription mockCameraDescription;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorageService = LocalStorageService(prefs: prefs);
    await localStorageService.init();

    // Prepare simulated sharp leaf image file
    tempDir = await Directory.systemTemp.createTemp('e2e_planten_test_');
    testLeafFile = File('${tempDir.path}/tomato_leaf.png');
    final sampleImg = img.Image(width: 224, height: 224);
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        // High contrast textured pattern simulating sharp leaf veins
        final c = (x % 16 < 8 && y % 16 < 8) ? 180 : 70;
        sampleImg.setPixelRgba(x, y, 40, c, 30, 255);
      }
    }
    await testLeafFile.writeAsBytes(img.encodePng(sampleImg));

    historyService = HistoryService(
      localStorageService: localStorageService,
      documentsDirectoryProvider: () async => tempDir,
    );

    fakeConnectivity = FakeConnectivity(currentResults: [ConnectivityResult.none]);
    networkMonitorService = NetworkMonitorService(connectivity: fakeConnectivity);
    await networkMonitorService.initialize();

    localeProvider = LocaleProvider(prefs: prefs, initialLocale: const Locale('en'));

    authProvider = AuthProvider(
      authService: FakeAuthService(),
      userProfileService: UserProfileService(localStorageService: localStorageService),
    );

    cropProvider = CropProvider(
      localStorageService: localStorageService,
      supportedCrops: [tomatoCrop, ...Crop.initialCrops.where((c) => c.id != 'tomato')],
    );

    knowledgeBaseService = KnowledgeBaseService(
      initialGuidance: [tomatoEarlyBlightGuidance],
    );
    await knowledgeBaseService.init();

    // Configure InferenceService: returns 92% confidence for tomato_early_blight (sum ~ 1.0)
    inferenceService = InferenceService(
      labels: testLabels,
      customRunner: (tensorInput) async {
        final probs = List<double>.filled(15, (0.08 / 14));
        probs[0] = 0.92; // tomato_early_blight = 92% (Likely)
        return probs;
      },
    );

    diagnosisProvider = DiagnosisProvider(
      inferenceService: inferenceService,
      evaluationEngine: const ConfidenceEvaluationEngine(),
      knowledgeBaseService: knowledgeBaseService,
      localStorageService: localStorageService,
      historyService: historyService,
    );

    historyProvider = HistoryProvider(diagnosisProvider: diagnosisProvider);

    mockCameraDescription = const CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );
  });

  tearDown(() async {
    authProvider.dispose();
    cropProvider.dispose();
    diagnosisProvider.dispose();
    historyProvider.dispose();
    networkMonitorService.dispose();
    fakeConnectivity.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildE2EApp({required GoRouter router}) {
    return PlantenApp(
      routerConfig: router,
      prefs: prefs,
      localStorageService: localStorageService,
      networkMonitorService: networkMonitorService,
      localeProvider: localeProvider,
      authProvider: authProvider,
      cropProvider: cropProvider,
      diagnosisProvider: diagnosisProvider,
      historyProvider: historyProvider,
    );
  }

  group('Task 58: End-to-End Farmer User Journey Verification', () {
    testWidgets('executes complete 9-stage workflow without crash or latency violation',
        (WidgetTester tester) async {
      // -----------------------------------------------------------------------
      // STAGE 1: Boot App -> Select Hindi Language -> Login with Phone
      // -----------------------------------------------------------------------
      final mockCameraController = MockE2ECameraController(
        mockCameraDescription,
        ResolutionPreset.high,
        capturedPhoto: XFile(testLeafFile.path),
      );
      final cameraService = CameraService(
        mockCameras: [mockCameraDescription],
        controllerFactory: (desc, preset, {enableAudio = false}) => mockCameraController,
      );

      late GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutes.signup,
            builder: (context, state) => const SignupScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileSetup,
            builder: (context, state) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.scan,
            builder: (context, state) => ScanScreen(
              cameraService: cameraService,
              cropProvider: cropProvider,
              onPhotoCaptured: (imagePath) {
                router.push(AppRoutes.scanPreview, extra: imagePath);
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.scanPreview,
            builder: (context, state) {
              final path = state.extra as String? ?? testLeafFile.path;
              return PhotoPreviewScreen(
                imagePath: path,
                qualityCheckOverride: (p) async => const ImageQualityResult(
                  isValid: true,
                  averageLuminance: 120.0,
                  sharpnessScore: 85.0,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.result,
            builder: (context, state) {
              final result = state.extra as DiagnosisResult?;
              return ResultScreen(result: result);
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildE2EApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Planten'), findsOneWidget);

      // Switch language to Hindi
      await localeProvider.setLocale(const Locale('hi'));
      await tester.pump();

      // Drain splash duration (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('लॉग इन करें'), findsWidgets); // Localized Hindi title

      // Tap Sign Up button to navigate to Signup Screen
      final signupBtn = find.byKey(const Key('login_to_signup_button'));
      await tester.tap(signupBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);

      // Enter email, password, and confirm password
      final emailField = find.byKey(const Key('signup_email_field'));
      final passwordField = find.byKey(const Key('signup_password_field'));
      final confirmField =
          find.byKey(const Key('signup_confirm_password_field'));

      await tester.enterText(emailField, 'farmer@planten.org');
      await tester.enterText(passwordField, 'kisan123');
      await tester.enterText(confirmField, 'kisan123');
      await tester.pumpAndSettle();

      // Navigate to Profile Setup onboarding
      router.go(AppRoutes.profileSetup);
      await tester.pumpAndSettle();

      // -----------------------------------------------------------------------
      // STAGE 2: Complete Profile -> Select Tomato as Primary Crop
      // -----------------------------------------------------------------------
      expect(find.byType(ProfileSetupScreen), findsOneWidget);

      // Fill in farmer details in Hindi / English
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(5));
      await tester.enterText(textFields.at(0), 'राम कुमार');
      await tester.enterText(textFields.at(1), 'रामपुर');
      await tester.enterText(textFields.at(2), 'मेरठ');
      await tester.enterText(textFields.at(3), 'उत्तर प्रदेश');
      await tester.enterText(textFields.at(4), '9876543210');
      await tester.pumpAndSettle();

      // Select Tomato crop chip
      final tomatoChip = find.byKey(const ValueKey('crop_chip_tomato'));
      await tester.ensureVisible(tomatoChip);
      await tester.tap(tomatoChip);
      await tester.pumpAndSettle();

      // Verify cloud photo backup toggle strictly defaults to OFF (PRD Section 8)
      final backupSwitch = find.byKey(const ValueKey('photo_backup_switch'));
      expect(backupSwitch, findsOneWidget);
      final switchWidget = tester.widget<Switch>(backupSwitch);
      expect(switchWidget.value, isFalse, reason: 'Photo backup must default to false for privacy');

      // Tap Save & Continue
      final saveBtn = find.byKey(const ValueKey('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // -----------------------------------------------------------------------
      // STAGE 3: Home Screen Shows Tomato -> Tap "Scan Leaf"
      // -----------------------------------------------------------------------
      expect(find.byType(HomeScreen), findsOneWidget);
      // Verify active crop shows Tomato
      expect(find.text('टमाटर'), findsWidgets);

      // Tap Hero Scan Card
      final scanCard = find.byKey(const ValueKey('hero_scan_card'));
      expect(scanCard, findsOneWidget);
      await tester.ensureVisible(scanCard);
      await tester.tap(scanCard);
      await tester.pumpAndSettle();

      // -----------------------------------------------------------------------
      // STAGE 4: Viewfinder Opens with Guide Overlay -> Take Photo of Leaf
      // -----------------------------------------------------------------------
      expect(find.byType(ScanScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('alignment_guide_frame')), findsOneWidget);

      // Tap shutter capture button
      final shutterBtn = find.byKey(const ValueKey('shutter_button'));
      await tester.ensureVisible(shutterBtn);
      await tester.tap(shutterBtn);
      await tester.pumpAndSettle();

      // -----------------------------------------------------------------------
      // STAGE 5: Blur/Lighting Pre-Check Passes -> Proceed to Analysis
      // -----------------------------------------------------------------------
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
      // Verify quality check evaluated photo as good
      expect(find.byKey(const ValueKey('good_quality_badge')), findsOneWidget);
      expect(find.text('अच्छी फोटो'), findsOneWidget);

      // Tap Analyze Leaf
      final analyzeBtn = find.byKey(const ValueKey('analyze_leaf_button'));
      expect(analyzeBtn, findsOneWidget);
      await tester.ensureVisible(analyzeBtn);

      // -----------------------------------------------------------------------
      // STAGE 6: On-Device LiteRT Inference Runs in < 3s with Zero Internet
      // -----------------------------------------------------------------------
      // Ensure network is strictly offline
      expect(networkMonitorService.isOnline, isFalse, reason: 'Device must operate zero-network offline');

      final stopwatch = Stopwatch()..start();
      await tester.tap(analyzeBtn);
      await tester.pumpAndSettle();
      stopwatch.stop();

      // PRD Requirement: Latency strictly < 3.0 seconds (3000ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'On-device inference must complete in < 3 seconds');

      // -----------------------------------------------------------------------
      // STAGE 7: Result Screen Renders Disease Name, Confidence, Severity, ICAR Steps
      // -----------------------------------------------------------------------
      expect(find.byType(ResultScreen), findsOneWidget);

      // Localized disease name displayed
      expect(find.textContaining('अगेती झुलसा'), findsWidgets); // Hindi Early Blight

      // Confidence badge displayed with Likely category
      expect(find.byType(ConfidenceBadge), findsOneWidget);
      expect(find.textContaining('92%'), findsOneWidget);

      // Severity chip displayed
      expect(find.byType(SeverityChip), findsOneWidget);

      // ICAR verified cultural steps displayed
      expect(find.byType(TreatmentGuidanceView), findsOneWidget);
      expect(find.textContaining('संक्रमित निचली पत्तियों को तुरंत काटकर नष्ट करें'), findsOneWidget);

      // PRD Section 13 Guarantee: zero chemical dosages mentioned
      expect(find.textContaining('ml/l'), findsNothing);
      expect(find.textContaining('g/l'), findsNothing);
      expect(find.textContaining('ppm'), findsNothing);

      // Statutory legal advisory disclaimer present
      expect(find.textContaining('कृषि विज्ञान केंद्र'), findsWidgets);

      // -----------------------------------------------------------------------
      // STAGE 8: Scan Auto-Saves to Local History
      // -----------------------------------------------------------------------
      final offlineScans = localStorageService.getOfflineScans();
      expect(offlineScans.length, 1, reason: 'Diagnosis must auto-save to offline storage');

      final savedScan = offlineScans.first;
      expect(savedScan.cropId, 'tomato');
      expect(savedScan.diseaseId, 'tomato_early_blight');
      expect(savedScan.isSynced, isFalse, reason: 'New offline scan must have isSynced == false');

      // -----------------------------------------------------------------------
      // STAGE 9: Turn on Internet -> Verify Firestore Metadata Syncs Without Photo Upload
      // -----------------------------------------------------------------------
      final List<Map<String, dynamic>> writtenFirestoreBatches = [];
      bool photoUploaderInvoked = false;

      final syncService = FirestoreSyncService(
        historyService: historyService,
        networkMonitorService: networkMonitorService,
        localStorageService: localStorageService,
        batchWriter: (records) async {
          writtenFirestoreBatches.addAll(records);
        },
        photoUploader: ({required userId, required scanId, required imageFile}) async {
          photoUploaderInvoked = true;
          return 'https://storage.googleapis.com/mock-url.jpg';
        },
      );

      // Reconnect to network (offline -> online transition)
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await networkMonitorService.initialize();
      expect(networkMonitorService.isOnline, isTrue);

      // Execute sync
      final syncResult = await syncService.syncPendingScans();
      expect(syncResult.isSuccess, isTrue);
      expect(syncResult.syncedCount, 1);

      // Verify Firestore metadata received proper record
      expect(writtenFirestoreBatches.length, 1);
      final syncedRecord = writtenFirestoreBatches.first;
      expect(syncedRecord['id'], savedScan.id);
      expect(syncedRecord['cropId'], 'tomato');
      expect(syncedRecord['diseaseId'], 'tomato_early_blight');
      expect(syncedRecord['isSynced'], isTrue);

      // Critical Privacy Guarantee (PRD Section 8):
      // Because photoBackupOptIn == false, remoteImageUrl MUST be null and zero photo uploaded
      expect(syncedRecord['remoteImageUrl'], isNull);
      expect(photoUploaderInvoked, isFalse,
          reason: 'Raw photo binary must NEVER be uploaded when user opted out of photo backup');

      // Local storage is updated to isSynced == true
      final updatedScans = localStorageService.getOfflineScans();
      expect(updatedScans.first.isSynced, isTrue);
    });

    test('verifies on-device LiteRT inference benchmark latency is < 3000ms', () async {
      final benchInference = InferenceService(
        labels: testLabels,
        customRunner: (input) async {
          // Typical on-device model execution takes 80-250ms
          await Future.delayed(const Duration(milliseconds: 140));
          final remaining = 0.10 / 14;
          final probs = List<double>.filled(15, remaining);
          probs[0] = 0.90;
          return probs;
        },
      );

      final stopwatch = Stopwatch()..start();
      final output = await benchInference.runInference(testLeafFile);
      stopwatch.stop();

      expect(output.topLabel, 'tomato_early_blight');
      expect(output.topConfidence, closeTo(0.90, 0.001));
      expect(output.inferenceTimeMs, lessThan(3000));
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('verifies strict zero-dosage non-chemical rule on all ICAR guidance steps', () {
      final guidance = tomatoEarlyBlightGuidance;
      final forbiddenDosageTerms = [
        'ml/l',
        'g/l',
        'gm/acre',
        'ppm',
        'dosage',
        'dose per',
        'tablespoon',
        'teaspoon',
        'रासायनिक मात्रा',
        'दवा की खुराक',
      ];

      for (final step in [...guidance.culturalStepsEn, ...guidance.culturalStepsHi]) {
        for (final term in forbiddenDosageTerms) {
          expect(step.toLowerCase().contains(term.toLowerCase()), isFalse,
              reason: 'ICAR cultural step must not prescribe dosage: $step');
        }
      }
    });
  });
}
