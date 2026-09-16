import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/widgets/confidence_badge.dart';
import 'package:planten/widgets/scan_history_card.dart';

void main() {
  final sampleScan = DiagnosisResult(
    id: 'scan-001',
    cropId: 'tomato',
    diseaseId: 'tomato_early_blight',
    diseaseNameEn: 'Tomato Early Blight',
    diseaseNameHi: 'टमाटर का अगेती झुलसा',
    confidenceScore: 0.94,
    severity: SeverityLevel.medium,
    timestamp: DateTime.utc(2026, 9, 9, 14, 30, 0),
    localImagePath: '/non/existent/leaf_photo.jpg',
    isSynced: true,
  );

  Widget buildTestable(Widget widget) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: widget),
      ),
    );
  }

  group('ScanHistoryCard Widget (Task 19)', () {
    testWidgets('renders localized disease name and formatted date', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(scan: sampleScan),
        ),
      );

      expect(find.text('Tomato Early Blight'), findsOneWidget);
      expect(find.textContaining('09 Sep 2026'), findsOneWidget);
      expect(find.byType(ConfidenceBadge), findsOneWidget);
      expect(find.text('Likely (94%)'), findsOneWidget);
    });

    testWidgets('supports Hindi localization', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(
            scan: sampleScan,
            languageCode: 'hi',
          ),
        ),
      );

      expect(find.text('टमाटर का अगेती झुलसा'), findsOneWidget);
      expect(find.text('संभावित (94%)'), findsOneWidget);
      expect(find.text('क्लाउड सिंक'), findsOneWidget);
    });

    testWidgets('fires onTap callback when card is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(
            scan: sampleScan,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ScanHistoryCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders fallback thumbnail safely when image file is missing', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(scan: sampleScan),
        ),
      );

      expect(find.byIcon(Icons.spa), findsOneWidget);
    });

    testWidgets('indicates offline status when isSynced is false', (tester) async {
      final offlineScan = sampleScan.copyWith(isSynced: false);

      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(scan: offlineScan),
        ),
      );

      expect(find.byIcon(Icons.cloud_queue), findsOneWidget);
      expect(find.text('Offline only'), findsOneWidget);
    });

    testWidgets('renders delete button when onDelete is provided and fires callback', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(
            scan: sampleScan,
            onDelete: () => deleted = true,
          ),
        ),
      );

      final deleteBtn = find.byKey(ValueKey('delete_scan_${sampleScan.id}'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('omits delete button when onDelete is null', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          ScanHistoryCard(scan: sampleScan),
        ),
      );

      final deleteBtn = find.byKey(ValueKey('delete_scan_${sampleScan.id}'));
      expect(deleteBtn, findsNothing);
    });
  });
}
