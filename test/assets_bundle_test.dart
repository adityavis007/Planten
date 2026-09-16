import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 12: Assets & Model Verification', () {
    const requiredAssets = [
      'assets/model/crop_doctor_model.tflite',
      'assets/model/labels.txt',
      'assets/icons/crops/tomato.png',
      'assets/icons/crops/potato.png',
      'assets/icons/crops/wheat.png',
      'assets/icons/crops/chili.png',
      'assets/icons/crops/cotton.png',
    ];

    for (final assetPath in requiredAssets) {
      test('loads $assetPath successfully via rootBundle', () async {
        final byteData = await rootBundle.load(assetPath);
        expect(byteData, isNotNull);
        expect(byteData.lengthInBytes, greaterThan(0));
      });
    }

    test('labels.txt contains exactly 15 valid classification classes', () async {
      final text = await rootBundle.loadString('assets/model/labels.txt');
      final labels = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      expect(labels.length, 15);
      expect(labels, contains('tomato_early_blight'));
      expect(labels, contains('potato_early_blight'));
      expect(labels, contains('wheat_yellow_rust'));
      expect(labels, contains('chili_leaf_curl'));
      expect(labels, contains('cotton_bacterial_blight'));
    });
  });
}
