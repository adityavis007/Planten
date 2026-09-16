import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Normalization schemes for machine learning input tensors.
enum NormalizationType {
  /// Scales pixel channels from [0, 255] to [0.0, 1.0].
  /// Common for MobileNetV2 and modern vision backbones.
  zeroToOne,

  /// Scales pixel channels from [0, 255] to [-1.0, 1.0].
  /// Common for Inception and EfficientNet models ((pixel - 127.5) / 127.5).
  minusOneToOne,

  /// Standardizes pixel channels using ImageNet mean & standard deviation:
  /// mean = [0.485, 0.456, 0.406], std = [0.229, 0.224, 0.225].
  imageNet,

  /// Leaves pixel channels as raw integers in [0, 255] (for quantized uint8 models).
  uint8,
}

/// Image preprocessing utilities for on-device LiteRT / TFLite inference.
///
/// Features:
/// - Aspect-ratio-preserving center square cropping matching leaf alignment frames.
/// - Bilinear resizing to model tensor dimensions (default 224x224).
/// - Multiple normalization modes (0..1, -1..1, ImageNet, quantized uint8).
/// - Conversion to flat 1D tensor buffers ([1, H, W, 3]) and nested 4D lists.
abstract final class ImagePreprocessor {
  /// Default input dimension for mobile vision backbones.
  static const int defaultInputSize = 224;

  // ImageNet standard statistics
  static const double _imageNetMeanR = 0.485;
  static const double _imageNetMeanG = 0.456;
  static const double _imageNetMeanB = 0.406;
  static const double _imageNetStdR = 0.229;
  static const double _imageNetStdG = 0.224;
  static const double _imageNetStdB = 0.225;

  /// Crops the center square of [image] preserving leaf lesion geometry.
  static img.Image centerCropSquare(img.Image image) {
    final size = min(image.width, image.height);
    if (image.width == size && image.height == size) {
      return image;
    }

    final xOffset = (image.width - size) ~/ 2;
    final yOffset = (image.height - size) ~/ 2;

    return img.copyCrop(
      image,
      x: xOffset,
      y: yOffset,
      width: size,
      height: size,
    );
  }

  /// Center-crops to square and resizes to [targetWidth] x [targetHeight].
  static img.Image resizeAndCrop(
    img.Image image, {
    int targetWidth = defaultInputSize,
    int targetHeight = defaultInputSize,
  }) {
    final cropped = centerCropSquare(image);

    if (cropped.width == targetWidth && cropped.height == targetHeight) {
      return cropped;
    }

    return img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Converts [image] into a flattened [Float32List] tensor buffer of shape
  /// `[1, targetHeight, targetWidth, 3]`.
  static Float32List toFloat32Buffer(
    img.Image image, {
    NormalizationType normalization = NormalizationType.zeroToOne,
    int targetWidth = defaultInputSize,
    int targetHeight = defaultInputSize,
  }) {
    final processed = resizeAndCrop(
      image,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    final totalFloats = targetWidth * targetHeight * 3;
    final buffer = Float32List(totalFloats);
    int bufferIndex = 0;

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = processed.getPixel(x, y);

        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        switch (normalization) {
          case NormalizationType.zeroToOne:
            buffer[bufferIndex++] = r / 255.0;
            buffer[bufferIndex++] = g / 255.0;
            buffer[bufferIndex++] = b / 255.0;
            break;

          case NormalizationType.minusOneToOne:
            buffer[bufferIndex++] = (r - 127.5) / 127.5;
            buffer[bufferIndex++] = (g - 127.5) / 127.5;
            buffer[bufferIndex++] = (b - 127.5) / 127.5;
            break;

          case NormalizationType.imageNet:
            final normR = r / 255.0;
            final normG = g / 255.0;
            final normB = b / 255.0;
            buffer[bufferIndex++] = (normR - _imageNetMeanR) / _imageNetStdR;
            buffer[bufferIndex++] = (normG - _imageNetMeanG) / _imageNetStdG;
            buffer[bufferIndex++] = (normB - _imageNetMeanB) / _imageNetStdB;
            break;

          case NormalizationType.uint8:
            buffer[bufferIndex++] = r;
            buffer[bufferIndex++] = g;
            buffer[bufferIndex++] = b;
            break;
        }
      }
    }

    return buffer;
  }

  /// Converts [image] into a flattened [Uint8List] tensor buffer of shape
  /// `[1, targetHeight, targetWidth, 3]` for quantized integer models.
  static Uint8List toUint8Buffer(
    img.Image image, {
    int targetWidth = defaultInputSize,
    int targetHeight = defaultInputSize,
  }) {
    final processed = resizeAndCrop(
      image,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    final totalBytes = targetWidth * targetHeight * 3;
    final buffer = Uint8List(totalBytes);
    int bufferIndex = 0;

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = processed.getPixel(x, y);
        buffer[bufferIndex++] = pixel.r.toInt().clamp(0, 255);
        buffer[bufferIndex++] = pixel.g.toInt().clamp(0, 255);
        buffer[bufferIndex++] = pixel.b.toInt().clamp(0, 255);
      }
    }

    return buffer;
  }

  /// Converts [image] into a nested 4D list with shape `[1][H][W][3]`.
  static List<List<List<List<double>>>> to4DList(
    img.Image image, {
    NormalizationType normalization = NormalizationType.zeroToOne,
    int targetWidth = defaultInputSize,
    int targetHeight = defaultInputSize,
  }) {
    final processed = resizeAndCrop(
      image,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    final List<List<List<double>>> batch = List.generate(
      targetHeight,
      (y) => List.generate(
        targetWidth,
        (x) {
          final pixel = processed.getPixel(x, y);
          final r = pixel.r.toDouble();
          final g = pixel.g.toDouble();
          final b = pixel.b.toDouble();

          switch (normalization) {
            case NormalizationType.zeroToOne:
              return [r / 255.0, g / 255.0, b / 255.0];
            case NormalizationType.minusOneToOne:
              return [
                (r - 127.5) / 127.5,
                (g - 127.5) / 127.5,
                (b - 127.5) / 127.5,
              ];
            case NormalizationType.imageNet:
              return [
                ((r / 255.0) - _imageNetMeanR) / _imageNetStdR,
                ((g / 255.0) - _imageNetMeanG) / _imageNetStdG,
                ((b / 255.0) - _imageNetMeanB) / _imageNetStdB,
              ];
            case NormalizationType.uint8:
              return [r, g, b];
          }
        },
      ),
    );

    return [batch];
  }

  /// Loads an image from [filePath], decodes it, center-crops, and resizes it.
  ///
  /// Returns `null` if the file cannot be read or decoded.
  static Future<img.Image?> loadAndPreprocessFile(
    String filePath, {
    int targetWidth = defaultInputSize,
    int targetHeight = defaultInputSize,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      return loadAndPreprocessBytes(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes raw image [bytes], center-crops to square, and resizes to target dimensions.
  ///
  /// Returns `null` if the byte stream cannot be decoded.
  static img.Image? loadAndPreprocessBytes(
    Uint8List bytes, {
    int targetWidth = defaultInputSize,
    int targetHeight = defaultInputSize,
  }) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return null;
      }
      return resizeAndCrop(
        decoded,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    } catch (_) {
      return null;
    }
  }
}
