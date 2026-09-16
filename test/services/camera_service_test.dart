import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planten/services/camera_service.dart';

class FakeCameraController extends CameraController {
  bool initializeCalled = false;
  bool takePictureCalled = false;
  bool disposeCalled = false;
  FlashMode? lastFlashModeSet;
  XFile? photoToReturn;
  bool throwOnInitialize = false;
  bool throwOnTakePicture = false;
  bool throwOnFlashMode = false;
  Duration? takePictureDelay;

  FakeCameraController(
    super.description,
    super.resolutionPreset, {
    super.enableAudio = false,
  });

  @override
  Future<void> initialize() async {
    if (throwOnInitialize) {
      throw CameraException('CAMERA_FAILED', 'Failed to initialize mock camera');
    }
    initializeCalled = true;
    value = value.copyWith(isInitialized: true);
  }

  @override
  Future<XFile> takePicture() async {
    if (takePictureDelay != null) {
      await Future.delayed(takePictureDelay!);
    }
    if (throwOnTakePicture) {
      throw CameraException('CAPTURE_FAILED', 'Failed to capture photo');
    }
    takePictureCalled = true;
    return photoToReturn ?? XFile('mock/path/leaf_photo.jpg');
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    if (throwOnFlashMode) {
      throw CameraException('FLASH_NOT_SUPPORTED', 'Flash not supported on this device');
    }
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

class FakeImagePicker extends Fake implements ImagePicker {
  XFile? imageToReturn;
  bool throwOnPick = false;
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
    if (throwOnPick) {
      throw Exception('Gallery permission denied');
    }
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

  late FakeImagePicker fakeImagePicker;
  late FakeCameraController fakeController;
  late CameraService cameraService;

  setUp(() {
    fakeImagePicker = FakeImagePicker();
    fakeController = FakeCameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    cameraService = CameraService(
      imagePicker: fakeImagePicker,
      mockCameras: [backCamera, frontCamera],
      controllerFactory: (desc, preset, {bool enableAudio = false}) {
        fakeController = FakeCameraController(
          desc,
          preset,
          enableAudio: enableAudio,
        );
        return fakeController;
      },
    );
  });

  tearDown(() {
    cameraService.dispose();
  });

  group('CameraService - Discovery & Initialization (Task 34)', () {
    test('discovers mock cameras correctly', () async {
      final cameras = await cameraService.getAvailableCameras();
      expect(cameras.length, 2);
      expect(cameraService.availableCamerasList.length, 2);
      expect(cameras.first.lensDirection, CameraLensDirection.back);
    });

    test('invokes custom discovery function when mockCameras is empty', () async {
      final service = CameraService(
        availableCamerasDiscovery: () async => [backCamera],
      );

      final cameras = await service.getAvailableCameras();
      expect(cameras.length, 1);
      expect(cameras.first.name, '0');
    });

    test('handles camera discovery exception gracefully without crashing', () async {
      final service = CameraService(
        availableCamerasDiscovery: () async =>
            throw Exception('Camera subsystem unavailable'),
      );

      final cameras = await service.getAvailableCameras();
      expect(cameras, isEmpty);
      expect(service.hasError, isTrue);
      expect(service.errorMessage, contains('Failed to discover device cameras'));
    });

    test('initializes default rear camera with ResolutionPreset.high and audio disabled',
        () async {
      expect(cameraService.isInitialized, isFalse);

      await cameraService.initialize();

      expect(cameraService.isInitialized, isTrue);
      expect(cameraService.selectedCamera, backCamera);
      expect(cameraService.resolutionPreset, ResolutionPreset.high);
      expect(fakeController.initializeCalled, isTrue);
      expect(cameraService.hasError, isFalse);
      expect(cameraService.currentFlashMode, FlashMode.off);
    });

    test('initializes with custom CameraDescription when provided', () async {
      await cameraService.initialize(customCamera: frontCamera);

      expect(cameraService.isInitialized, isTrue);
      expect(cameraService.selectedCamera, frontCamera);
      expect(fakeController.description.lensDirection, CameraLensDirection.front);
    });

    test('sets error when no cameras are available on device', () async {
      final service = CameraService(
        mockCameras: [],
        availableCamerasDiscovery: () async => [],
      );

      await service.initialize();

      expect(service.isInitialized, isFalse);
      expect(service.hasError, isTrue);
      expect(service.errorMessage, 'No cameras available on this device.');
    });

    test('handles CameraException during initialize gracefully', () async {
      final service = CameraService(
        mockCameras: [backCamera],
        controllerFactory: (desc, preset, {bool enableAudio = false}) {
          final ctrl = FakeCameraController(desc, preset, enableAudio: enableAudio);
          ctrl.throwOnInitialize = true;
          return ctrl;
        },
      );

      await service.initialize();

      expect(service.isInitialized, isFalse);
      expect(service.hasError, isTrue);
      expect(service.errorMessage, contains('CAMERA_FAILED'));
    });

    test('disposes previous controller when re-initializing', () async {
      await cameraService.initialize();
      final firstController = fakeController;

      await cameraService.initialize(customCamera: frontCamera);

      expect(firstController.disposeCalled, isTrue);
      expect(cameraService.selectedCamera, frontCamera);
    });
  });

  group('CameraService - Photo Capture (Task 34)', () {
    test('returns null and sets error if takePicture is called before initialization',
        () async {
      final photo = await cameraService.takePicture();

      expect(photo, isNull);
      expect(cameraService.hasError, isTrue);
      expect(cameraService.errorMessage, 'Camera is not initialized.');
    });

    test('captures photo successfully when camera is initialized', () async {
      await cameraService.initialize();

      fakeController.photoToReturn = XFile('test/captured/tomato_blight.jpg');

      final photo = await cameraService.takePicture();

      expect(photo, isNotNull);
      expect(photo!.path, 'test/captured/tomato_blight.jpg');
      expect(fakeController.takePictureCalled, isTrue);
      expect(cameraService.hasError, isFalse);
      expect(cameraService.isTakingPicture, isFalse);
    });

    test('guards against concurrent takePicture calls', () async {
      await cameraService.initialize();
      fakeController.takePictureDelay = const Duration(milliseconds: 100);

      final future1 = cameraService.takePicture();
      expect(cameraService.isTakingPicture, isTrue);

      final future2 = cameraService.takePicture(); // Should return null immediately

      final result2 = await future2;
      expect(result2, isNull);

      final result1 = await future1;
      expect(result1, isNotNull);
      expect(cameraService.isTakingPicture, isFalse);
    });

    test('handles CameraException during takePicture safely', () async {
      await cameraService.initialize();
      fakeController.throwOnTakePicture = true;

      final photo = await cameraService.takePicture();

      expect(photo, isNull);
      expect(cameraService.hasError, isTrue);
      expect(cameraService.errorMessage, contains('CAPTURE_FAILED'));
      expect(cameraService.isTakingPicture, isFalse);
    });
  });

  group('CameraService - Flash Modes (Task 34)', () {
    test('sets flash mode successfully and notifies listeners', () async {
      await cameraService.initialize();

      int notifications = 0;
      cameraService.addListener(() => notifications++);

      await cameraService.setFlashMode(FlashMode.torch);

      expect(cameraService.currentFlashMode, FlashMode.torch);
      expect(fakeController.lastFlashModeSet, FlashMode.torch);
      expect(notifications, greaterThan(0));
    });

    test('toggleFlashMode cycles sequentially: off -> torch -> auto -> off',
        () async {
      await cameraService.initialize();
      expect(cameraService.currentFlashMode, FlashMode.off);

      // off -> torch
      final mode1 = await cameraService.toggleFlashMode();
      expect(mode1, FlashMode.torch);
      expect(cameraService.currentFlashMode, FlashMode.torch);

      // torch -> auto
      final mode2 = await cameraService.toggleFlashMode();
      expect(mode2, FlashMode.auto);
      expect(cameraService.currentFlashMode, FlashMode.auto);

      // auto -> off
      final mode3 = await cameraService.toggleFlashMode();
      expect(mode3, FlashMode.off);
      expect(cameraService.currentFlashMode, FlashMode.off);
    });

    test('handles flash mode exception gracefully', () async {
      await cameraService.initialize();
      fakeController.throwOnFlashMode = true;

      await cameraService.setFlashMode(FlashMode.torch);

      expect(cameraService.hasError, isTrue);
      expect(cameraService.errorMessage, contains('Flash not supported'));
    });
  });

  group('CameraService - Switch Camera (Task 34)', () {
    test('switches from back to front camera', () async {
      await cameraService.initialize();
      expect(cameraService.selectedCamera!.name, '0');

      await cameraService.switchCamera();
      expect(cameraService.selectedCamera!.name, '1');

      await cameraService.switchCamera();
      expect(cameraService.selectedCamera!.name, '0');
    });

    test('switchCamera does nothing if fewer than 2 cameras are available', () async {
      final service = CameraService(
        mockCameras: [backCamera],
        controllerFactory: (desc, preset, {bool enableAudio = false}) =>
            FakeCameraController(desc, preset, enableAudio: enableAudio),
      );

      await service.initialize();
      expect(service.selectedCamera, backCamera);

      await service.switchCamera();
      expect(service.selectedCamera, backCamera);
    });
  });

  group('CameraService - Gallery Fallback (Task 34)', () {
    test('picks image from device gallery successfully', () async {
      fakeImagePicker.imageToReturn = XFile('gallery/photo_potato.jpg');

      final image = await cameraService.pickImageFromGallery();

      expect(image, isNotNull);
      expect(image!.path, 'gallery/photo_potato.jpg');
      expect(fakeImagePicker.lastSource, ImageSource.gallery);
      expect(cameraService.hasError, isFalse);
    });

    test('handles gallery picker exception gracefully', () async {
      fakeImagePicker.throwOnPick = true;

      final image = await cameraService.pickImageFromGallery();

      expect(image, isNull);
      expect(cameraService.hasError, isTrue);
      expect(cameraService.errorMessage, contains('Gallery permission denied'));
    });
  });

  group('CameraService - Lifecycle & Safe Disposal (Task 34)', () {
    test('dispose cleans up controller and marks service disposed', () async {
      await cameraService.initialize();
      expect(cameraService.isInitialized, isTrue);

      final activeController = fakeController;
      cameraService.dispose();

      expect(activeController.disposeCalled, isTrue);
      expect(cameraService.controller, isNull);
      expect(cameraService.isInitialized, isFalse);
    });
  });
}
