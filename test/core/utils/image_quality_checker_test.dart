import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:planten/core/utils/image_quality_checker.dart';

void main() {
  group('ImageQualityChecker (Task 36)', () {
    test('detects solid black image as too dark and invalid', () {
      final blackImage = img.Image(width: 100, height: 100);
      img.fill(blackImage, color: img.ColorRgb8(0, 0, 0));

      final result = ImageQualityChecker.checkQuality(blackImage);

      expect(result.isValid, isFalse);
      expect(result.isTooDark, isTrue);
      expect(result.isTooBright, isFalse);
      expect(result.averageLuminance, 0.0);
      expect(result.warningMessageEn, contains('too dark'));
      expect(result.warningMessageHi, contains('अंधेरे'));
      expect(result.localizedWarning('en'), contains('too dark'));
      expect(result.localizedWarning('hi'), contains('अंधेरे'));
    });

    test('detects solid white image as too bright / overexposed and invalid', () {
      final whiteImage = img.Image(width: 100, height: 100);
      img.fill(whiteImage, color: img.ColorRgb8(255, 255, 255));

      final result = ImageQualityChecker.checkQuality(whiteImage);

      expect(result.isValid, isFalse);
      expect(result.isTooBright, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.averageLuminance, 255.0);
      expect(result.warningMessageEn, contains('overexposed'));
      expect(result.warningMessageHi, contains('रोशनी'));
    });

    test('detects flat uniform grey image as blurry (zero edge contrast)', () {
      final greyImage = img.Image(width: 100, height: 100);
      img.fill(greyImage, color: img.ColorRgb8(128, 128, 128));

      final result = ImageQualityChecker.checkQuality(greyImage);

      expect(result.isValid, isFalse);
      expect(result.isTooBlurry, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.isTooBright, isFalse);
      expect(result.averageLuminance, closeTo(128.0, 2.0));
      expect(result.sharpnessScore, 0.0);
      expect(result.warningMessageEn, contains('blurry'));
      expect(result.warningMessageHi, contains('धुंधली'));
    });

    test('detects high-contrast textured image as valid and sharp', () {
      final checkerImage = img.Image(width: 100, height: 100);
      // Create high-contrast alternating checkerboard pattern
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final isEvenSquare = ((x ~/ 10) + (y ~/ 10)) % 2 == 0;
          final color = isEvenSquare
              ? img.ColorRgb8(240, 240, 240)
              : img.ColorRgb8(20, 20, 20);
          checkerImage.setPixel(x, y, color);
        }
      }

      final result = ImageQualityChecker.checkQuality(checkerImage);

      expect(result.isValid, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.isTooBright, isFalse);
      expect(result.isTooBlurry, isFalse);
      expect(result.sharpnessScore, greaterThan(ImageQualityChecker.defaultBlurThreshold));
      expect(result.warningMessageEn, isNull);
      expect(result.warningMessageHi, isNull);
    });

    test('respects custom luminance and blur thresholds', () {
      final midImage = img.Image(width: 100, height: 100);
      img.fill(midImage, color: img.ColorRgb8(60, 60, 60));

      // With default threshold (35.0), 60.0 is not too dark
      final defaultResult = ImageQualityChecker.checkQuality(midImage);
      expect(defaultResult.isTooDark, isFalse);

      // With strict threshold (80.0), 60.0 is too dark
      final strictResult = ImageQualityChecker.checkQuality(
        midImage,
        darkThreshold: 80.0,
      );
      expect(strictResult.isTooDark, isTrue);
      expect(strictResult.isValid, isFalse);
    });

    test('analyzes image from compressed PNG bytes correctly', () {
      final testImage = img.Image(width: 50, height: 50);
      img.fill(testImage, color: img.ColorRgb8(10, 10, 10));
      final pngBytes = img.encodePng(testImage);

      final result = ImageQualityChecker.checkQualityFromBytes(pngBytes);

      expect(result.isValid, isFalse);
      expect(result.isTooDark, isTrue);
    });

    test('handles corrupted image bytes gracefully', () {
      final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = ImageQualityChecker.checkQualityFromBytes(corruptBytes);

      expect(result.isValid, isFalse);
      expect(result.warningMessageEn, contains('Failed to decode'));
      expect(result.warningMessageHi, contains('विफल'));
    });

    test('handles non-existent image file path gracefully', () async {
      final result = await ImageQualityChecker.checkQualityFromFile(
        'non_existent_folder/missing_leaf.jpg',
      );

      expect(result.isValid, isFalse);
      expect(result.warningMessageEn, contains('does not exist'));
      expect(result.warningMessageHi, contains('मौजूद नहीं है'));
    });
  });
}
