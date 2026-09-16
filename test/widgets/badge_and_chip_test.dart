import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/models/confidence_category.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/widgets/confidence_badge.dart';
import 'package:planten/widgets/severity_chip.dart';

void main() {
  Widget buildTestable(Widget widget) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: widget),
      ),
    );
  }

  group('ConfidenceBadge (Task 17)', () {
    testWidgets('maps >85% score to Likely tier with check icon and percentage', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ConfidenceBadge(
            score: 0.92,
            showPercentage: true,
          ),
        ),
      );

      expect(find.text('Likely (92%)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('maps 60-85% score to Possible tier with info icon', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ConfidenceBadge(
            score: 0.74,
            showPercentage: true,
          ),
        ),
      );

      expect(find.text('Possible (74%)'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('maps <60% score to Uncertain tier with warning icon', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ConfidenceBadge(
            score: 0.45,
            showPercentage: false,
          ),
        ),
      );

      expect(find.text('Uncertain'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('supports Hindi localization', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ConfidenceBadge(
            score: 0.95,
            languageCode: 'hi',
            showPercentage: true,
          ),
        ),
      );

      expect(find.text('संभावित (95%)'), findsOneWidget);
    });

    testWidgets('supports category constructor and compact mode', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ConfidenceBadge.fromCategory(
            category: ConfidenceCategory.possible,
            isCompact: true,
          ),
        ),
      );

      expect(find.text('Possible'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('SeverityChip (Task 17)', () {
    testWidgets('renders all 4 severity levels with icons and labels', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const Column(
            children: [
              SeverityChip(severity: SeverityLevel.healthy),
              SeverityChip(severity: SeverityLevel.low),
              SeverityChip(severity: SeverityLevel.medium),
              SeverityChip(severity: SeverityLevel.high),
            ],
          ),
        ),
      );

      expect(find.text('Healthy'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);

      expect(find.text('Low Severity'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      expect(find.text('Medium Severity'), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);

      expect(find.text('High Severity'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('supports Hindi localization for severity levels', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const Column(
            children: [
              SeverityChip(severity: SeverityLevel.healthy, languageCode: 'hi'),
              SeverityChip(severity: SeverityLevel.high, languageCode: 'hi'),
            ],
          ),
        ),
      );

      expect(find.text('स्वस्थ'), findsOneWidget);
      expect(find.text('गंभीर प्रकोप'), findsOneWidget);
    });

    testWidgets('supports isSolid and isCompact flags', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const SeverityChip(
            severity: SeverityLevel.medium,
            isSolid: true,
            isCompact: true,
          ),
        ),
      );

      expect(find.text('Medium Severity'), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
    });
  });
}
