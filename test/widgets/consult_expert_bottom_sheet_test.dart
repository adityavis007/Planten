import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/widgets/consult_expert_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleDiagnosis = DiagnosisResult(
    id: 'scan-expert-1',
    cropId: 'tomato',
    diseaseId: 'tomato_early_blight',
    diseaseNameEn: 'Early Blight',
    diseaseNameHi: 'अगेती झुलसा',
    confidenceScore: 0.88,
    severity: SeverityLevel.high,
    timestamp: DateTime(2026, 9, 9, 11, 0),
    localImagePath: 'test/sample.jpg',
  );

  Widget buildTestableBottomSheet({
    DiagnosisResult? result,
    Locale locale = const Locale('en'),
    Future<bool> Function(Uri)? urlLauncherOverride,
    VoidCallback? onShareTap,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                key: const ValueKey('open_sheet_button'),
                onPressed: () {
                  ConsultExpertBottomSheet.show(
                    context,
                    result: result ?? sampleDiagnosis,
                    urlLauncherOverride: urlLauncherOverride,
                    onShareTap: onShareTap,
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('ConsultExpertBottomSheet (Task 45) Unit & Widget Tests', () {
    testWidgets('renders sheet title, Kisan Call Center number, and call button', (tester) async {
      await tester.pumpWidget(buildTestableBottomSheet());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Consult Agriculture Expert'), findsOneWidget);

      // KCC Card
      expect(find.byKey(const ValueKey('kisan_call_center_card')), findsOneWidget);
      expect(find.text('1800-180-1551'), findsOneWidget);
      expect(find.text('TOLL FREE'), findsOneWidget);

      // Call button
      expect(find.byKey(const ValueKey('kcc_call_button')), findsOneWidget);
      expect(find.text('Call Now (1800-180-1551)'), findsOneWidget);
    });

    testWidgets('tapping Call Now triggers dialer with tel:18001801551', (tester) async {
      Uri? launchedUri;

      await tester.pumpWidget(buildTestableBottomSheet(
        urlLauncherOverride: (uri) async {
          launchedUri = uri;
          return true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('kcc_call_button')));
      await tester.pumpAndSettle();

      expect(launchedUri, isNotNull);
      expect(launchedUri.toString(), 'tel:18001801551');
    });

    testWidgets('renders KVK sample preparation guidelines', (tester) async {
      await tester.pumpWidget(buildTestableBottomSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      // KVK Guide Card
      expect(find.byKey(const ValueKey('kvk_sample_guide_card')), findsOneWidget);
      expect(find.text('How to Visit Your Local KVK Officer'), findsOneWidget);
      expect(find.text('Collect Fresh Samples'), findsOneWidget);
      expect(find.text('Use Paper Envelope or Cloth'), findsOneWidget);
      expect(find.text('Note Variety & Field Details'), findsOneWidget);
    });

    testWidgets('renders share diagnosis card and tapping Share invokes callback', (tester) async {
      bool shareTapped = false;

      await tester.pumpWidget(buildTestableBottomSheet(
        onShareTap: () => shareTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('share_diagnosis_card')), findsOneWidget);
      expect(find.text('Share Scan with Extension Worker'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('share_diagnosis_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('share_diagnosis_button')));
      await tester.pumpAndSettle();

      expect(shareTapped, isTrue);
    });

    testWidgets('tapping close button dismisses bottom sheet', (tester) async {
      await tester.pumpWidget(buildTestableBottomSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ConsultExpertBottomSheet), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('close_expert_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ConsultExpertBottomSheet), findsNothing);
    });

    testWidgets('renders Hindi vernacular localization correctly', (tester) async {
      await tester.pumpWidget(buildTestableBottomSheet(
        locale: const Locale('hi'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      // Localized header
      expect(find.text('कृषि अधिकारी से सलाह लें'), findsOneWidget);

      // Localized KCC card
      expect(find.text('किसान कॉल सेंटर (भारत सरकार)'), findsOneWidget);
      expect(find.text('टोल-फ्री'), findsOneWidget);
      expect(find.text('अभी कॉल करें (1800-180-1551)'), findsOneWidget);

      // Localized KVK sample guide
      expect(find.text('नजदीकी कृषि विज्ञान केंद्र (KVK) पर कैसे दिखाएं?'), findsOneWidget);
      expect(find.text('ताजा पत्ती का नमूना लें'), findsOneWidget);
      expect(find.text('कागज के लिफाफे में रखें'), findsOneWidget);
      expect(find.text('बुआई व मौसम की जानकारी'), findsOneWidget);

      // Localized Share card
      expect(find.text('कृषि मित्र से रिपोर्ट साझा करें'), findsOneWidget);
      expect(find.text('साझा करें'), findsOneWidget);
    });
  });
}
