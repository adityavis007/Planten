import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:planten/models/raw_inference_output.dart';
import 'package:planten/services/inference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final modelFile = File('assets/model/crop_doctor_model.tflite');
  final labelsFile = File('assets/model/labels.txt');

  group('RawInferenceOutput domain model', () {
    final testLabels = ['tomato_early_blight', 'tomato_healthy', 'wheat_rust'];
    final testProbs = [0.70, 0.20, 0.10];

    test('instantiates correctly and maps properties', () {
      final output = RawInferenceOutput.fromProbabilities(
        probabilities: testProbs,
        labels: testLabels,
        inferenceTimeMs: 45,
      );

      expect(output.probabilities, testProbs);
      expect(output.labels, testLabels);
      expect(output.inferenceTimeMs, 45);
      expect(output.topIndex, 0);
      expect(output.topLabel, 'tomato_early_blight');
      expect(output.topConfidence, 0.70);
      expect(output.probabilityFor('tomato_healthy'), 0.20);
      expect(output.probabilityFor('non_existent'), 0.0);
    });

    test('getTopK returns entries in descending order', () {
      final output = RawInferenceOutput.fromProbabilities(
        probabilities: [0.10, 0.85, 0.05],
        labels: ['class_a', 'class_b', 'class_c'],
        inferenceTimeMs: 12,
      );

      final top2 = output.getTopK(2);
      expect(top2.length, 2);
      expect(top2[0].key, 'class_b');
      expect(top2[0].value, 0.85);
      expect(top2[1].key, 'class_a');
      expect(top2[1].value, 0.10);

      expect(output.getTopK(0), isEmpty);
    });

    test('throws ArgumentError if probabilities count mismatches labels count', () {
      expect(
        () => RawInferenceOutput.fromProbabilities(
          probabilities: [0.5, 0.5],
          labels: ['one'],
          inferenceTimeMs: 10,
        ),
        throwsArgumentError,
      );
    });

    test('serializes and deserializes toJson / fromJson round-trip', () {
      final output = RawInferenceOutput.fromProbabilities(
        probabilities: [0.6, 0.4],
        labels: ['label_1', 'label_2'],
        inferenceTimeMs: 35,
      );

      final json = output.toJson();
      final restored = RawInferenceOutput.fromJson(json);

      expect(restored.probabilities, output.probabilities);
      expect(restored.labels, output.labels);
      expect(restored.inferenceTimeMs, output.inferenceTimeMs);
      expect(restored.topLabel, output.topLabel);
      expect(restored.topConfidence, output.topConfidence);
      expect(restored, equals(output));
    });
  });

  group('InferenceService normalization', () {
    test('applySoftmax handles arbitrary logits and sums to 1.0', () {
      final logits = [10.0, 5.0, 1.0];
      final probs = InferenceService.normalizeProbabilities(logits);

      expect(probs.length, 3);
      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
      expect(probs[0], greaterThan(probs[1]));
      expect(probs[1], greaterThan(probs[2]));
    });

    test('keeps already normalized probabilities unchanged', () {
      final input = [0.70, 0.20, 0.10];
      final probs = InferenceService.normalizeProbabilities(input);

      expect(probs[0], closeTo(0.70, 0.001));
      expect(probs[1], closeTo(0.20, 0.001));
      expect(probs[2], closeTo(0.10, 0.001));
    });

    test('returns empty list for empty input', () {
      expect(InferenceService.normalizeProbabilities([]), isEmpty);
    });
  });

  group('InferenceService uninitialized and invalid errors', () {
    test('throws InferenceNotInitializedException if run without init', () async {
      final service = InferenceService();
      final tempFile = File('dummy.jpg');

      expect(
        () => service.runInference(tempFile),
        throwsA(isA<InferenceNotInitializedException>()),
      );
    });

    test('throws InvalidImageException if file does not exist', () async {
      final service = InferenceService(
        customRunner: (tensor) async => List.filled(15, 1.0 / 15),
        labels: List.generate(15, (i) => 'label_$i'),
      );

      final nonExistentFile = File('this_file_does_not_exist_at_all.jpg');
      expect(
        () => service.runInference(nonExistentFile),
        throwsA(isA<InvalidImageException>()),
      );
    });

    test('throws InvalidImageException if image bytes cannot be decoded', () async {
      final service = InferenceService(
        customRunner: (tensor) async => List.filled(15, 1.0 / 15),
        labels: List.generate(15, (i) => 'label_$i'),
      );

      final corruptedBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(
        () => service.runInferenceOnBytes(corruptedBytes),
        throwsA(isA<InvalidImageException>()),
      );
    });
  });

  group('InferenceService on-device execution with real model', () {
    late InferenceService service;
    late Directory tempDir;

    setUp(() async {
      service = InferenceService();
      await service.initialize(
        modelFile: modelFile,
        customLabels: labelsFile.existsSync()
            ? labelsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList()
            : null,
      );
      tempDir = await Directory.systemTemp.createTemp('planten_inference_test_');
    });

    tearDown(() async {
      service.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initializes correctly with 15 labels', () {
      expect(service.isInitialized, isTrue);
      expect(service.labels.length, 15);
      expect(service.labels, contains('tomato_early_blight'));
      expect(service.labels, contains('cotton_healthy'));
    });

    test('runs inference on valid image file under 3 seconds', () async {
      // Create a synthetic green leaf image (256x256)
      final testImg = img.Image(width: 256, height: 256);
      for (var y = 0; y < testImg.height; y++) {
        for (var x = 0; x < testImg.width; x++) {
          testImg.setPixelRgb(x, y, 34, 139, 34); // Forest green leaf color
        }
      }

      final pngBytes = Uint8List.fromList(img.encodePng(testImg));
      final file = File('${tempDir.path}/test_leaf.png');
      await file.writeAsBytes(pngBytes);

      final output = await service.runInference(file);

      // Verify outputs
      expect(output.probabilities.length, 15);
      expect(output.labels.length, 15);
      final sum = output.probabilities.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.02), reason: 'Probabilities must sum to ~1.0');
      expect(output.topLabel, isNotEmpty);
      expect(output.topConfidence, inInclusiveRange(0.0, 1.0));
      expect(output.inferenceTimeMs, lessThan(3000), reason: 'Latency must be < 3s');
    });

    test('runs inference on bytes and pre-decoded image', () async {
      final testImg = img.Image(width: 100, height: 100);
      for (var y = 0; y < testImg.height; y++) {
        for (var x = 0; x < testImg.width; x++) {
          testImg.setPixelRgb(x, y, 120, 180, 50);
        }
      }

      final pngBytes = Uint8List.fromList(img.encodePng(testImg));

      // Test runInferenceOnBytes
      final bytesOutput = await service.runInferenceOnBytes(pngBytes);
      expect(bytesOutput.probabilities.length, 15);

      // Test runInferenceOnImage
      final imgOutput = await service.runInferenceOnImage(testImg);
      expect(imgOutput.probabilities.length, 15);
      expect(imgOutput.inferenceTimeMs, lessThan(3000));
    });

    test('dispose clears initialized state', () {
      service.dispose();
      expect(service.isInitialized, isFalse);
      expect(
        () => service.runInferenceOnImage(img.Image(width: 224, height: 224)),
        throwsA(isA<InferenceNotInitializedException>()),
      );
    });

    test('demo mode outputs high-confidence (>85%) prediction for visual testing', () async {
      service.enableDemoMode(enabled: true);
      expect(service.isDemoModeEnabled, isTrue);

      // Clean green leaf -> Tomato Healthy (93%)
      final cleanImg = img.Image(width: 100, height: 100);
      for (var y = 0; y < cleanImg.height; y++) {
        for (var x = 0; x < cleanImg.width; x++) {
          cleanImg.setPixelRgb(x, y, 40, 160, 40);
        }
      }

      final outputClean = await service.runInferenceOnImage(cleanImg);
      expect(outputClean.topConfidence, greaterThan(0.85));
      expect(outputClean.topLabel, equals('tomato_healthy'));

      // Diseased leaf with brown spots -> Tomato Early Blight (89%)
      final diseasedImg = img.Image(width: 100, height: 100);
      for (var y = 0; y < diseasedImg.height; y++) {
        for (var x = 0; x < diseasedImg.width; x++) {
          diseasedImg.setPixelRgb(x, y, 140, 60, 20); // brown lesions
        }
      }

      final outputDiseased = await service.runInferenceOnImage(diseasedImg);
      expect(outputDiseased.topConfidence, greaterThan(0.85));
      expect(outputDiseased.topLabel, equals('tomato_early_blight'));

      // Disable demo mode
      service.enableDemoMode(enabled: false);
      expect(service.isDemoModeEnabled, isFalse);
    });
  });
}
