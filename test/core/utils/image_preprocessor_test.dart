import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:planten/core/utils/image_preprocessor.dart';

void main() {
  group('ImagePreprocessor (Task 38)', () {
    test('centerCropSquare crops landscape image to center square', () {
      final landscape = img.Image(width: 400, height: 300);
      final cropped = ImagePreprocessor.centerCropSquare(landscape);

      expect(cropped.width, 300);
      expect(cropped.height, 300);
    });

    test('centerCropSquare crops portrait image to center square', () {
      final portrait = img.Image(width: 300, height: 500);
      final cropped = ImagePreprocessor.centerCropSquare(portrait);

      expect(cropped.width, 300);
      expect(cropped.height, 300);
    });

    test('centerCropSquare returns square image directly', () {
      final square = img.Image(width: 250, height: 250);
      final cropped = ImagePreprocessor.centerCropSquare(square);

      expect(cropped.width, 250);
      expect(cropped.height, 250);
    });

    test('resizeAndCrop outputs exact target dimensions', () {
      final photo = img.Image(width: 800, height: 600);

      // Default dimensions (224x224)
      final processedDefault = ImagePreprocessor.resizeAndCrop(photo);
      expect(processedDefault.width, 224);
      expect(processedDefault.height, 224);

      // Custom dimensions (128x128)
      final processedCustom = ImagePreprocessor.resizeAndCrop(
        photo,
        targetWidth: 128,
        targetHeight: 128,
      );
      expect(processedCustom.width, 128);
      expect(processedCustom.height, 128);
    });

    test('toFloat32Buffer with NormalizationType.zeroToOne normalizes to [0.0, 1.0]', () {
      final image = img.Image(width: 50, height: 50);
      // Fill with solid pure red (255, 0, 0)
      img.fill(image, color: img.ColorRgb8(255, 0, 0));

      final buffer = ImagePreprocessor.toFloat32Buffer(
        image,
        normalization: NormalizationType.zeroToOne,
        targetWidth: 50,
        targetHeight: 50,
      );

      expect(buffer.length, 50 * 50 * 3);

      // Verify red pixel: R=1.0, G=0.0, B=0.0
      expect(buffer[0], closeTo(1.0, 0.001));
      expect(buffer[1], closeTo(0.0, 0.001));
      expect(buffer[2], closeTo(0.0, 0.001));

      // Verify entire buffer in range
      for (final val in buffer) {
        expect(val, inInclusiveRange(0.0, 1.0));
      }
    });

    test('toFloat32Buffer with NormalizationType.minusOneToOne normalizes to [-1.0, 1.0]', () {
      final image = img.Image(width: 20, height: 20);
      // Fill with pure blue (0, 0, 255)
      img.fill(image, color: img.ColorRgb8(0, 0, 255));

      final buffer = ImagePreprocessor.toFloat32Buffer(
        image,
        normalization: NormalizationType.minusOneToOne,
        targetWidth: 20,
        targetHeight: 20,
      );

      expect(buffer.length, 20 * 20 * 3);

      // Verify blue pixel: R=-1.0, G=-1.0, B=1.0
      expect(buffer[0], closeTo(-1.0, 0.001));
      expect(buffer[1], closeTo(-1.0, 0.001));
      expect(buffer[2], closeTo(1.0, 0.001));
    });

    test('toFloat32Buffer with NormalizationType.imageNet standardizes with ImageNet mean/std', () {
      final image = img.Image(width: 10, height: 10);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      final buffer = ImagePreprocessor.toFloat32Buffer(
        image,
        normalization: NormalizationType.imageNet,
        targetWidth: 10,
        targetHeight: 10,
      );

      // (1.0 - 0.485) / 0.229 = ~2.2489
      expect(buffer[0], closeTo((1.0 - 0.485) / 0.229, 0.01));
      // (1.0 - 0.456) / 0.224 = ~2.4285
      expect(buffer[1], closeTo((1.0 - 0.456) / 0.224, 0.01));
      // (1.0 - 0.406) / 0.225 = ~2.64
      expect(buffer[2], closeTo((1.0 - 0.406) / 0.225, 0.01));
    });

    test('toUint8Buffer produces correctly shaped byte buffer for quantized models', () {
      final image = img.Image(width: 30, height: 30);
      img.fill(image, color: img.ColorRgb8(200, 100, 50));

      final buffer = ImagePreprocessor.toUint8Buffer(
        image,
        targetWidth: 30,
        targetHeight: 30,
      );

      expect(buffer.length, 30 * 30 * 3);
      expect(buffer[0], 200);
      expect(buffer[1], 100);
      expect(buffer[2], 50);
    });

    test('to4DList produces tensor with shape [1][H][W][3]', () {
      final image = img.Image(width: 16, height: 16);
      img.fill(image, color: img.ColorRgb8(120, 150, 180));

      final tensor4D = ImagePreprocessor.to4DList(
        image,
        targetWidth: 16,
        targetHeight: 16,
      );

      // Batch size
      expect(tensor4D.length, 1);

      // Height
      expect(tensor4D[0].length, 16);

      // Width
      expect(tensor4D[0][0].length, 16);

      // Channels
      expect(tensor4D[0][0][0].length, 3);
      expect(tensor4D[0][0][0][0], closeTo(120 / 255.0, 0.001));
      expect(tensor4D[0][0][0][1], closeTo(150 / 255.0, 0.001));
      expect(tensor4D[0][0][0][2], closeTo(180 / 255.0, 0.001));
    });

    test('loadAndPreprocessBytes decodes and resizes valid PNG bytes', () {
      final original = img.Image(width: 100, height: 80);
      img.fill(original, color: img.ColorRgb8(50, 150, 250));
      final bytes = img.encodePng(original);

      final processed = ImagePreprocessor.loadAndPreprocessBytes(
        bytes,
        targetWidth: 224,
        targetHeight: 224,
      );

      expect(processed, isNotNull);
      expect(processed!.width, 224);
      expect(processed.height, 224);
    });

    test('loadAndPreprocessBytes returns null on corrupted bytes', () {
      final corrupt = Uint8List.fromList([1, 2, 3, 4, 5]);
      final processed = ImagePreprocessor.loadAndPreprocessBytes(corrupt);

      expect(processed, isNull);
    });

    test('loadAndPreprocessFile returns null when file does not exist', () async {
      final processed = await ImagePreprocessor.loadAndPreprocessFile(
        'missing/leaf_path.jpg',
      );

      expect(processed, isNull);
    });
  });
}
