import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Represents the quality verification outcome of a leaf photograph.
class ImageQualityResult {
  /// Whether the photo satisfies lighting and sharpness requirements for AI inference.
  final bool isValid;

  /// Whether the image is severely underexposed or captured in dark conditions.
  final bool isTooDark;

  /// Whether the image is severely overexposed or washed out by harsh glare.
  final bool isTooBright;

  /// Whether the image is severely out-of-focus or motion-blurred.
  final bool isTooBlurry;

  /// Average luminance score across the image on a 0.0 to 255.0 scale.
  final double averageLuminance;

  /// Variance of the Laplacian operator measuring high-frequency edge energy.
  final double sharpnessScore;

  /// English warning message explaining the quality defect, or null if valid.
  final String? warningMessageEn;

  /// Hindi warning message explaining the quality defect, or null if valid.
  final String? warningMessageHi;

  const ImageQualityResult({
    required this.isValid,
    this.isTooDark = false,
    this.isTooBright = false,
    this.isTooBlurry = false,
    this.averageLuminance = 0.0,
    this.sharpnessScore = 0.0,
    this.warningMessageEn,
    this.warningMessageHi,
  });

  /// Factory for constructing an unreadable or missing file error result.
  factory ImageQualityResult.invalid({
    required String warningMessageEn,
    required String warningMessageHi,
  }) {
    return ImageQualityResult(
      isValid: false,
      warningMessageEn: warningMessageEn,
      warningMessageHi: warningMessageHi,
    );
  }

  /// Returns the localized warning message matching [languageCode] (`'en'` or `'hi'`).
  String? localizedWarning(String languageCode) {
    if (languageCode == 'hi') {
      return warningMessageHi ?? warningMessageEn;
    }
    return warningMessageEn;
  }
}

/// Utility for assessing lighting and sharpness of leaf images before AI inference.
///
/// Features:
/// - Fast performance: resizes to a standardized grid to complete in <50ms.
/// - Calculates average luminance (0-255) to detect underexposure or overexposure.
/// - Applies discrete 2D Laplacian convolution to compute gradient edge variance for blur detection.
abstract final class ImageQualityChecker {
  /// Default minimum average luminance below which an image is considered too dark.
  static const double defaultDarkThreshold = 35.0;

  /// Default maximum average luminance above which an image is considered overexposed.
  static const double defaultBrightThreshold = 230.0;

  /// Default minimum Laplacian variance below which an image is considered blurry.
  static const double defaultBlurThreshold = 45.0;

  /// Standard resolution for fast edge and luminance analysis.
  static const int standardAnalysisSize = 180;

  /// Analyzes image quality from a file on the local filesystem.
  static Future<ImageQualityResult> checkQualityFromFile(
    String filePath, {
    double darkThreshold = defaultDarkThreshold,
    double brightThreshold = defaultBrightThreshold,
    double blurThreshold = defaultBlurThreshold,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ImageQualityResult.invalid(
        warningMessageEn: 'Image file does not exist.',
        warningMessageHi: 'फोटो फाइल मौजूद नहीं है।',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      return checkQualityFromBytes(
        bytes,
        darkThreshold: darkThreshold,
        brightThreshold: brightThreshold,
        blurThreshold: blurThreshold,
      );
    } catch (e) {
      return ImageQualityResult.invalid(
        warningMessageEn: 'Failed to read image file: $e',
        warningMessageHi: 'फोटो फाइल पढ़ने में त्रुटि।',
      );
    }
  }

  /// Analyzes image quality from raw compressed image bytes (JPEG, PNG, WebP).
  static ImageQualityResult checkQualityFromBytes(
    Uint8List bytes, {
    double darkThreshold = defaultDarkThreshold,
    double brightThreshold = defaultBrightThreshold,
    double blurThreshold = defaultBlurThreshold,
  }) {
    try {
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return ImageQualityResult.invalid(
          warningMessageEn: 'Failed to decode image data.',
          warningMessageHi: 'फोटो लोड करने में विफल।',
        );
      }

      return checkQuality(
        decoded,
        darkThreshold: darkThreshold,
        brightThreshold: brightThreshold,
        blurThreshold: blurThreshold,
      );
    } catch (e) {
      return ImageQualityResult.invalid(
        warningMessageEn: 'Failed to decode image data: $e',
        warningMessageHi: 'फोटो लोड करने में विफल।',
      );
    }
  }

  /// Analyzes an in-memory [img.Image] for lighting and blur.
  static ImageQualityResult checkQuality(
    img.Image image, {
    double darkThreshold = defaultDarkThreshold,
    double brightThreshold = defaultBrightThreshold,
    double blurThreshold = defaultBlurThreshold,
    int analysisSize = standardAnalysisSize,
  }) {
    // 1. Downsample and convert to grayscale for fast, memory-safe evaluation
    final img.Image resized = (image.width > analysisSize || image.height > analysisSize)
        ? img.copyResize(
            image,
            width: analysisSize,
            height: analysisSize,
            interpolation: img.Interpolation.linear,
          )
        : image;

    final img.Image gray = img.grayscale(resized);
    final width = gray.width;
    final height = gray.height;

    // 2. Compute Average Luminance across all pixels
    double totalLuminance = 0.0;
    final List<List<double>> matrix = List.generate(
      width,
      (_) => List<double>.filled(height, 0.0),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = gray.getPixel(x, y);
        // Since image is grayscale, r == g == b
        final lum = pixel.r.toDouble();
        matrix[x][y] = lum;
        totalLuminance += lum;
      }
    }

    final totalPixels = width * height;
    final avgLuminance = totalPixels > 0 ? totalLuminance / totalPixels : 0.0;

    // 3. Compute Discrete 2D Laplacian Operator:
    // [  0,  1,  0 ]
    // [  1, -4,  1 ]
    // [  0,  1,  0 ]
    double sumLaplacian = 0.0;
    int laplacianCount = 0;

    // Buffer to hold laplacian responses
    final List<double> laplacianValues = [];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final val = matrix[x + 1][y] +
            matrix[x - 1][y] +
            matrix[x][y + 1] +
            matrix[x][y - 1] -
            (4.0 * matrix[x][y]);

        sumLaplacian += val;
        laplacianValues.add(val);
        laplacianCount++;
      }
    }

    // 4. Calculate Variance of Laplacian (Sharpness Score)
    double sharpness = 0.0;
    if (laplacianCount > 0) {
      final meanLaplacian = sumLaplacian / laplacianCount;
      double sumSquaredDiff = 0.0;
      for (final val in laplacianValues) {
        final diff = val - meanLaplacian;
        sumSquaredDiff += diff * diff;
      }
      sharpness = sumSquaredDiff / laplacianCount;
    }

    // 5. Evaluate Quality Thresholds
    final isTooDark = avgLuminance < darkThreshold;
    final isTooBright = avgLuminance > brightThreshold;
    final isTooBlurry = sharpness < blurThreshold;

    final isValid = !isTooDark && !isTooBright && !isTooBlurry;

    String? warningEn;
    String? warningHi;

    if (isTooDark) {
      warningEn = 'Photo appears too dark. Please take photo in good daylight.';
      warningHi = 'फोटो बहुत धुंधली या अंधेरे में है। कृपया अच्छी रोशनी में फोटो लें।';
    } else if (isTooBright) {
      warningEn = 'Photo appears overexposed. Please avoid direct harsh glare.';
      warningHi = 'फोटो में बहुत तेज रोशनी या चमक है। कृपया सीधी तेज धूप से बचें।';
    } else if (isTooBlurry) {
      warningEn = 'Photo appears blurry. Please hold camera steady.';
      warningHi = 'फोटो धुंधली दिख रही है। कृपया कैमरा स्थिर रखें।';
    }

    return ImageQualityResult(
      isValid: isValid,
      isTooDark: isTooDark,
      isTooBright: isTooBright,
      isTooBlurry: isTooBlurry,
      averageLuminance: double.parse(avgLuminance.toStringAsFixed(1)),
      sharpnessScore: double.parse(sharpness.toStringAsFixed(1)),
      warningMessageEn: warningEn,
      warningMessageHi: warningHi,
    );
  }
}
