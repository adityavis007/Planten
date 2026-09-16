import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Function signature for instantiating a [CameraController].
typedef CameraControllerFactory = CameraController Function(
  CameraDescription description,
  ResolutionPreset resolutionPreset, {
  bool enableAudio,
});

/// Service managing device camera lifecycle, photo capture, flash control,
/// and gallery fallback for leaf disease diagnosis.
///
/// Complies with Planten PRD and offline architecture requirements:
/// - Defaults to rear camera with [ResolutionPreset.high] for sharp leaf detail.
/// - Explicitly disables audio (`enableAudio: false`) to avoid microphone permissions.
/// - Provides fallback to [ImagePicker] for gallery uploads and hardware failures.
/// - Safe lifecycle handling preventing camera memory and hardware leaks.
class CameraService with ChangeNotifier {
  final ImagePicker _imagePicker;
  final Future<List<CameraDescription>> Function()? _availableCamerasDiscovery;
  final CameraControllerFactory? _controllerFactory;

  List<CameraDescription> _availableCameras = [];
  CameraDescription? _selectedCamera;
  CameraController? _controller;
  FlashMode _flashMode = FlashMode.off;
  ResolutionPreset _resolutionPreset = ResolutionPreset.high;

  bool _isTakingPicture = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Creates a [CameraService] instance with optional dependency injection for testing.
  CameraService({
    ImagePicker? imagePicker,
    List<CameraDescription>? mockCameras,
    this._availableCamerasDiscovery,
    this._controllerFactory,
  }) : _imagePicker = imagePicker ?? ImagePicker() {
    if (mockCameras != null) {
      _availableCameras = List<CameraDescription>.from(mockCameras);
    }
  }

  /// Active camera controller, or `null` if not yet initialized or disposed.
  CameraController? get controller => _controller;

  /// Whether the camera controller is instantiated and initialized.
  bool get isInitialized =>
      !_isDisposed &&
      _controller != null &&
      _controller!.value.isInitialized;

  /// Whether a picture is currently being captured.
  bool get isTakingPicture => _isTakingPicture;

  /// Currently active flash mode.
  FlashMode get currentFlashMode => _flashMode;

  /// Currently selected camera description.
  CameraDescription? get selectedCamera => _selectedCamera;

  /// List of discovered device cameras.
  List<CameraDescription> get availableCamerasList =>
      List<CameraDescription>.unmodifiable(_availableCameras);

  /// Currently configured resolution preset.
  ResolutionPreset get resolutionPreset => _resolutionPreset;

  /// Whether an error occurred during camera operation.
  bool get hasError => _hasError;

  /// Human-readable error message, if [hasError] is true.
  String? get errorMessage => _errorMessage;

  /// Discovers available cameras on the device.
  ///
  /// Returns cached cameras if already discovered, or queries device hardware.
  Future<List<CameraDescription>> getAvailableCameras() async {
    if (_availableCameras.isNotEmpty) {
      return _availableCameras;
    }

    try {
      if (_availableCamerasDiscovery != null) {
        _availableCameras = await _availableCamerasDiscovery();
      } else {
        _availableCameras = await availableCameras();
      }
      _clearError();
    } catch (e) {
      _setError('Failed to discover device cameras: $e');
      _availableCameras = [];
    }

    return _availableCameras;
  }

  /// Initializes the device camera.
  ///
  /// - Selects [customCamera] or defaults to the rear camera (`CameraLensDirection.back`).
  /// - Configures [preset] (defaults to [ResolutionPreset.high]).
  /// - Disables audio (`enableAudio: false`).
  /// - Sets initial flash mode to [FlashMode.off].
  Future<void> initialize({
    CameraDescription? customCamera,
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    _resolutionPreset = preset;
    _clearError();

    try {
      final cameras = await getAvailableCameras();
      if (cameras.isEmpty) {
        _setError('No cameras available on this device.');
        return;
      }

      // Default to rear camera for scanning leaves
      final targetCamera = customCamera ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      _selectedCamera = targetCamera;

      // Dispose existing controller before creating new one
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // Instantiate controller via factory or default constructor
      final newController = _controllerFactory != null
          ? _controllerFactory(
              targetCamera,
              preset,
              enableAudio: false,
            )
          : CameraController(
              targetCamera,
              preset,
              enableAudio: false,
            );

      _controller = newController;
      await newController.initialize();

      // Configure initial flash mode
      try {
        await newController.setFlashMode(FlashMode.off);
        _flashMode = FlashMode.off;
      } catch (_) {
        // Flash might not be supported on this device/camera (e.g. front camera)
        _flashMode = FlashMode.off;
      }

      _clearError();
    } on CameraException catch (e) {
      _setError('Camera error (${e.code}): ${e.description ?? e.toString()}');
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  /// Captures a photo using the active camera controller.
  ///
  /// Returns an [XFile] pointing to the saved image file in temporary storage,
  /// or `null` if capture failed or is already in progress.
  Future<XFile?> takePicture() async {
    if (!isInitialized || _controller == null) {
      _setError('Camera is not initialized.');
      return null;
    }

    if (_isTakingPicture) {
      return null;
    }

    _isTakingPicture = true;
    _notifySafely();

    try {
      final XFile photo = await _controller!.takePicture();
      _clearError();
      return photo;
    } on CameraException catch (e) {
      _setError('Failed to capture photo (${e.code}): ${e.description ?? e.toString()}');
      return null;
    } catch (e) {
      _setError('Failed to capture photo: $e');
      return null;
    } finally {
      _isTakingPicture = false;
      _notifySafely();
    }
  }

  /// Sets the camera flash mode ([FlashMode.off], [FlashMode.torch], [FlashMode.auto]).
  Future<void> setFlashMode(FlashMode mode) async {
    if (!isInitialized || _controller == null) {
      return;
    }

    try {
      await _controller!.setFlashMode(mode);
      _flashMode = mode;
      _notifySafely();
    } on CameraException catch (e) {
      _setError('Failed to change flash mode: ${e.description ?? e.code}');
    } catch (e) {
      _setError('Failed to change flash mode: $e');
    }
  }

  /// Toggles through flash modes sequentially:
  /// [FlashMode.off] -> [FlashMode.torch] -> [FlashMode.auto] -> [FlashMode.off].
  Future<FlashMode> toggleFlashMode() async {
    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.torch,
      FlashMode.torch => FlashMode.auto,
      _ => FlashMode.off,
    };

    await setFlashMode(nextMode);
    return _flashMode;
  }

  /// Switches between available cameras (e.g. back to front).
  Future<void> switchCamera() async {
    final cameras = await getAvailableCameras();
    if (cameras.length < 2 || _selectedCamera == null) {
      return;
    }

    final currentIndex = cameras.indexWhere((c) => c.name == _selectedCamera!.name);
    final nextIndex = (currentIndex + 1) % cameras.length;
    await initialize(customCamera: cameras[nextIndex], preset: _resolutionPreset);
  }

  /// Selects an image from the device photo gallery.
  ///
  /// Acts as a fallback when camera hardware fails or permission is permanently denied,
  /// or when the farmer explicitly taps the gallery icon.
  Future<XFile?> pickImageFromGallery({
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int? imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      _clearError();
      return image;
    } catch (e) {
      _setError('Failed to pick image from gallery: $e');
      return null;
    }
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _notifySafely();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = null;
    _notifySafely();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
