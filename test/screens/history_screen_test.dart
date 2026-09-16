import 'dart:io';
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
import 'package:planten/providers/history_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/history/history_screen.dart';
import 'package:planten/services/history_service.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/widgets/scan_history_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docsDir;
  late LocalStorageService localStorageService;
  late HistoryService historyService;
  late HistoryProvider historyProvider;
  late LocaleProvider localeProvider;

  DiagnosisResult buildSampleScan({
    required String id,
    String cropId = 'tomato',
    String diseaseId = 'tomato_early_blight',
    String diseaseNameEn = 'Tomato Early Blight',
    String diseaseNameHi = 'टमाटर का अगेती झुलसा',
    double confidenceScore = 0.92,
    SeverityLevel severity = SeverityLevel.medium,
    DateTime? timestamp,
    String localImagePath = '',
    bool isSynced = false,
  }) {
    return DiagnosisResult(
      id: id,
      cropId: cropId,
      diseaseId: diseaseId,
      diseaseNameEn: diseaseNameEn,
      diseaseNameHi: diseaseNameHi,
      confidenceScore: confidenceScore,
      severity: severity,
      timestamp: timestamp ?? DateTime.now(),
      localImagePath: localImagePath,
      isSynced: isSynced,
      guidance: const TreatmentGuidance(
        diseaseId: 'tomato_early_blight',
        crop: 'tomato',
        nameEn: 'Tomato Early Blight',
        nameHi: 'टमाटर का अगेती झुलसा',
        symptomsEn: 'Dark concentric spots.',
        symptomsHi: 'काले छल्लेदार धब्बे।',
        culturalStepsEn: ['Prune lower leaves.'],
        culturalStepsHi: ['निचली पत्तियों को हटाएं।'],
        managementCategory: 'cultural',
        severityLevel: 'medium',
        disclaimerEn: 'Advisory only.',
        disclaimerHi: 'केवल सलाह हेतु।',
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorageService = LocalStorageService(prefs: prefs);

    tempDir = await Directory.systemTemp.createTemp('planten_hist_screen_test_');
    docsDir = Directory('${tempDir.path}/app_docs');
    await docsDir.create(recursive: true);

    historyService = HistoryService(
      localStorageService: localStorageService,
      documentsDirectoryProvider: () async => docsDir,
    );

    historyProvider = HistoryProvider(
      historyService: historyService,
      autoLoad: false,
    );

    localeProvider = LocaleProvider(prefs: prefs);
  });

  tearDown(() async {
    historyProvider.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestableHistoryScreen({
    HistoryProvider? provider,
    void Function(DiagnosisResult scan)? onScanTap,
    VoidCallback? onScanCtaTap,
    Locale locale = const Locale('en'),
  }) {
    final activeProvider = provider ?? historyProvider;
    localeProvider.setLocale(locale);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HistoryProvider>.value(value: activeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HistoryScreen(
          historyProviderOverride: activeProvider,
          onScanTap: onScanTap,
          onScanCtaTap: onScanCtaTap,
        ),
      ),
    );
  }

  group('HistoryScreen (Task 48) Presentation & Interaction Tests', () {
    testWidgets('renders screen title, crop filter chips, and empty state when no scans exist', (tester) async {
      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      // App Bar Title
      expect(find.text('Scan History'), findsOneWidget);

      // Filter Chips
      expect(find.byKey(const ValueKey('crop_filter_all')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_filter_tomato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_filter_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_filter_potato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_filter_chili')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_filter_cotton')), findsOneWidget);

      // Empty State
      expect(find.byKey(const ValueKey('empty_history_icon')), findsOneWidget);
      expect(find.text('No Scan History Yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('empty_state_scan_button')), findsOneWidget);
      expect(find.text('Scan Leaf for Disease'), findsOneWidget);
    });

    testWidgets('tapping empty state CTA invokes onScanCtaTap', (tester) async {
      bool scanCtaTapped = false;
      await tester.pumpWidget(buildTestableHistoryScreen(
        onScanCtaTap: () => scanCtaTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('empty_state_scan_button')));
      await tester.pumpAndSettle();

      expect(scanCtaTapped, isTrue);
    });

    testWidgets('renders scans grouped by date headers (Today, Yesterday)', (tester) async {
      final now = DateTime.now();
      final todayScan = buildSampleScan(
        id: 'scan-today-1',
        cropId: 'tomato',
        diseaseNameEn: 'Tomato Early Blight',
        timestamp: now,
      );
      final yesterdayScan = buildSampleScan(
        id: 'scan-yesterday-1',
        cropId: 'wheat',
        diseaseNameEn: 'Wheat Yellow Rust',
        timestamp: now.subtract(const Duration(days: 1)),
      );

      await historyService.saveScan(todayScan);
      await historyService.saveScan(yesterdayScan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      // Date Headers
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);

      // Scan Cards
      expect(find.byType(ScanHistoryCard), findsNWidgets(2));
      expect(find.text('Tomato Early Blight'), findsOneWidget);
      expect(find.text('Wheat Yellow Rust'), findsOneWidget);
    });

    testWidgets('filtering by crop updates visible cards and empty message', (tester) async {
      final now = DateTime.now();
      final tomatoScan = buildSampleScan(
        id: 'scan-tomato',
        cropId: 'tomato',
        diseaseNameEn: 'Tomato Early Blight',
        timestamp: now,
      );
      final wheatScan = buildSampleScan(
        id: 'scan-wheat',
        cropId: 'wheat',
        diseaseNameEn: 'Wheat Yellow Rust',
        timestamp: now,
      );

      await historyService.saveScan(tomatoScan);
      await historyService.saveScan(wheatScan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      // Initially both show
      expect(find.byType(ScanHistoryCard), findsNWidgets(2));

      // Filter by Tomato
      await tester.tap(find.byKey(const ValueKey('crop_filter_tomato')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanHistoryCard), findsOneWidget);
      expect(find.text('Tomato Early Blight'), findsOneWidget);
      expect(find.text('Wheat Yellow Rust'), findsNothing);

      // Filter by Chili (0 scans) -> shows specific crop empty state
      await tester.tap(find.byKey(const ValueKey('crop_filter_chili')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanHistoryCard), findsNothing);
      expect(find.text('No scans recorded yet for Chili.'), findsOneWidget);

      // Reset to All Crops
      await tester.tap(find.byKey(const ValueKey('crop_filter_all')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanHistoryCard), findsNWidgets(2));
    });

    testWidgets('tapping ScanHistoryCard triggers onScanTap with selected diagnosis', (tester) async {
      final scan = buildSampleScan(
        id: 'review-target-scan',
        cropId: 'tomato',
        diseaseNameEn: 'Tomato Early Blight',
      );
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      DiagnosisResult? tappedScan;
      await tester.pumpWidget(buildTestableHistoryScreen(
        onScanTap: (result) => tappedScan = result,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ScanHistoryCard));
      await tester.pumpAndSettle();

      expect(tappedScan, isNotNull);
      expect(tappedScan?.id, 'review-target-scan');
      expect(tappedScan?.diseaseNameEn, 'Tomato Early Blight');
    });

    testWidgets('displays unsynced scans badge in app bar when pending sync', (tester) async {
      final scan = buildSampleScan(
        id: 'unsynced-scan',
        isSynced: false,
      );
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('unsynced_scans_badge')), findsOneWidget);
      expect(find.textContaining('1 pending'), findsOneWidget);
    });

    testWidgets('renders Hindi vernacular localization correctly', (tester) async {
      final now = DateTime.now();
      final scan = buildSampleScan(
        id: 'hindi-scan',
        cropId: 'tomato',
        diseaseNameHi: 'टमाटर का अगेती झुलसा',
        timestamp: now,
      );
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen(
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      // App bar title in Hindi
      expect(find.text('जांच इतिहास'), findsOneWidget);

      // Filter chip in Hindi
      expect(find.text('सभी फसलें'), findsOneWidget);
      expect(find.text('टमाटर'), findsOneWidget);

      // Today date group in Hindi
      expect(find.text('आज'), findsOneWidget);

      // Disease name in Hindi
      expect(find.text('टमाटर का अगेती झुलसा'), findsOneWidget);
    });

    testWidgets('tapping delete button displays confirmation dialog and cancelling preserves item', (tester) async {
      final scan = buildSampleScan(id: 'delete-target-1');
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const ValueKey('delete_scan_delete-target-1'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Scan'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this scan record?'), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.byKey(const ValueKey('cancel_delete_scan_button')));
      await tester.pumpAndSettle();

      // Card is still present
      expect(find.byType(ScanHistoryCard), findsOneWidget);
    });

    testWidgets('confirming delete removes scan and displays success SnackBar', (tester) async {
      final scan = buildSampleScan(id: 'delete-target-2');
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_scan_delete-target-2')));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.byKey(const ValueKey('confirm_delete_scan_button')));
      await tester.pumpAndSettle();

      // Card is removed
      expect(find.byType(ScanHistoryCard), findsNothing);
      expect(find.text('Scan deleted successfully'), findsOneWidget);
      expect(find.text('No Scan History Yet'), findsOneWidget);
    });

    testWidgets('swiping Dismissible card horizontally prompts confirmation dialog and deletes item', (tester) async {
      final scan = buildSampleScan(id: 'swipe-target');
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      final dismissibleFinder = find.byKey(const ValueKey('dismissible_scan_swipe-target'));
      expect(dismissibleFinder, findsOneWidget);

      // Drag card to the left to dismiss
      await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Scan'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.byKey(const ValueKey('confirm_delete_scan_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanHistoryCard), findsNothing);
      expect(find.text('Scan deleted successfully'), findsOneWidget);
    });

    testWidgets('clear all history button in AppBar confirms and clears all scans into empty state', (tester) async {
      final scan1 = buildSampleScan(id: 'batch-1');
      final scan2 = buildSampleScan(id: 'batch-2');
      await historyService.saveScan(scan1);
      await historyService.saveScan(scan2);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen());
      await tester.pumpAndSettle();

      expect(find.byType(ScanHistoryCard), findsNWidgets(2));

      final clearAllBtn = find.byKey(const ValueKey('clear_all_history_button'));
      expect(clearAllBtn, findsOneWidget);

      // Tap clear all
      await tester.tap(clearAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Clear All History'), findsNWidgets(2)); // Title and confirm button
      expect(find.text('Are you sure you want to delete all scan history? This action cannot be undone.'), findsOneWidget);

      // Cancel first
      await tester.tap(find.byKey(const ValueKey('cancel_clear_all_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanHistoryCard), findsNWidgets(2));

      // Re-trigger and confirm
      await tester.tap(clearAllBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirm_clear_all_button')));
      await tester.pumpAndSettle();

      // Empty state should be visible
      expect(find.byType(ScanHistoryCard), findsNothing);
      expect(find.text('No Scan History Yet'), findsOneWidget);
      expect(find.text('All scan history cleared'), findsOneWidget);
    });

    testWidgets('renders localized Hindi delete confirmation and clear all dialogs', (tester) async {
      final scan = buildSampleScan(id: 'hindi-delete-scan');
      await historyService.saveScan(scan);
      await historyProvider.loadHistory();

      await tester.pumpWidget(buildTestableHistoryScreen(
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byKey(const ValueKey('delete_scan_hindi-delete-scan')));
      await tester.pumpAndSettle();

      expect(find.text('स्कैन हटाएं'), findsOneWidget);
      expect(find.text('क्या आप वाकई इस स्कैन रिकॉर्ड को हटाना चाहते हैं?'), findsOneWidget);
      expect(find.text('रद्द करें'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cancel_delete_scan_button')));
      await tester.pumpAndSettle();

      // Tap clear all
      await tester.tap(find.byKey(const ValueKey('clear_all_history_button')));
      await tester.pumpAndSettle();

      expect(find.text('सारा इतिहास हटाएं'), findsNWidgets(2));
      expect(find.text('क्या आप वाकई सभी स्कैन रिकॉर्ड हटाना चाहते हैं? यह क्रिया वापस नहीं ली जा सकती।'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cancel_clear_all_button')));
      await tester.pumpAndSettle();
    });
  });

  group('HistoryScreen GoRouter Navigation Integration', () {
    testWidgets('navigating to AppRoutes.history renders HistoryScreen within router', (tester) async {
      final testRouter = GoRouter(
        initialLocation: AppRoutes.history,
        routes: [
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => HistoryScreen(
              historyProviderOverride: historyProvider,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
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

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('Scan History'), findsOneWidget);
    });
  });
}
