import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/l10n/app_localizations.dart';

void main() {
  group('Localization Verification (Task 08)', () {
    testWidgets('English localizations load correctly', (WidgetTester tester) async {
      late AppLocalizations localizations;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(localizations.appTitle, equals('Planten'));
      expect(localizations.selectCrop, equals('Select Crop'));
      expect(localizations.scanTitle, equals('Scan Crop Leaf'));
      expect(localizations.healthyPlant, equals('Healthy Plant'));
      expect(localizations.consultExpert, equals('Consult Agriculture Expert'));
    });

    testWidgets('Vernacular Hindi localizations load correctly', (WidgetTester tester) async {
      late AppLocalizations localizations;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('hi'),
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(localizations.appTitle, equals('प्लांटन'));
      expect(localizations.selectCrop, equals('अपनी फसल चुनें'));
      expect(localizations.scanTitle, equals('पत्ती की फोटो लें'));
      expect(localizations.healthyPlant, equals('फसल स्वस्थ है'));
      expect(localizations.uncertainDiagnosis, equals('निदान अनिश्चित — कृषि विशेषज्ञ से संपर्क करें'));
      expect(localizations.consultExpert, equals('कृषि अधिकारी से सलाह लें'));
      expect(localizations.retakePhoto, equals('साफ़ फोटो दोबारा लें'));
    });
  });
}
