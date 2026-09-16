import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

import '../core/utils/image_preprocessor.dart';
import '../models/raw_inference_output.dart';

/// Exception thrown when inference is invoked on an uninitialized [InferenceService].
class InferenceNotInitializedException implements Exception {
  final String message;
  const InferenceNotInitializedException([
    this.message = 'InferenceService has not been initialized. Call initialize() first.',
  ]);

  @override
  String toString() => 'InferenceNotInitializedException: $message';
}

/// Exception thrown when image preprocessing or file decoding fails.
class InvalidImageException implements Exception {
  final String message;
  const InvalidImageException([this.message = 'The provided image file or bytes could not be decoded.']);

  @override
  String toString() => 'InvalidImageException: $message';
}

/// On-device AI inference service powered by LiteRT / TensorFlow Lite.
///
/// Features:
/// - Loads `crop_doctor_model.tflite` and `labels.txt` from bundled assets.
/// - Preprocesses input images to model dimensions ([1, 224, 224, 3]) with aspect-ratio crop.
/// - Executes quantized mobile inference with stopwatch latency tracking (< 3s target).
/// - Ensures probability output array sums to ~1.0 via numerically stable Softmax normalization.
/// - Supports test injection and headless execution for zero-flake testability.
class InferenceService {
  /// Default asset path for the crop doctor TFLite model.
  static const String defaultModelAsset = 'assets/model/crop_doctor_model.tflite';

  /// Default asset path for the classification labels.
  static const String defaultLabelsAsset = 'assets/model/labels.txt';

  /// Expected tensor input height and width.
  static const int inputDimension = ImagePreprocessor.defaultInputSize; // 224

  /// Number of expected classification output classes.
  static const int expectedClassesCount = 15;

  /// Global developer/demo mode flag.
  ///
  /// When enabled, provides guaranteed high-confidence (>85%) inference
  /// allowing UI developers and testers to inspect full diagnosis guidance,
  /// fertilizer advisory cards, and severity states without requiring real diseased leaves.
  static bool isGlobalDemoModeEnabled = false;

  /// Instance developer/demo mode flag.
  bool isDemoModeEnabled = false;

  final String modelAssetPath;
  final String labelsAssetPath;

  Interpreter? _interpreter;
  List<String> _labels = const [];
  bool _isInitialized = false;

  /// Optional delegate runner for dependency injection and mocking in tests.
  final Future<List<double>> Function(List<List<List<List<double>>>> input)? _customRunner;

  InferenceService({
    this.modelAssetPath = defaultModelAsset,
    this.labelsAssetPath = defaultLabelsAsset,
    Interpreter? interpreter,
    List<String>? labels,
    Future<List<double>> Function(List<List<List<List<double>>>> input)? customRunner,
    bool demoMode = false,
  })  : _interpreter = interpreter,
        _labels = labels ?? const [],
        _customRunner = customRunner,
        isDemoModeEnabled = demoMode,
        _isInitialized = interpreter != null || customRunner != null;

  /// Enables or disables instance demo mode.
  void enableDemoMode({bool enabled = true}) {
    isDemoModeEnabled = enabled;
  }

  /// Enables or disables global demo mode across all instances.
  static void setGlobalDemoMode({bool enabled = true}) {
    isGlobalDemoModeEnabled = enabled;
  }

  /// Whether the model and labels are loaded and ready for inference.
  bool get isInitialized => _isInitialized;

  /// Immutable list of loaded class labels.
  List<String> get labels => List.unmodifiable(_labels);

  /// Initializes the LiteRT interpreter and loads classification labels.
  ///
  /// Can optionally accept [modelBytes], [modelFile], or [customLabels] to bypass asset bundle loading.
  Future<void> initialize({
    Uint8List? modelBytes,
    File? modelFile,
    List<String>? customLabels,
    InterpreterOptions? options,
  }) async {
    // 1. Load labels
    if (customLabels != null && customLabels.isNotEmpty) {
      _labels = List.unmodifiable(customLabels);
    } else {
      _labels = await _loadLabelsFromAsset(labelsAssetPath);
    }

    // 2. Load interpreter if not injected
    if (_customRunner == null) {
      if (modelFile != null) {
        _interpreter = Interpreter.fromFile(modelFile, options: options);
      } else if (modelBytes != null) {
        _interpreter = Interpreter.fromBuffer(modelBytes, options: options);
      } else {
        try {
          final byteData = await rootBundle.load(modelAssetPath);
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
          _interpreter = Interpreter.fromBuffer(bytes, options: options);
        } catch (e) {
          // Fallback to File if rootBundle fails (e.g. running in pure Dart test)
          final fallbackFile = File(modelAssetPath);
          if (await fallbackFile.exists()) {
            _interpreter = Interpreter.fromFile(fallbackFile, options: options);
          } else {
            rethrow;
          }
        }
      }
    }

    _isInitialized = true;
  }

  /// Runs on-device AI inference on a given image [file].
  ///
  /// Returns a [RawInferenceOutput] containing class probabilities, top predictions, and latency.
  Future<RawInferenceOutput> runInference(File imageFile) async {
    _ensureInitialized();

    if (!imageFile.existsSync()) {
      throw InvalidImageException('Image file does not exist at: ${imageFile.path}');
    }

    final bytes = imageFile.readAsBytesSync();
    return runInferenceOnBytes(bytes);
  }

  /// Runs on-device AI inference directly on raw encoded image [bytes] (JPEG/PNG).
  Future<RawInferenceOutput> runInferenceOnBytes(Uint8List imageBytes) async {
    _ensureInitialized();

    final image = ImagePreprocessor.loadAndPreprocessBytes(
      imageBytes,
      targetWidth: inputDimension,
      targetHeight: inputDimension,
    );

    if (image == null) {
      throw const InvalidImageException('Failed to decode image bytes into pixel buffer.');
    }

    return runInferenceOnImage(image);
  }

  /// Runs on-device AI inference on a pre-decoded [image].
  Future<RawInferenceOutput> runInferenceOnImage(img.Image image) async {
    _ensureInitialized();

    // In demo mode, produce realistic high-confidence (>85%) output for UI/guidance testing
    if (isDemoModeEnabled || isGlobalDemoModeEnabled) {
      return _generateDemoInferenceOutput(image);
    }

    // 1. Convert to 4D tensor shape [1, 224, 224, 3] with [0.0, 1.0] normalization
    final inputTensor = ImagePreprocessor.to4DList(
      image,
      normalization: NormalizationType.zeroToOne,
      targetWidth: inputDimension,
      targetHeight: inputDimension,
    );

    // 2. Measure inference duration with monotonic stopwatch
    final stopwatch = Stopwatch()..start();
    final List<double> rawOutput;

    if (_customRunner != null) {
      rawOutput = await _customRunner(inputTensor);
    } else {
      final interpreter = _interpreter;
      if (interpreter == null) {
        throw const InferenceNotInitializedException('Interpreter is null.');
      }

      // Output tensor shape: [1, 15]
      final outputTensor = List.generate(
        1,
        (_) => List<double>.filled(_labels.length, 0.0),
      );

      interpreter.run(inputTensor, outputTensor);
      rawOutput = outputTensor[0];
    }
    stopwatch.stop();

    // 3. Ensure probabilities sum to ~1.0
    final normalizedProbabilities = normalizeProbabilities(rawOutput);

    return RawInferenceOutput.fromProbabilities(
      probabilities: normalizedProbabilities,
      labels: _labels,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Applies numerically stable Softmax normalization to [logits] if they do not already sum to ~1.0.
  static List<double> normalizeProbabilities(List<double> logits) {
    if (logits.isEmpty) return const [];

    // Check if values are already probabilities (all >= 0 and sum ~ 1.0)
    double sum = 0.0;
    bool hasNegative = false;
    for (final v in logits) {
      if (v < 0.0) hasNegative = true;
      sum += v;
    }

    if (!hasNegative && (sum - 1.0).abs() < 0.02) {
      // Already normalized probabilities, clamp to [0.0, 1.0]
      return logits.map((e) => e.clamp(0.0, 1.0)).toList();
    }

    // Apply stable Softmax: P_i = exp(z_i - max(z)) / sum(exp(z_j - max(z)))
    final maxLogit = logits.reduce(max);
    final expScores = logits.map((z) => exp(z - maxLogit)).toList();
    final expSum = expScores.reduce((a, b) => a + b);

    if (expSum == 0.0) {
      return List<double>.filled(logits.length, 1.0 / logits.length);
    }

    return expScores.map((e) => e / expSum).toList();
  }

  /// Closes the LiteRT interpreter and releases native FFI resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized || (_interpreter == null && _customRunner == null)) {
      throw const InferenceNotInitializedException();
    }
  }

  static Future<List<String>> _loadLabelsFromAsset(String assetPath) async {
    String text;
    try {
      text = await rootBundle.loadString(assetPath);
    } catch (_) {
      // Fallback to File if rootBundle fails in testing
      final file = File(assetPath);
      if (await file.exists()) {
        text = await file.readAsString();
      } else {
        rethrow;
      }
    }

    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Generates a realistic high-confidence (>85%) inference output based on visual heuristics.
  RawInferenceOutput _generateDemoInferenceOutput(img.Image image) {
    int brownOrYellowLesionCount = 0;
    int sampledPixelCount = 0;

    final stepX = max(1, image.width ~/ 40);
    final stepY = max(1, image.height ~/ 40);

    for (int y = 0; y < image.height; y += stepY) {
      for (int x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        sampledPixelCount++;

        // Detect brown/yellow discoloration or lesions:
        final isYellow = r > 120 && g > 100 && b < 80;
        final isBrown = r > 80 && r > g * 1.05 && g > b * 1.2;

        if (isYellow || isBrown) {
          brownOrYellowLesionCount++;
        }
      }
    }

    final lesionRatio = sampledPixelCount > 0 ? brownOrYellowLesionCount / sampledPixelCount : 0.0;

    final String targetLabel;
    final double targetConfidence;

    if (lesionRatio > 0.12) {
      // Evident brown lesions -> Early Blight (89%)
      targetLabel = _labels.contains('tomato_early_blight') ? 'tomato_early_blight' : _labels.first;
      targetConfidence = 0.89;
    } else if (lesionRatio > 0.04) {
      // Moderate yellowing / spotting -> Leaf Curl (87%)
      targetLabel = _labels.contains('tomato_leaf_curl') ? 'tomato_leaf_curl' : _labels.first;
      targetConfidence = 0.87;
    } else {
      // Clean predominantly green foliage -> Healthy (93%)
      targetLabel = _labels.contains('tomato_healthy') ? 'tomato_healthy' : _labels.first;
      targetConfidence = 0.93;
    }

    final targetIndex = _labels.indexOf(targetLabel);
    final List<double> probs = List.filled(_labels.length, 0.0);
    final remainingPerClass = (1.0 - targetConfidence) / max(1, _labels.length - 1);

    for (int i = 0; i < _labels.length; i++) {
      probs[i] = (i == targetIndex) ? targetConfidence : remainingPerClass;
    }

    return RawInferenceOutput.fromProbabilities(
      probabilities: probs,
      labels: _labels,
      inferenceTimeMs: 42,
    );
  }
}
