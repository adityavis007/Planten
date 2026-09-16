import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/widgets/treatment_guidance_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleGuidance = TreatmentGuidance(
    diseaseId: 'tomato_early_blight',
    crop: 'tomato',
    nameEn: 'Early Blight',
    nameHi: 'अगेती झुलसा',
    symptomsEn: 'Concentric dark brown rings with yellow chlorotic halos on lower leaves.',
    symptomsHi: 'निचली पत्तियों पर गहरे भूरे रंग के गोल छल्ले और पीलापन दिखाई देता है।',
    culturalStepsEn: [
      'Prune and destroy infected lower leaves immediately.',
      'Ensure proper plant spacing (45-60cm) to promote good air circulation.',
      'Water at the base of the plant using drip irrigation; avoid overhead sprinkling.',
      'Apply organic mulch to prevent soil splashing onto foliage.',
    ],
    culturalStepsHi: [
      'संक्रमित निचली पत्तियों को तुरंत काटकर नष्ट करें।',
      'हवा के संचार के लिए पौधों के बीच 45-60 सेमी की उचित दूरी रखें।',
      'ड्रिप विधि से केवल जड़ों में पानी दें; ऊपर से पत्तियों पर पानी न छिड़कें।',
      'मिट्टी के छीटों को रोकने के लिए पुआल की मल्चिंग करें।',
    ],
    managementCategory: 'Fungal Infection',
    severityLevel: 'medium',
    disclaimerEn:
        'Planten provides verified cultural management steps and does not prescribe chemical dosages. Consult your local Krishi Vigyan Kendra (KVK) or agriculture officer before applying any fungicide.',
    disclaimerHi:
        'प्लांटन केवल वैज्ञानिक व देशी रोकथाम के उपाय सुझाता है और रासायनिक दवाओं की मात्रा नहीं बताता। कोई भी कीटनाशक डालने से पहले नजदीकी कृषि विज्ञान केंद्र (KVK) से सलाह लें।',
  );

  Widget buildTestableWidget({
    TreatmentGuidance guidance = sampleGuidance,
    String languageCode = 'en',
    bool initialExpandSymptoms = false,
    bool initialExpandPrevention = true,
    bool initialExpandSafety = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TreatmentGuidanceView(
              guidance: guidance,
              languageCode: languageCode,
              initialExpandSymptoms: initialExpandSymptoms,
              initialExpandPrevention: initialExpandPrevention,
              initialExpandSafety: initialExpandSafety,
            ),
          ),
        ),
      ),
    );
  }

  group('TreatmentGuidanceView (Task 43) Unit & Widget Tests', () {
    testWidgets('renders header title and management category badge', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Management Guidance'), findsOneWidget);
      expect(find.byKey(const ValueKey('management_category_badge')), findsOneWidget);
      expect(find.text('Fungal Infection'), findsOneWidget);
    });

    testWidgets('renders all 3 accordion section headers', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.text('Preventive Actions'), findsOneWidget);
      expect(find.text('Important Safety Advice'), findsOneWidget);
    });

    testWidgets('Preventive Actions is expanded by default with numbered steps', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Prevention content is visible
      expect(find.byKey(const ValueKey('guidance_prevention_content')), findsOneWidget);
      expect(
        find.text('Prune and destroy infected lower leaves immediately.'),
        findsOneWidget,
      );
      expect(
        find.text('Ensure proper plant spacing (45-60cm) to promote good air circulation.'),
        findsOneWidget,
      );

      // Numbered step badges (1, 2, 3, 4)
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('toggling Symptoms accordion expands and collapses content', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialExpandSymptoms: false));
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.byKey(const ValueKey('guidance_symptoms_content')), findsNothing);

      // Tap header to expand
      await tester.tap(find.byKey(const ValueKey('accordion_symptoms_header')));
      await tester.pumpAndSettle();

      // Now visible
      expect(find.byKey(const ValueKey('guidance_symptoms_content')), findsOneWidget);
      expect(
        find.text('Concentric dark brown rings with yellow chlorotic halos on lower leaves.'),
        findsOneWidget,
      );

      // Tap header again to collapse
      await tester.tap(find.byKey(const ValueKey('accordion_symptoms_header')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guidance_symptoms_content')), findsNothing);
    });

    testWidgets('toggling Safety Advice accordion expands and verifies no chemical dosages', (tester) async {
      await tester.pumpWidget(buildTestableWidget(initialExpandSafety: false));
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.byKey(const ValueKey('guidance_safety_content')), findsNothing);

      // Tap header to expand
      await tester.tap(find.byKey(const ValueKey('accordion_safety_header')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guidance_safety_content')), findsOneWidget);
      expect(find.text('Avoid Unauthorized Chemical Spraying'), findsOneWidget);
      expect(
        find.textContaining('Planten provides verified cultural management steps and does not prescribe chemical dosages'),
        findsOneWidget,
      );
    });

    testWidgets('renders certified ICAR & Krishi Vigyan Kendra (KVK) attribution footer', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('icar_kvk_attribution')), findsOneWidget);
      expect(
        find.text('Source: Verified by ICAR & Krishi Vigyan Kendra (KVK) Advisory'),
        findsOneWidget,
      );
    });

    testWidgets('renders Hindi vernacular localization correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        languageCode: 'hi',
        initialExpandSymptoms: true,
        initialExpandPrevention: true,
        initialExpandSafety: true,
      ));
      await tester.pumpAndSettle();

      // Localized header
      expect(find.text('रोकथाम व प्रबंधन'), findsOneWidget);

      // Localized accordion titles
      expect(find.text('लक्षण'), findsOneWidget);
      expect(find.text('रोकथाम के उपाय'), findsOneWidget);
      expect(find.text('महत्वपूर्ण सूचना व सलाह'), findsOneWidget);

      // Localized symptoms
      expect(
        find.text('निचली पत्तियों पर गहरे भूरे रंग के गोल छल्ले और पीलापन दिखाई देता है।'),
        findsOneWidget,
      );

      // Localized cultural step
      expect(
        find.text('संक्रमित निचली पत्तियों को तुरंत काटकर नष्ट करें।'),
        findsOneWidget,
      );

      // Localized safety warning
      expect(find.text('रासायनिक दवाओं का अंधाधुंध छिड़काव न करें'), findsOneWidget);

      // Localized attribution footer
      expect(
        find.text('स्रोत: आईसीएआर (ICAR) एवं कृषि विज्ञान केंद्र (KVK) द्वारा प्रमाणित सलाह'),
        findsOneWidget,
      );
    });

    testWidgets('handles empty cultural steps gracefully', (tester) async {
      const guidanceWithoutSteps = TreatmentGuidance(
        diseaseId: 'wheat_leaf_spot',
        crop: 'wheat',
        nameEn: 'Leaf Spot',
        nameHi: 'पत्ती धब्बा',
        symptomsEn: 'Brown spots.',
        symptomsHi: 'भूरे धब्बे।',
        culturalStepsEn: [],
        culturalStepsHi: [],
        managementCategory: 'Fungal',
        severityLevel: 'low',
        disclaimerEn: 'Consult extension.',
        disclaimerHi: 'सलाह लें।',
      );

      await tester.pumpWidget(buildTestableWidget(
        guidance: guidanceWithoutSteps,
        initialExpandPrevention: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No specific cultural steps available.'), findsOneWidget);
    });
  });
}
