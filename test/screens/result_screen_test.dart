import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/result/result_screen.dart';
import 'package:planten/widgets/consult_expert_bottom_sheet.dart';
import 'package:planten/widgets/treatment_guidance_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;

  // 1x1 transparent PNG memory image for test rendering
  final Uint8List transparentImage = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  final sampleLikelyDiagnosis = DiagnosisResult(
    id: 'scan-101',
    cropId: 'tomato',
    diseaseId: 'tomato_early_blight',
    diseaseNameEn: 'Early Blight',
    diseaseNameHi: 'अगेती झुलसा',
    confidenceScore: 0.92,
    severity: SeverityLevel.medium,
    timestamp: DateTime(2026, 9, 9, 14, 30),
    localImagePath: 'test/sample_leaf.jpg',
    guidance: const TreatmentGuidance(
      diseaseId: 'tomato_early_blight',
      crop: 'tomato',
      nameEn: 'Early Blight',
      nameHi: 'अगेती झुलसा',
      symptomsEn: 'Concentric dark rings and yellow halos on lower leaves.',
      symptomsHi: 'निचली पत्तियों पर गहरे छल्ले और पीले घेरे दिखाई देते हैं।',
      culturalStepsEn: ['Prune infected leaves', 'Ensure soil drainage'],
      culturalStepsHi: ['प्रभावित पत्तियां काटकर हटाएं', 'उचित जल निकासी रखें'],
      managementCategory: 'Fungal Infection',
      severityLevel: 'medium',
      disclaimerEn: 'Consult local agricultural extension.',
      disclaimerHi: 'नजदीकी कृषि विज्ञान केंद्र से संपर्क करें।',
    ),
  );

  final samplePossibleDiagnosis = DiagnosisResult(
    id: 'scan-102',
    cropId: 'wheat',
    diseaseId: 'wheat_rust',
    diseaseNameEn: 'Wheat Rust',
    diseaseNameHi: 'गेहूं का रतुआ',
    confidenceScore: 0.72,
    severity: SeverityLevel.high,
    timestamp: DateTime(2026, 9, 9, 10, 15),
    localImagePath: 'test/sample_wheat.jpg',
    guidance: const TreatmentGuidance(
      diseaseId: 'wheat_rust',
      crop: 'wheat',
      nameEn: 'Wheat Rust',
      nameHi: 'गेहूं का रतुआ',
      symptomsEn: 'Orange-brown powdery pustules on leaf surface.',
      symptomsHi: 'पत्ती की सतह पर नारंगी-भूरे रंग के पाउडर जैसे दाने।',
      culturalStepsEn: ['Avoid excess nitrogen', 'Plant resistant varieties'],
      culturalStepsHi: [
        'अधिक नाइट्रोजन से बचें',
        'प्रतिरोधी किस्मों की बुआई करें',
      ],
      managementCategory: 'Fungal Infection',
      severityLevel: 'high',
      disclaimerEn: 'Consult local agricultural extension.',
      disclaimerHi: 'नजदीकी कृषि विज्ञान केंद्र से संपर्क करें।',
    ),
  );

  final sampleUncertainDiagnosis = DiagnosisResult(
    id: 'scan-103',
    cropId: 'potato',
    diseaseId: 'potato_uncertain',
    diseaseNameEn: 'Uncertain Diagnosis',
    diseaseNameHi: 'निदान अनिश्चित',
    confidenceScore: 0.45,
    severity: SeverityLevel.medium,
    timestamp: DateTime(2026, 9, 9, 12, 00),
    localImagePath: 'test/sample_potato.jpg',
  );

  final sampleHealthyDiagnosis = DiagnosisResult(
    id: 'scan-104',
    cropId: 'cotton',
    diseaseId: 'cotton_healthy',
    diseaseNameEn: 'Healthy Plant',
    diseaseNameHi: 'स्वस्थ पौधा',
    confidenceScore: 0.95,
    severity: SeverityLevel.healthy,
    timestamp: DateTime(2026, 9, 9, 16, 45),
    localImagePath: 'test/sample_cotton.jpg',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    localeProvider = LocaleProvider(prefs: prefs);
  });

  Widget buildTestableResultScreen({
    DiagnosisResult? result,
    Locale locale = const Locale('en'),
    VoidCallback? onConsultExpertTap,
    VoidCallback? onDoneTap,
    VoidCallback? onBackTap,
    VoidCallback? onRetakeTap,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: ResultScreen(
          result: result,
          imageProviderOverride: MemoryImage(transparentImage),
          onConsultExpertTap: onConsultExpertTap,
          onDoneTap: onDoneTap,
          onBackTap: onBackTap,
          onRetakeTap: onRetakeTap,
        ),
      ),
    );
  }

  group('ResultScreen (Task 42) Presentation Tests', () {
    testWidgets('renders leaf photograph, crop badge, and scan timestamp', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableResultScreen(result: sampleLikelyDiagnosis),
      );
      await tester.pumpAndSettle();

      // Leaf Photo
      expect(find.byKey(const ValueKey('result_leaf_image')), findsOneWidget);

      // Crop Badge
      expect(find.byKey(const ValueKey('result_crop_badge')), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);

      // Scan Timestamp
      expect(find.textContaining('09 Sep 2026'), findsOneWidget);
    });

    testWidgets(
      'renders Likely disease state with ConfidenceBadge, SeverityChip, and guidance',
      (tester) async {
        await tester.pumpWidget(
          buildTestableResultScreen(result: sampleLikelyDiagnosis),
        );
        await tester.pumpAndSettle();

        // Condition Title with "Likely" prefix per PRD 7.6
        expect(find.text('Likely Early Blight'), findsOneWidget);

        // Confidence badge (92%)
        expect(
          find.byKey(const ValueKey('result_confidence_badge')),
          findsOneWidget,
        );
        expect(find.text('Likely (92%)'), findsOneWidget);

        // Severity chip
        expect(
          find.byKey(const ValueKey('result_severity_chip')),
          findsOneWidget,
        );
        expect(find.text('Medium Severity'), findsOneWidget);

        // Description / Symptoms from guidance
        expect(
          find.text('Concentric dark rings and yellow halos on lower leaves.'),
          findsOneWidget,
        );

        // Embedded TreatmentGuidanceView (Task 43)
        expect(find.byType(TreatmentGuidanceView), findsOneWidget);
        expect(
          find.byKey(const ValueKey('result_treatment_guidance_view')),
          findsOneWidget,
        );
        expect(find.text('Preventive Actions'), findsOneWidget);

        // Bottom bar
        expect(
          find.byKey(const ValueKey('result_bottom_action_bar')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('done_home_button')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('consult_expert_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders Possible disease state (60-85%) with appropriate badge',
      (tester) async {
        await tester.pumpWidget(
          buildTestableResultScreen(result: samplePossibleDiagnosis),
        );
        await tester.pumpAndSettle();

        // Possible condition title
        expect(find.text('Possible Wheat Rust'), findsOneWidget);

        // Possible confidence badge (72%)
        expect(find.text('Possible (72%)'), findsOneWidget);

        // High severity chip
        expect(find.text('High Severity'), findsOneWidget);

        // High severity warning banner
        expect(
          find.byKey(const ValueKey('high_severity_warning_banner')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders Uncertain Diagnosis state (<60%) with warning banner, checklist, and no disease assertion (Task 44)',
      (tester) async {
        await tester.pumpWidget(
          buildTestableResultScreen(result: sampleUncertainDiagnosis),
        );
        await tester.pumpAndSettle();

        // Condition Title is "Uncertain Diagnosis" without any asserted disease name
        expect(find.text('Uncertain Diagnosis'), findsOneWidget);
        expect(find.text('Uncertain (45%)'), findsOneWidget);

        // Strictly verify no guessed disease names appear
        expect(find.text('Early Blight'), findsNothing);
        expect(find.text('Wheat Rust'), findsNothing);
        expect(find.byType(TreatmentGuidanceView), findsNothing);

        // Warning Card & Banner
        expect(
          find.byKey(const ValueKey('uncertain_warning_banner')),
          findsOneWidget,
        );
        expect(
          find.textContaining('The app is uncertain about this leaf condition'),
          findsOneWidget,
        );

        // Diagnostic Troubleshooting Checklist Card
        expect(
          find.byKey(const ValueKey('uncertain_checklist_card')),
          findsOneWidget,
        );
        expect(find.text('Why might this scan have failed?'), findsOneWidget);
        expect(find.text('Harsh Shadows or Low Light'), findsOneWidget);
        expect(find.text('Distance or Blur'), findsOneWidget);
        expect(find.text('Multiple Leaves in Frame'), findsOneWidget);
        expect(find.text('Early-Stage or Ambiguous Symptoms'), findsOneWidget);

        // SeverityChip is suppressed completely in Uncertain state (Fix 3)
        expect(
          find.byKey(const ValueKey('result_severity_chip')),
          findsNothing,
        );

        // In-card duplicate action buttons are removed (Fix 3), only sticky bottom bar remains
        expect(
          find.byKey(const ValueKey('uncertain_card_retake_button')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('uncertain_card_consult_button')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('retake_photo_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('consult_expert_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping retake button in uncertain state triggers onRetakeTap (Task 44 & Fix 3)',
      (tester) async {
        bool retakeTapped = false;
        await tester.pumpWidget(
          buildTestableResultScreen(
            result: sampleUncertainDiagnosis,
            onRetakeTap: () => retakeTapped = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('retake_photo_button')));
        await tester.pumpAndSettle();

        expect(retakeTapped, isTrue);
      },
    );

    testWidgets(
      'renders Hindi localization for Uncertain state and Checklist (Task 44)',
      (tester) async {
        await tester.pumpWidget(
          buildTestableResultScreen(
            result: sampleUncertainDiagnosis,
            locale: const Locale('hi'),
          ),
        );
        await tester.pumpAndSettle();

        // Hindi Condition Title
        expect(
          find.text('निदान अनिश्चित — कृषि विशेषज्ञ से संपर्क करें'),
          findsOneWidget,
        );

        // Hindi subtitle
        expect(
          find.text('रोग की पुष्टि नहीं हो सकी — कोई दवा न डालें'),
          findsOneWidget,
        );

        // Hindi checklist
        expect(
          find.text('फोटो स्पष्ट क्यों नहीं आई? (जांच सूची)'),
          findsOneWidget,
        );
        expect(find.text('छाया व रोशनी की कमी'), findsOneWidget);
        expect(find.text('दूरी व कैमरा फोकस'), findsOneWidget);
        expect(find.text('फ्रेम में एक से अधिक पत्तियां'), findsOneWidget);
        expect(find.text('शुरुआती या अस्पष्ट लक्षण'), findsOneWidget);

        // Hindi sticky bar buttons
        expect(
          find.text('साफ़ फोटो दोबारा लें'),
          findsOneWidget,
        ); // sticky bar only
        expect(find.text('कृषि केंद्र'), findsOneWidget); // sticky bar
      },
    );

    testWidgets('renders Healthy Plant state with reassurance banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableResultScreen(result: sampleHealthyDiagnosis),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Healthy Plant'), findsOneWidget);

      // Severity is Healthy
      expect(find.text('Healthy'), findsOneWidget);

      // Reassurance banner
      expect(
        find.byKey(const ValueKey('healthy_reassurance_banner')),
        findsOneWidget,
      );

      // Description
      expect(
        find.text(
          'No visible signs of disease, pest damage, or nutrient deficiency detected.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Hindi vernacular localization correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableResultScreen(
          result: sampleLikelyDiagnosis,
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      // Localized screen title in app bar
      expect(find.text('जांच परिणाम'), findsOneWidget);

      // Localized crop name
      expect(find.text('टमाटर'), findsOneWidget);

      // Localized disease title
      expect(find.text('संभावित रोग: अगेती झुलसा'), findsOneWidget);

      // Localized symptoms
      expect(
        find.text('निचली पत्तियों पर गहरे छल्ले और पीले घेरे दिखाई देते हैं।'),
        findsOneWidget,
      );

      // Localized section title
      expect(find.text('लक्षण व स्थिति'), findsOneWidget);
    });

    testWidgets('fires onDoneTap when Back to Home button is tapped', (
      tester,
    ) async {
      bool doneTapped = false;
      await tester.pumpWidget(
        buildTestableResultScreen(
          result: sampleLikelyDiagnosis,
          onDoneTap: () => doneTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('done_home_button')));
      await tester.pumpAndSettle();

      expect(doneTapped, isTrue);
    });

    testWidgets(
      'fires onConsultExpertTap when consult expert button is tapped',
      (tester) async {
        bool consultTapped = false;
        await tester.pumpWidget(
          buildTestableResultScreen(
            result: sampleUncertainDiagnosis,
            onConsultExpertTap: () => consultTapped = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('consult_expert_button')));
        await tester.pumpAndSettle();

        expect(consultTapped, isTrue);
      },
    );

    testWidgets(
      'shows ConsultExpertBottomSheet when consult expert is tapped without callback override (Task 45)',
      (tester) async {
        await tester.pumpWidget(
          buildTestableResultScreen(result: sampleLikelyDiagnosis),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('consult_expert_button')));
        await tester.pumpAndSettle();

        // Bottom sheet should open
        expect(find.byType(ConsultExpertBottomSheet), findsOneWidget);
        expect(find.byKey(const ValueKey('kcc_number_text')), findsOneWidget);
        expect(find.byKey(const ValueKey('kcc_call_button')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('kvk_sample_guide_card')),
          findsOneWidget,
        );

        // Tap Close
        await tester.tap(
          find.byKey(const ValueKey('close_expert_sheet_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ConsultExpertBottomSheet), findsNothing);
      },
    );

    testWidgets('fires onBackTap when back button in app bar is tapped', (
      tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        buildTestableResultScreen(
          result: sampleLikelyDiagnosis,
          onBackTap: () => backTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('result_back_button')));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });

    testWidgets('renders empty state gracefully when result is null', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableResultScreen(result: null));
      await tester.pumpAndSettle();

      expect(find.text('No Diagnosis Available'), findsOneWidget);
      expect(
        find.text('Please scan a crop leaf to view diagnosis details.'),
        findsOneWidget,
      );
      expect(find.text('Scan Leaf for Disease'), findsOneWidget);
    });

    testWidgets(
      'renders Fertilizer & Crop Nutrition advisory card when guidance contains nutrition data',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final diagnosisWithNutrition = DiagnosisResult(
          id: 'scan-with-nutrition',
          cropId: 'tomato',
          diseaseId: 'tomato_early_blight',
          diseaseNameEn: 'Early Blight',
          diseaseNameHi: 'अगेती झुलसा',
          confidenceScore: 0.94,
          severity: SeverityLevel.medium,
          timestamp: DateTime(2026, 9, 9, 14, 30),
          localImagePath: 'test/sample_leaf.jpg',
          guidance: const TreatmentGuidance(
            diseaseId: 'tomato_early_blight',
            crop: 'tomato',
            nameEn: 'Early Blight',
            nameHi: 'अगेती झुलसा',
            symptomsEn: 'Concentric dark rings.',
            symptomsHi: 'गहरे छल्ले।',
            culturalStepsEn: ['Prune leaves'],
            culturalStepsHi: ['पत्तियां हटाएं'],
            managementCategory: 'Fungal Infection',
            severityLevel: 'medium',
            disclaimerEn: 'Consult KVK.',
            disclaimerHi: 'KVK से संपर्क करें।',
            organicNutritionEn: 'Apply neem cake and vermicompost.',
            organicNutritionHi: 'नीम खली और वर्मीकम्पोस्ट डालें।',
            fertilizerClassEn: 'Balanced NPK and Potash (MOP).',
            fertilizerClassHi: 'संतुलित NPK और पोटाश डालें।',
            nutritionDisclaimerEn: 'Check local soil test.',
            nutritionDisclaimerHi: 'मिट्टी की जांच करें।',
          ),
        );

        await tester.pumpWidget(
          buildTestableResultScreen(result: diagnosisWithNutrition),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('result_fertilizer_nutrition_card')),
          findsOneWidget,
        );
        expect(find.text('Fertilizer & Nutrition'), findsOneWidget);
        expect(find.text('Apply neem cake and vermicompost.'), findsOneWidget);
        expect(find.text('Balanced NPK and Potash (MOP).'), findsOneWidget);
      },
    );
  });

  group('ResultScreen GoRouter Navigation Integration', () {
    testWidgets(
      'navigating to AppRoutes.result renders ResultScreen with extra data',
      (tester) async {
        final testRouter = GoRouter(
          initialLocation: AppRoutes.result,
          routes: [
            GoRoute(
              path: AppRoutes.result,
              builder: (context, state) {
                final scan =
                    state.extra as DiagnosisResult? ?? sampleLikelyDiagnosis;
                return ResultScreen(
                  result: scan,
                  imageProviderOverride: MemoryImage(transparentImage),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<LocaleProvider>.value(
                value: localeProvider,
              ),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: testRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResultScreen), findsOneWidget);
        expect(find.text('Likely Early Blight'), findsOneWidget);
      },
    );
  });
}
