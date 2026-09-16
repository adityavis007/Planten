import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/crop.dart';
import 'package:planten/screens/crops/crop_farming_detail_screen.dart';
import 'package:planten/screens/crops/my_crop_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    );
  }

  group('MyCropScreen & CropFarmingDetailScreen (Wireframe Implementation)', () {
    testWidgets('MyCropScreen renders title, guidance banner, and 2-column crop grid', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const MyCropScreen()));
      await tester.pumpAndSettle();

      // Header title
      expect(find.text('My Crop'), findsOneWidget);

      // Grid of crops
      expect(find.byKey(const ValueKey('my_crop_grid')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_tomato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_potato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_card_chili')), findsOneWidget);

      // Crop names initially visible
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Potato'), findsOneWidget);
      expect(find.text('Wheat'), findsOneWidget);

      // Scroll to reveal 5th crop (Cotton)
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('crop_card_cotton')),
        100.0,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(const ValueKey('crop_card_cotton')), findsOneWidget);
    });

    testWidgets('MyCropScreen renders Hindi vernacular text when locale is hi', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MyCropScreen(),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('मेरी फसलें (My Crop)'), findsOneWidget);
      expect(find.text('टमाटर'), findsOneWidget);
      expect(find.text('आलू'), findsOneWidget);
      expect(find.text('गेहूं'), findsOneWidget);
    });

    testWidgets('tapping crop card invokes onCropTap callback', (tester) async {
      Crop? selectedCrop;

      await tester.pumpWidget(buildTestableWidget(
        MyCropScreen(
          onCropTap: (crop) {
            selectedCrop = crop;
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('crop_card_tomato')));
      await tester.pumpAndSettle();

      expect(selectedCrop, isNotNull);
      expect(selectedCrop!.id, 'tomato');
    });

    testWidgets('CropFarmingDetailScreen renders all components from wireframe Screen 2', (tester) async {
      const tomatoCrop = Crop(
        id: 'tomato',
        nameEn: 'Tomato',
        nameHi: 'टमाटर',
        iconAssetPath: 'assets/icons/crops/tomato.png',
      );

      await tester.pumpWidget(buildTestableWidget(
        const CropFarmingDetailScreen(crop: tomatoCrop),
      ));
      await tester.pumpAndSettle();

      // App Bar Title
      expect(find.text('Tomato Farming Guide'), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_detail_back_button')), findsOneWidget);

      // Top section: Crop Name, Duration, Best Weather
      expect(find.textContaining('Time / Duration:'), findsOneWidget);
      expect(find.textContaining('90 - 120 Days'), findsOneWidget);
      expect(find.textContaining('Best Weather:'), findsOneWidget);
      expect(find.textContaining('20°C - 28°C'), findsOneWidget);

      // Card 1: Management Guidance with (O) icon
      expect(find.text('Management Guidance'), findsOneWidget);
      expect(find.textContaining('Well-drained sandy loam'), findsOneWidget);

      // Card 2: Symptoms
      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.textContaining('Early Blight:'), findsOneWidget);
      expect(find.textContaining('Late Blight:'), findsOneWidget);

      // Card 3: Preventive Action (with bullet points)
      expect(find.text('Preventive Action'), findsOneWidget);
      expect(find.textContaining('Treat seeds with Trichoderma'), findsOneWidget);

      // Card 4: Important Safety
      expect(find.text('Important Safety'), findsOneWidget);
      expect(find.textContaining('Wear protective gloves'), findsOneWidget);

      // Bottom Badge: source: verified
      expect(find.textContaining('source: verified'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('CropFarmingDetailScreen renders in Hindi with vernacular agricultural terms', (tester) async {
      const wheatCrop = Crop(
        id: 'wheat',
        nameEn: 'Wheat',
        nameHi: 'गेहूं',
        iconAssetPath: 'assets/icons/crops/wheat.png',
      );

      await tester.pumpWidget(buildTestableWidget(
        const CropFarmingDetailScreen(crop: wheatCrop),
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('गेहूं की खेती'), findsOneWidget);
      expect(find.textContaining('समय / अवधि:'), findsOneWidget);
      expect(find.textContaining('110 - 130 दिन'), findsOneWidget);
      expect(find.textContaining('प्रबंधन मार्गदर्शन'), findsOneWidget);
      expect(find.textContaining('निवारक उपाय'), findsOneWidget);
      expect(find.textContaining('महत्वपूर्ण सुरक्षा'), findsOneWidget);
      expect(find.textContaining('source: verified'), findsOneWidget);
    });

    testWidgets('tapping back button in CropFarmingDetailScreen navigates back', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const MyCropScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap on Tomato
      await tester.tap(find.byKey(const ValueKey('crop_card_tomato')));
      await tester.pumpAndSettle();

      expect(find.text('Tomato Farming Guide'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const ValueKey('crop_detail_back_button')));
      await tester.pumpAndSettle();

      // Back on MyCropScreen
      expect(find.text('My Crop'), findsOneWidget);
    });
  });
}
