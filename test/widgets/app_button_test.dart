import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/widgets/app_button.dart';

void main() {
  Widget buildTestable(Widget widget) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(child: widget),
      ),
    );
  }

  group('AppButton Widget (Task 16)', () {
    testWidgets('renders text and fires onPressed when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestable(
          AppButton(
            text: 'Scan Leaf',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Scan Leaf'), findsOneWidget);
      await tester.tap(find.text('Scan Leaf'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('enforces minimum touch target height of at least 48dp', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          AppButton(
            text: 'Small Height Request',
            height: 30.0, // Requested smaller than accessible 48dp
            onPressed: () {},
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('ignores tap events when onPressed is null (disabled state)', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AppButton(
            text: 'Disabled Action',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('shows CircularProgressIndicator and ignores taps when isLoading is true', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestable(
          AppButton(
            text: 'Loading Action',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Action'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('renders leading and trailing icons', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          AppButton(
            text: 'With Icons',
            leadingIcon: const Icon(Icons.camera_alt, key: Key('leading-icon')),
            trailingIcon: const Icon(Icons.arrow_forward, key: Key('trailing-icon')),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('leading-icon')), findsOneWidget);
      expect(find.byKey(const Key('trailing-icon')), findsOneWidget);
      expect(find.text('With Icons'), findsOneWidget);
    });

    testWidgets('renders secondary and outline button types', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          Column(
            children: [
              AppButton(
                text: 'Secondary',
                type: AppButtonType.secondary,
                onPressed: () {},
              ),
              AppButton(
                text: 'Outline',
                type: AppButtonType.outline,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
    });
  });
}
