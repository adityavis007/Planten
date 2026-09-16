import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:planten/core/utils/image_quality_checker.dart';

void main() {
  group('Image Quality Pre-Check Logic (Task 56)', () {
    test('sharp, well-lit textured leaf photograph passes quality check', () {
      final validImage = img.Image(width: 100, height: 100);
      // Generate a sharp high-frequency checkerboard pattern with moderate luminance
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          final isEven = ((x ~/ 5) + (y ~/ 5)) % 2 == 0;
          final colorVal = isEven ? 160 : 60;
          validImage.setPixel(x, y, img.ColorRgb8(colorVal, colorVal, colorVal));
        }
      }

      final result = ImageQualityChecker.checkQuality(validImage);

      expect(result.isValid, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.isTooBright, isFalse);
      expect(result.isTooBlurry, isFalse);
      expect(result.warningMessageEn, isNull);
      expect(result.warningMessageHi, isNull);
      expect(result.averageLuminance, inInclusiveRange(70.0, 150.0));
      expect(result.sharpnessScore, greaterThanOrEqualTo(ImageQualityChecker.defaultBlurThreshold));
    });

    test('underexposed photo (< 35.0 luminance) is detected as too dark and invalid', () {
      final darkImage = img.Image(width: 80, height: 80);
      // Extremely low luminance pixel values
      img.fill(darkImage, color: img.ColorRgb8(15, 15, 15));

      final result = ImageQualityChecker.checkQuality(darkImage);

      expect(result.isValid, isFalse);
      expect(result.isTooDark, isTrue);
      expect(result.isTooBright, isFalse);
      expect(result.averageLuminance, lessThan(35.0));
      expect(result.warningMessageEn, contains('too dark'));
      expect(result.warningMessageHi, contains('अंधेरे'));
      expect(result.localizedWarning('en'), contains('too dark'));
      expect(result.localizedWarning('hi'), contains('अंधेरे'));
    });

    test('overexposed photo (> 230.0 luminance) is detected as too bright and invalid', () {
      final brightImage = img.Image(width: 80, height: 80);
      // Overexposed washed out pixels
      img.fill(brightImage, color: img.ColorRgb8(245, 245, 245));

      final result = ImageQualityChecker.checkQuality(brightImage);

      expect(result.isValid, isFalse);
      expect(result.isTooBright, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.averageLuminance, greaterThan(230.0));
      expect(result.warningMessageEn, contains('overexposed'));
      expect(result.warningMessageHi, contains('रोशनी'));
      expect(result.localizedWarning('en'), contains('overexposed'));
      expect(result.localizedWarning('hi'), contains('रोशनी'));
    });

    test('motion-blurred / out-of-focus flat photo is detected as blurry and invalid', () {
      final blurryImage = img.Image(width: 80, height: 80);
      // Uniform grey image has zero edge gradients
      img.fill(blurryImage, color: img.ColorRgb8(120, 120, 120));

      final result = ImageQualityChecker.checkQuality(blurryImage);

      expect(result.isValid, isFalse);
      expect(result.isTooBlurry, isTrue);
      expect(result.sharpnessScore, equals(0.0));
      expect(result.warningMessageEn, contains('blurry'));
      expect(result.warningMessageHi, contains('धुंधली'));
      expect(result.localizedWarning('en'), contains('blurry'));
      expect(result.localizedWarning('hi'), contains('धुंधली'));
    });

    test('checkQualityFromBytes parses valid encoded PNG bytes', () {
      final image = img.Image(width: 50, height: 50);
      for (int y = 0; y < 50; y++) {
        for (int x = 0; x < 50; x++) {
          final isEven = (x + y) % 2 == 0;
          image.setPixel(x, y, isEven ? img.ColorRgb8(200, 200, 200) : img.ColorRgb8(50, 50, 50));
        }
      }
      final pngBytes = Uint8List.fromList(img.encodePng(image));

      final result = ImageQualityChecker.checkQualityFromBytes(pngBytes);
      expect(result.isValid, isTrue);
      expect(result.averageLuminance, inInclusiveRange(50.0, 200.0));
    });

    test('checkQualityFromBytes returns invalid on corrupted bytes without throwing', () {
      final corruptBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

      final result = ImageQualityChecker.checkQualityFromBytes(corruptBytes);
      expect(result.isValid, isFalse);
      expect(result.warningMessageEn, contains('Failed to decode'));
      expect(result.warningMessageHi, contains('विफल'));
    });

    test('checkQualityFromFile returns invalid on non-existent file path', () async {
      final result = await ImageQualityChecker.checkQualityFromFile('invalid/path/leaf_nonexistent.jpg');

      expect(result.isValid, isFalse);
      expect(result.warningMessageEn, contains('does not exist'));
      expect(result.warningMessageHi, contains('मौजूद नहीं है'));
    });

    test('supports customized sensitivity thresholds', () {
      final image = img.Image(width: 50, height: 50);
      img.fill(image, color: img.ColorRgb8(50, 50, 50)); // Luminance ~50

      // With default threshold (35.0), luminance 50 is NOT too dark
      final defaultResult = ImageQualityChecker.checkQuality(image);
      expect(defaultResult.isTooDark, isFalse);

      // With stricter custom threshold (60.0), luminance 50 IS too dark
      final strictResult = ImageQualityChecker.checkQuality(image, darkThreshold: 60.0);
      expect(strictResult.isTooDark, isTrue);
      expect(strictResult.isValid, isFalse);
    });
  });
}
