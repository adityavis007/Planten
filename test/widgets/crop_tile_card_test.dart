import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_colors.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/models/crop.dart';
import 'package:planten/widgets/crop_tile_card.dart';

void main() {
  const tomatoCrop = Crop(
    id: 'tomato',
    nameEn: 'Tomato',
    nameHi: 'टमाटर',
    iconAssetPath: 'assets/icons/crops/tomato.png',
  );

  Widget buildTestable(Widget widget) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: widget),
      ),
    );
  }

  group('CropTileCard Widget (Task 18)', () {
    testWidgets('renders crop label and image, and fires onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestable(
          CropTileCard(
            crop: tomatoCrop,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Tomato'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.text('Tomato'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('supports Hindi localized name', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const CropTileCard(
            crop: tomatoCrop,
            languageCode: 'hi',
          ),
        ),
      );

      expect(find.text('टमाटर'), findsOneWidget);
    });

    testWidgets('displays checkmark badge and selection border when selected', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const CropTileCard(
            crop: tomatoCrop,
            isSelected: true,
          ),
        ),
      );

      // Checkmark icon visible
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Check shape border styling
      final materialFinder = find.descendant(
        of: find.byType(CropTileCard),
        matching: find.byType(Material),
      );
      final material = tester.widget<Material>(materialFinder);
      final shape = material.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.primary);
      expect(shape.side.width, 2.0);
    });

    testWidgets('omits checkmark badge when not selected', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const CropTileCard(
            crop: tomatoCrop,
            isSelected: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);

      final materialFinder = find.descendant(
        of: find.byType(CropTileCard),
        matching: find.byType(Material),
      );
      final material = tester.widget<Material>(materialFinder);
      final shape = material.shape as RoundedRectangleBorder;
      expect(shape.side.width, 1.0);
    });

    testWidgets('enforces minimum touch target of at least 100x100 dp', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const CropTileCard(
            crop: tomatoCrop,
            width: 50.0, // Requested smaller than minimum
            height: 50.0,
          ),
        ),
      );

      final cardFinder = find.byType(CropTileCard);
      final size = tester.getSize(cardFinder);
      expect(size.width, greaterThanOrEqualTo(100.0));
      expect(size.height, greaterThanOrEqualTo(100.0));
    });
  });
}
