import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/widgets/language_toggle_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localeProvider = LocaleProvider(
      prefs: prefs,
      initialLocale: const Locale('en'),
    );
  });

  Widget buildTestable(Widget widget) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: localeProvider,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(child: widget),
        ),
      ),
    );
  }

  group('LanguageToggleWidget (Task 20)', () {
    testWidgets('renders English and Hindi options in standard mode', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LanguageToggleWidget(),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
    });

    testWidgets('renders EN and Hindi in compact mode', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LanguageToggleWidget(isCompact: true),
        ),
      );

      expect(find.text('EN'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
    });

    testWidgets('tapping Hindi switches active locale to Hindi', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LanguageToggleWidget(),
        ),
      );

      expect(localeProvider.isHindi, isFalse);

      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      expect(localeProvider.isHindi, isTrue);
      expect(localeProvider.currentLocale.languageCode, 'hi');
    });

    testWidgets('tapping English when Hindi is active switches back to English', (tester) async {
      await localeProvider.setLocale(const Locale('hi'));

      await tester.pumpWidget(
        buildTestable(
          const LanguageToggleWidget(),
        ),
      );

      expect(localeProvider.isHindi, isTrue);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(localeProvider.isEnglish, isTrue);
      expect(localeProvider.currentLocale.languageCode, 'en');
    });
  });
}
