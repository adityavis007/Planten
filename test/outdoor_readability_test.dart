import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/theme/app_colors.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/core/theme/app_typography.dart';
import 'package:planten/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 57: Outdoor Readability & Touch Target Accessibility Audit', () {
    group('1. Touch Target Accessibility (>= 48x48dp)', () {
      testWidgets('Theme button and chip definitions enforce minimum 48dp targets',
          (tester) async {
        final theme = AppTheme.lightTheme;

        // Elevated Button Theme
        final elevatedMinSize = theme.elevatedButtonTheme.style?.minimumSize?.resolve({});
        expect(elevatedMinSize?.height, greaterThanOrEqualTo(48.0));

        // Outlined Button Theme
        final outlinedMinSize = theme.outlinedButtonTheme.style?.minimumSize?.resolve({});
        expect(outlinedMinSize?.height, greaterThanOrEqualTo(48.0));

        // Text Button Theme
        final textMinSize = theme.textButtonTheme.style?.minimumSize?.resolve({});
        expect(textMinSize?.height, greaterThanOrEqualTo(48.0));
        expect(textMinSize?.width, greaterThanOrEqualTo(48.0));

        // Icon Button Theme
        final iconMinSize = theme.iconButtonTheme.style?.minimumSize?.resolve({});
        expect(iconMinSize?.height, greaterThanOrEqualTo(48.0));
        expect(iconMinSize?.width, greaterThanOrEqualTo(48.0));

        // Chip Theme: Padding ensures legible and comfortable touch target spacing
        expect(theme.chipTheme.padding, isNotNull);
      });

      testWidgets('AppButton enforces minimum 48dp height', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: AppButton(
                  text: 'Submit Scan',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        final buttonSize = tester.getSize(find.byType(AppButton));
        expect(buttonSize.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('ElevatedButton and OutlinedButton render with height >= 48dp',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Action'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Secondary Action'),
                  ),
                ],
              ),
            ),
          ),
        );

        final elevatedSize = tester.getSize(find.byType(ElevatedButton));
        expect(elevatedSize.height, greaterThanOrEqualTo(48.0));

        final outlinedSize = tester.getSize(find.byType(OutlinedButton));
        expect(outlinedSize.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('IconButton renders with >= 48x48dp touch bounds', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        final iconBtnSize = tester.getSize(find.byType(IconButton));
        expect(iconBtnSize.width, greaterThanOrEqualTo(48.0));
        expect(iconBtnSize.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('FilterChip touch target achieves 48x48dp via padded tap target',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: FilterChip(
                  label: const Text('Tomato'),
                  selected: true,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        );

        final chipSize = tester.getSize(find.byType(FilterChip));
        expect(chipSize.height, greaterThanOrEqualTo(48.0));
        expect(chipSize.width, greaterThanOrEqualTo(48.0));
      });
    });

    group('2. Outdoor Typography Scale Audit', () {
      test('All body text styles are >= 14sp for sunlight readability', () {
        // Body Regular
        expect(AppTypography.body.fontSize, greaterThanOrEqualTo(14.0));

        // Body Medium
        expect(AppTypography.bodyMedium.fontSize, greaterThanOrEqualTo(14.0));

        // Button text
        expect(AppTypography.button.fontSize, greaterThanOrEqualTo(14.0));

        // Devanagari default body
        expect(AppTypography.devanagariStyle().fontSize, greaterThanOrEqualTo(14.0));
      });

      test('All heading text styles are >= 18sp for visual hierarchy', () {
        // Section Title
        expect(AppTypography.sectionTitle.fontSize, greaterThanOrEqualTo(18.0));

        // Headline
        expect(AppTypography.headline.fontSize, greaterThanOrEqualTo(18.0));
      });

      test('Caption text style is at 12sp and restricted to secondary metadata', () {
        expect(AppTypography.caption.fontSize, equals(12.0));
        expect(AppTypography.caption.color, equals(AppColors.textSecondary));
      });
    });

    group('3. WCAG AA Contrast Ratio Audit (>= 4.5:1)', () {
      test('Charcoal text (#212121) on Off-white background (#F7F9F5) passes WCAG AA', () {
        final ratio = AppTypography.calculateContrastRatio(
          AppColors.textPrimary,
          AppColors.background,
        );

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: 'Charcoal text must achieve >= 4.5:1 on background');
        expect(ratio, greaterThanOrEqualTo(7.0),
            reason: 'High-contrast charcoal achieves WCAG AAA');
      });

      test('Charcoal text (#212121) on White surface (#FFFFFF) passes WCAG AA', () {
        final ratio = AppTypography.calculateContrastRatio(
          AppColors.textPrimary,
          AppColors.surface,
        );

        expect(ratio, greaterThanOrEqualTo(4.5));
      });

      test('Warm Grey text (#6B6B6B) on Off-white background (#F7F9F5) passes WCAG AA', () {
        final ratio = AppTypography.calculateContrastRatio(
          AppColors.textSecondary,
          AppColors.background,
        );

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: 'Secondary text on background achieves WCAG AA (>= 4.5:1)');
      });

      test('Forest Green (#2E7D32) on Off-white background (#F7F9F5) passes WCAG AA', () {
        final ratio = AppTypography.calculateContrastRatio(
          AppColors.primary,
          AppColors.background,
        );

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: 'Primary brand elements on background achieve WCAG AA');
      });

      test('White text (#FFFFFF) on Forest Green (#2E7D32) passes WCAG AA', () {
        final ratio = AppTypography.calculateContrastRatio(
          Colors.white,
          AppColors.primary,
        );

        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: 'White text on primary buttons achieves WCAG AA');
      });
    });

    group('4. Devanagari Font Fallbacks & Alignment', () {
      test('Typography styles configure Noto Sans Devanagari fallback', () {
        final styles = [
          AppTypography.headline,
          AppTypography.sectionTitle,
          AppTypography.body,
          AppTypography.bodyMedium,
          AppTypography.caption,
          AppTypography.button,
        ];

        for (final style in styles) {
          expect(style.fontFamilyFallback, isNotNull);
          expect(style.fontFamilyFallback, contains('Noto Sans Devanagari'),
              reason: 'Style ${style.fontSize} must include Noto Sans Devanagari fallback');
        }
      });

      test('Body styles ensure minimum 1.4x line height to prevent matra clipping', () {
        expect(AppTypography.body.height, greaterThanOrEqualTo(1.40));
        expect(AppTypography.bodyMedium.height, greaterThanOrEqualTo(1.40));
        expect(AppTypography.devanagariStyle().height, greaterThanOrEqualTo(1.40));
      });

      testWidgets('Devanagari text with upper and lower matras renders without clipping',
          (tester) async {
        const hindiText = 'पौधों के ऊपर से पानी छिड़कने से बचें; पानी सीधे जड़ में दें।';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    hindiText,
                    style: AppTypography.devanagariStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text(hindiText), findsOneWidget);
        // Ensure no overflow errors occurred during layout
        expect(tester.takeException(), isNull);
      });
    });
  });
}
