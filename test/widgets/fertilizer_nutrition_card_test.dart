import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/treatment_model.dart';
import 'package:planten/widgets/fertilizer_nutrition_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleGuidance = TreatmentModel(
    diseaseId: 'tomato_early_blight',
    crop: 'tomato',
    nameEn: 'Early Blight',
    nameHi: 'अगेती झुलसा',
    symptomsEn: 'Concentric dark brown rings on lower leaves.',
    symptomsHi: 'निचली पत्तियों पर गहरे भूरे छल्ले।',
    culturalStepsEn: ['Prune infected leaves.'],
    culturalStepsHi: ['संक्रमित पत्तियां काटें।'],
    managementCategory: 'fungal',
    severityLevel: 'medium',
    disclaimerEn: 'Consult local agricultural extension officer.',
    disclaimerHi: 'स्थानीय कृषि अधिकारी से संपर्क करें।',
    organicNutritionEn:
        'Apply well-decomposed farmyard manure or vermicompost enriched with neem cake.',
    organicNutritionHi:
        'नीम की खली से समृद्ध सड़ी गोबर की खाद या केंचुआ खाद का प्रयोग करें।',
    fertilizerClassEn:
        'Maintain balanced NPK ratio; supplement with potash (MOP) and micronutrients (Zinc/Boron).',
    fertilizerClassHi:
        'संतुलित NPK अनुपात बनाए रखें; पोटाश (MOP) और सूक्ष्म पोषक तत्वों (जिंक/बोरॉन) का प्रयोग करें।',
    nutritionDisclaimerEn:
        'Fertilizer requirements vary by soil fertility and growth stage. Consult your local KVK.',
    nutritionDisclaimerHi:
        'खाद की आवश्यकता मिट्टी की उर्वरता और फसल की अवस्था पर निर्भर करती है। नजदीकी KVK से संपर्क करें।',
  );

  Widget buildTestableWidget({
    TreatmentModel guidance = sampleGuidance,
    String languageCode = 'en',
    bool initiallyExpanded = true,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(languageCode),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FertilizerNutritionCard(
              guidance: guidance,
              languageCode: languageCode,
              initiallyExpanded: initiallyExpanded,
            ),
          ),
        ),
      ),
    );
  }

  group('FertilizerNutritionCard Widget Tests', () {
    testWidgets('renders all 3 sections in English when expanded', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fertilizer_nutrition_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('fertilizer_nutrition_header')), findsOneWidget);
      expect(find.text('Fertilizer & Nutrition'), findsOneWidget);
      expect(find.byIcon(Icons.spa_rounded), findsOneWidget);

      // Section 1: Bio & Organic Nutrition
      expect(find.byKey(const ValueKey('fertilizer_organic_section')), findsOneWidget);
      expect(find.text('Bio & Organic Boost'), findsOneWidget);
      expect(
        find.text(
          'Apply well-decomposed farmyard manure or vermicompost enriched with neem cake.',
        ),
        findsOneWidget,
      );

      // Section 2: Balanced Nutrients
      expect(find.byKey(const ValueKey('fertilizer_chemical_section')), findsOneWidget);
      expect(find.text('Balanced Nutrients'), findsOneWidget);
      expect(
        find.text(
          'Maintain balanced NPK ratio; supplement with potash (MOP) and micronutrients (Zinc/Boron).',
        ),
        findsOneWidget,
      );

      // Section 3: Regulatory Safety Disclaimer
      expect(find.byKey(const ValueKey('fertilizer_disclaimer_section')), findsOneWidget);
      expect(
        find.text(
          'Fertilizer requirements vary by soil fertility and growth stage. Consult your local KVK.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Always follow package instructions or expert guidance.'),
        findsOneWidget,
      );
    });

    testWidgets('renders properly in Hindi vernacular localization', (tester) async {
      await tester.pumpWidget(buildTestableWidget(languageCode: 'hi'));
      await tester.pumpAndSettle();

      expect(find.text('खाद एवं फसल पोषण'), findsOneWidget);
      expect(find.text('जैविक एवं प्राकृतिक खाद'), findsOneWidget);
      expect(
        find.text('नीम की खली से समृद्ध सड़ी गोबर की खाद या केंचुआ खाद का प्रयोग करें।'),
        findsOneWidget,
      );
      expect(find.text('संतुलित उर्वरक एवं पोषण'), findsOneWidget);
      expect(
        find.text('संतुलित NPK अनुपात बनाए रखें; पोटाश (MOP) और सूक्ष्म पोषक तत्वों (जिंक/बोरॉन) का प्रयोग करें।'),
        findsOneWidget,
      );
      expect(
        find.text('खाद की आवश्यकता मिट्टी की उर्वरता और फसल की अवस्था पर निर्भर करती है। नजदीकी KVK से संपर्क करें।'),
        findsOneWidget,
      );
      expect(
        find.text('हमेशा पैकेट पर लिखे निर्देश या कृषि विशेषज्ञ की सलाह अनुसार ही प्रयोग करें।'),
        findsOneWidget,
      );
    });

    testWidgets('toggling header collapses and expands advisory content', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initiallyExpanded: true));
      await tester.pumpAndSettle();

      // Content is initially visible
      expect(find.byKey(const ValueKey('fertilizer_organic_section')), findsOneWidget);
      expect(find.byKey(const ValueKey('fertilizer_chemical_section')), findsOneWidget);
      expect(find.byKey(const ValueKey('fertilizer_disclaimer_section')), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.byKey(const ValueKey('fertilizer_nutrition_header')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fertilizer_organic_section')), findsNothing);
      expect(find.byKey(const ValueKey('fertilizer_chemical_section')), findsNothing);
      expect(find.byKey(const ValueKey('fertilizer_disclaimer_section')), findsNothing);

      // Tap header again to expand
      await tester.tap(find.byKey(const ValueKey('fertilizer_nutrition_header')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fertilizer_organic_section')), findsOneWidget);
      expect(find.byKey(const ValueKey('fertilizer_chemical_section')), findsOneWidget);
      expect(find.byKey(const ValueKey('fertilizer_disclaimer_section')), findsOneWidget);
    });

    testWidgets('handles empty or fallback guidance values gracefully', (tester) async {
      const fallbackGuidance = TreatmentModel(
        diseaseId: 'unknown_condition',
        crop: 'tomato',
        nameEn: 'General Condition',
        nameHi: 'सामान्य स्थिति',
        symptomsEn: 'None',
        symptomsHi: 'कोई नहीं',
        culturalStepsEn: [],
        culturalStepsHi: [],
        managementCategory: 'general',
        severityLevel: 'low',
        disclaimerEn: 'Disclaimer',
        disclaimerHi: 'अस्वीकरण',
      );

      await tester.pumpWidget(buildTestableWidget(guidance: fallbackGuidance));
      await tester.pumpAndSettle();

      // Renders fallback text without throwing
      expect(find.byKey(const ValueKey('fertilizer_nutrition_card')), findsOneWidget);
      expect(find.textContaining('Apply well-decomposed farmyard manure'), findsOneWidget);
      expect(find.textContaining('balanced NPK'), findsOneWidget);
    });
  });
}
