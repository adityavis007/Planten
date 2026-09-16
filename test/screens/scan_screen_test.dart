import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/scan/scan_screen.dart';
import 'package:planten/services/camera_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestCameraController extends CameraController {
  bool initializeCalled = false;
  bool takePictureCalled = false;
  bool disposeCalled = false;
  FlashMode? lastFlashModeSet;
  XFile? photoToReturn;

  TestCameraController(
    super.description,
    super.resolutionPreset, {
    super.enableAudio = false,
  });

  @override
  Future<void> initialize() async {
    initializeCalled = true;
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1920, 1080),
    );
  }

  @override
  Future<XFile> takePicture() async {
    takePictureCalled = true;
    return photoToReturn ?? XFile('mock/path/tomato_leaf.jpg');
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    lastFlashModeSet = mode;
    value = value.copyWith(flashMode: mode);
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    value = value.copyWith(isInitialized: false);
    try {
      await super.dispose();
    } catch (_) {}
  }
}

class TestImagePicker extends Fake implements ImagePicker {
  XFile? imageToReturn;
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    return imageToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const backCamera = CameraDescription(
    name: '0',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  const frontCamera = CameraDescription(
    name: '1',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 270,
  );

  late LocaleProvider localeProvider;
  late CropProvider cropProvider;
  late LocalStorageService localStorage;
  late TestImagePicker fakeImagePicker;
  late TestCameraController fakeController;
  late CameraService cameraService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    localeProvider = LocaleProvider(prefs: prefs);
    cropProvider = CropProvider(localStorageService: localStorage);

    fakeImagePicker = TestImagePicker();
    fakeController = TestCameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    cameraService = CameraService(
      imagePicker: fakeImagePicker,
      mockCameras: [backCamera, frontCamera],
      controllerFactory: (desc, preset, {bool enableAudio = false}) {
        fakeController = TestCameraController(desc, preset, enableAudio: enableAudio);
        return fakeController;
      },
    );
  });

  tearDown(() {
    cameraService.dispose();
    cropProvider.dispose();
  });

  Widget buildTestableScanScreen({
    CameraService? customCameraService,
    CropProvider? customCropProvider,
    ValueChanged<String>? onPhotoCaptured,
    VoidCallback? onClose,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<CropProvider>.value(
            value: customCropProvider ?? cropProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ScanScreen(
          cameraService: customCameraService ?? cameraService,
          cropProvider: customCropProvider ?? cropProvider,
          onPhotoCaptured: onPhotoCaptured,
          onClose: onClose,
        ),
      ),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ScanScreen (Task 35)', () {
    testWidgets(
        'renders alignment guide box, guidance message, and corner brackets',
        (tester) async {
      setPhoneViewport(tester);
      await cameraService.initialize();

      await tester.pumpWidget(buildTestableScanScreen());
      await tester.pump();

      // Guide banner
      expect(find.byKey(const ValueKey('align_leaf_guide_banner')), findsOneWidget);
      expect(
        find.text('Align infected leaf inside the box'),
        findsOneWidget,
      );

      // Guide frame
      expect(find.byKey(const ValueKey('alignment_guide_frame')), findsOneWidget);
    });

    testWidgets(
        'renders top bar with close button, active crop pill, and flash toggle',
        (tester) async {
      await cameraService.initialize();

      await tester.pumpWidget(buildTestableScanScreen());
      await tester.pump();

      // Close button
      expect(find.byKey(const ValueKey('close_scan_button')), findsOneWidget);

      // Active crop pill
      expect(find.byKey(const ValueKey('active_crop_pill')), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);

      // Flash toggle button
      expect(find.byKey(const ValueKey('flash_toggle_button')), findsOneWidget);
    });

    testWidgets('tapping flash button toggles flash mode in CameraService',
        (tester) async {
      await cameraService.initialize();

      await tester.pumpWidget(buildTestableScanScreen());
      await tester.pump();

      expect(cameraService.currentFlashMode, FlashMode.off);

      // Tap flash button
      await tester.tap(find.byKey(const ValueKey('flash_toggle_button')));
      await tester.pump();

      expect(cameraService.currentFlashMode, FlashMode.torch);

      // Tap again
      await tester.tap(find.byKey(const ValueKey('flash_toggle_button')));
      await tester.pump();

      expect(cameraService.currentFlashMode, FlashMode.auto);
    });

    testWidgets('tapping close button triggers onClose callback',
        (tester) async {
      await cameraService.initialize();
      bool closeCalled = false;

      await tester.pumpWidget(
        buildTestableScanScreen(
          onClose: () {
            closeCalled = true;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('close_scan_button')));
      await tester.pump();

      expect(closeCalled, isTrue);
    });

    testWidgets('tapping active crop pill opens crop selection modal',
        (tester) async {
      await cameraService.initialize();

      await tester.pumpWidget(buildTestableScanScreen());
      await tester.pump();

      // Tap active crop pill
      await tester.tap(find.byKey(const ValueKey('active_crop_pill')));
      await tester.pumpAndSettle();

      // Crop selection modal opened
      expect(find.text('Select Crop'), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_tile_potato')), findsOneWidget);
    });

    testWidgets(
        'tapping shutter button triggers photo capture and invokes onPhotoCaptured',
        (tester) async {
      await cameraService.initialize();
      fakeController.photoToReturn = XFile('test/captured/chili_leaf.jpg');

      String? capturedPath;

      await tester.pumpWidget(
        buildTestableScanScreen(
          onPhotoCaptured: (path) {
            capturedPath = path;
          },
        ),
      );
      await tester.pump();

      // Tap shutter button
      final shutterBtn = find.byKey(const ValueKey('shutter_button'));
      expect(shutterBtn, findsOneWidget);
      await tester.tap(shutterBtn);
      await tester.pumpAndSettle();

      expect(capturedPath, 'test/captured/chili_leaf.jpg');
    });

    testWidgets(
        'tapping gallery button picks image and invokes onPhotoCaptured',
        (tester) async {
      await cameraService.initialize();
      fakeImagePicker.imageToReturn = XFile('test/gallery/potato_leaf.jpg');

      String? selectedPath;

      await tester.pumpWidget(
        buildTestableScanScreen(
          onPhotoCaptured: (path) {
            selectedPath = path;
          },
        ),
      );
      await tester.pump();

      // Tap gallery button
      final galleryBtn = find.byKey(const ValueKey('gallery_picker_button'));
      expect(galleryBtn, findsOneWidget);
      await tester.tap(galleryBtn);
      await tester.pumpAndSettle();

      expect(selectedPath, 'test/gallery/potato_leaf.jpg');
      expect(fakeImagePicker.lastSource, ImageSource.gallery);
    });

    testWidgets('renders camera switch button when multiple cameras exist',
        (tester) async {
      await cameraService.initialize();

      await tester.pumpWidget(buildTestableScanScreen());
      await tester.pump();

      final switchBtn = find.byKey(const ValueKey('switch_camera_button'));
      expect(switchBtn, findsOneWidget);

      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      expect(cameraService.selectedCamera!.lensDirection, CameraLensDirection.front);
    });

    testWidgets('displays error fallback UI with retry button when camera fails',
        (tester) async {
      final failingService = CameraService(
        mockCameras: [],
        availableCamerasDiscovery: () async => [],
      );

      await tester.pumpWidget(
        buildTestableScanScreen(customCameraService: failingService),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('retry_camera_button')), findsOneWidget);
      expect(find.text('No cameras available on this device.'), findsOneWidget);
    });

    testWidgets('navigates via GoRouter at AppRoutes.scan', (tester) async {
      await cameraService.initialize();

      final router = GoRouter(
        initialLocation: AppRoutes.scan,
        routes: [
          GoRoute(
            path: AppRoutes.scan,
            builder: (context, state) => ScanScreen(
              cameraService: cameraService,
              cropProvider: cropProvider,
            ),
          ),
          GoRoute(
            path: AppRoutes.scanPreview,
            builder: (context, state) => const Scaffold(
              body: Text('Preview Screen Destination'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
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

      expect(find.byType(ScanScreen), findsOneWidget);

      // Shutter click pushes to scanPreview
      fakeController.photoToReturn = XFile('test/captured/preview_test.jpg');
      await tester.tap(find.byKey(const ValueKey('shutter_button')));
      await tester.pumpAndSettle();

      expect(find.text('Preview Screen Destination'), findsOneWidget);
    });
  });
}
