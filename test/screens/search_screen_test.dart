import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/models/treatment_guidance.dart';
import 'package:planten/screens/search/search_screen.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/knowledge_base_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorageService localStorageService;
  late HistoryService historyService;
  late KnowledgeBaseService knowledgeBaseService;

  final sampleScans = [
    DiagnosisResult(
      id: 'scan-s1',
      cropId: 'tomato',
      diseaseId: 'tomato_early_blight',
      diseaseNameEn: 'Early Blight',
      diseaseNameHi: 'अगेती झुलसा',
      confidenceScore: 0.91,
      severity: SeverityLevel.medium,
      timestamp: DateTime(2026, 9, 8, 11, 0),
      localImagePath: '',
    ),
    DiagnosisResult(
      id: 'scan-s2',
      cropId: 'wheat',
      diseaseId: 'wheat_rust',
      diseaseNameEn: 'Wheat Rust',
      diseaseNameHi: 'गेहूं का रतुआ',
      confidenceScore: 0.88,
      severity: SeverityLevel.high,
      timestamp: DateTime(2026, 9, 9, 14, 0),
      localImagePath: '',
    ),
  ];

  final sampleGuidanceList = [
    const TreatmentGuidance(
      diseaseId: 'tomato_early_blight',
      crop: 'tomato',
      nameEn: 'Early Blight',
      nameHi: 'अगेती झुलसा',
      symptomsEn: 'Dark concentric target-like rings on lower foliage.',
      symptomsHi: 'निचली पत्तियों पर गहरे छल्ले।',
      culturalStepsEn: ['Prune diseased leaves', 'Stake plants for airflow'],
      culturalStepsHi: ['रोगग्रस्त पत्तियों को हटाएं', 'हवादार दूरी रखें'],
      managementCategory: 'Fungal',
      severityLevel: 'medium',
      disclaimerEn: 'Consult local expert.',
      disclaimerHi: 'कृषि विशेषज्ञ से सलाह लें।',
    ),
    const TreatmentGuidance(
      diseaseId: 'potato_late_blight',
      crop: 'potato',
      nameEn: 'Late Blight',
      nameHi: 'पछेती झुलसा',
      symptomsEn: 'Water-soaked lesions on leaf tips turning black.',
      symptomsHi: 'पत्तियों पर गीले काले धब्बे।',
      culturalStepsEn: ['Destroy infected debris', 'Avoid overhead irrigation'],
      culturalStepsHi: ['प्रभावित अवशेष नष्ट करें', 'ऊपर से पानी न दें'],
      managementCategory: 'Oomycete',
      severityLevel: 'high',
      disclaimerEn: 'Consult local expert.',
      disclaimerHi: 'कृषि विशेषज्ञ से सलाह लें।',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorageService = LocalStorageService(prefs: prefs);
    await localStorageService.init();

    historyService = HistoryService(localStorageService: localStorageService);
    for (final scan in sampleScans) {
      await historyService.saveScan(scan);
    }

    knowledgeBaseService = KnowledgeBaseService(
      initialGuidance: sampleGuidanceList,
    );
  });

  Widget buildTestableSearchScreen({Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: SearchScreen(
        historyService: historyService,
        knowledgeBaseService: knowledgeBaseService,
      ),
    );
  }

  group('SearchScreen Dual-Source Search (Fix 1 & Task 22b)', () {
    testWidgets('renders initial empty state with popular search chips', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableSearchScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_input_field')), findsOneWidget);
      expect(find.text('Search Crop Doctor'), findsOneWidget);
      expect(find.text('Popular Searches'), findsOneWidget);
      expect(find.text('Early Blight'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Wheat Rust'), findsOneWidget);
    });

    testWidgets(
      'tapping a suggestion chip populates search field and displays results',
      (tester) async {
        await tester.pumpWidget(buildTestableSearchScreen());
        await tester.pumpAndSettle();

        // Tap suggestion chip "Early Blight"
        await tester.tap(find.text('Early Blight'));
        await tester.pumpAndSettle();

        // Verify input updated
        final textField = tester.widget<TextField>(
          find.byKey(const ValueKey('search_input_field')),
        );
        expect(textField.controller?.text, 'Early Blight');

        // Verify sections appear
        expect(find.textContaining('Past Scan History (1)'), findsOneWidget);
        expect(
          find.textContaining('Crop Knowledge & Care (1)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(Card, 'Early Blight'),
          findsNWidgets(2),
        ); // Scan card + guidance card
        expect(
          find.text('Early Blight'),
          findsNWidgets(3),
        ); // TextField + 2 cards
      },
    );

    testWidgets(
      'typing search query returns matching scan history and knowledge base entries',
      (tester) async {
        await tester.pumpWidget(buildTestableSearchScreen());
        await tester.pumpAndSettle();

        // Enter search text "Wheat"
        await tester.enterText(
          find.byKey(const ValueKey('search_input_field')),
          'Wheat',
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Past Scan History (1)'), findsOneWidget);
        expect(find.text('Wheat Rust'), findsOneWidget);
      },
    );

    testWidgets('shows No matching results state when query has no matches', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableSearchScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('search_input_field')),
        'NonExistentDisease',
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching results found'), findsOneWidget);
    });

    testWidgets('clear button clears query and restores empty state', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableSearchScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('search_input_field')),
        'Tomato',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_clear_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('search_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('Search Crop Doctor'), findsOneWidget);
      expect(find.byKey(const ValueKey('search_clear_button')), findsNothing);
    });

    testWidgets('renders Hindi localization properly', (tester) async {
      await tester.pumpWidget(
        buildTestableSearchScreen(locale: const Locale('hi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('खोजें'), findsOneWidget);
      expect(find.text('फसल डॉक्टर में खोजें'), findsOneWidget);
      expect(find.text('लोकप्रिय खोजें'), findsOneWidget);
      expect(find.text('अगेती झुलसा'), findsOneWidget);
    });

    testWidgets('renders back button in AppBar and responds to tap', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableSearchScreen());
      await tester.pumpAndSettle();

      final backButtonFinder = find.byKey(const ValueKey('search_back_button'));
      expect(backButtonFinder, findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();
    });
  });
}
