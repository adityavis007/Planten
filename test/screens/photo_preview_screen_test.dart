import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/core/utils/image_quality_checker.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/scan/photo_preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;

  // Create a minimal 1x1 transparent memory image for test imageProvider
  final Uint8List transparentImage = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localeProvider = LocaleProvider(prefs: prefs);
  });

  Widget buildTestablePhotoPreviewScreen({
    String imagePath = 'test/mock_leaf.jpg',
    Future<ImageQualityResult> Function(String)? qualityCheckOverride,
    VoidCallback? onRetake,
    ValueChanged<String>? onAnalyze,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: PhotoPreviewScreen(
          imagePath: imagePath,
          imageProviderOverride: MemoryImage(transparentImage),
          qualityCheckOverride: qualityCheckOverride,
          onRetake: onRetake,
          onAnalyze: onAnalyze,
        ),
      ),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('PhotoPreviewScreen (Task 37)', () {
    testWidgets('renders interactive zoomable photo preview and top bar',
        (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: true,
            averageLuminance: 120.0,
            sharpnessScore: 90.0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const ValueKey('back_preview_button')), findsOneWidget);
    });

    testWidgets('shows "Good Quality" badge and "Analyze Leaf" primary button when valid',
        (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: true,
            averageLuminance: 130.0,
            sharpnessScore: 85.0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Good quality badge
      expect(find.byKey(const ValueKey('good_quality_badge')), findsOneWidget);
      expect(find.text('Good Quality'), findsOneWidget);

      // Warning banner absent
      expect(find.byKey(const ValueKey('quality_warning_banner')), findsNothing);

      // Action buttons
      expect(find.byKey(const ValueKey('analyze_leaf_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('retake_photo_button')), findsOneWidget);
    });

    testWidgets(
        'shows amber warning banner and promotes "Retake Photo" as primary button when quality check fails',
        (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: false,
            isTooDark: true,
            averageLuminance: 20.0,
            warningMessageEn: 'Photo appears too dark. Please take photo in good daylight.',
            warningMessageHi: 'फोटो बहुत धुंधली या अंधेरे में है।',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quality Issue badge
      expect(find.byKey(const ValueKey('quality_issue_badge')), findsOneWidget);
      expect(find.text('Quality Issue'), findsOneWidget);

      // Warning banner with localized message
      expect(find.byKey(const ValueKey('quality_warning_banner')), findsOneWidget);
      expect(
        find.text('Photo appears too dark. Please take photo in good daylight.'),
        findsOneWidget,
      );

      // In warning state, Continue and Retake are available
      expect(find.byKey(const ValueKey('continue_anyway_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('retake_photo_button')), findsOneWidget);
    });

    testWidgets('tapping "Retake Photo" invokes onRetake callback',
        (tester) async {
      setPhoneViewport(tester);
      bool retakeCalled = false;

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          onRetake: () {
            retakeCalled = true;
          },
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('retake_photo_button')));
      await tester.pump();

      expect(retakeCalled, isTrue);
    });

    testWidgets('tapping back button in top bar invokes onRetake callback',
        (tester) async {
      setPhoneViewport(tester);
      bool retakeCalled = false;

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          onRetake: () {
            retakeCalled = true;
          },
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('back_preview_button')));
      await tester.pump();

      expect(retakeCalled, isTrue);
    });

    testWidgets('tapping "Analyze Leaf" invokes onAnalyze callback with imagePath',
        (tester) async {
      setPhoneViewport(tester);
      String? analyzedPath;

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          imagePath: 'farm/wheat_rust.jpg',
          onAnalyze: (path) {
            analyzedPath = path;
          },
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('analyze_leaf_button')));
      await tester.pump();

      expect(analyzedPath, 'farm/wheat_rust.jpg');
    });

    testWidgets('tapping "Continue Anyway" invokes onAnalyze callback when warning is shown',
        (tester) async {
      setPhoneViewport(tester);
      String? analyzedPath;

      await tester.pumpWidget(
        buildTestablePhotoPreviewScreen(
          imagePath: 'farm/dark_chili.jpg',
          onAnalyze: (path) {
            analyzedPath = path;
          },
          qualityCheckOverride: (_) async => const ImageQualityResult(
            isValid: false,
            isTooDark: true,
            warningMessageEn: 'Photo appears too dark.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue_anyway_button')));
      await tester.pump();

      expect(analyzedPath, 'farm/dark_chili.jpg');
    });

    testWidgets('navigates via GoRouter at AppRoutes.scanPreview',
        (tester) async {
      setPhoneViewport(tester);

      final router = GoRouter(
        initialLocation: AppRoutes.scanPreview,
        routes: [
          GoRoute(
            path: AppRoutes.scanPreview,
            builder: (context, state) => PhotoPreviewScreen(
              imagePath: 'test/preview_leaf.jpg',
              imageProviderOverride: MemoryImage(transparentImage),
              qualityCheckOverride: (_) async => const ImageQualityResult(
                isValid: true,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
    });
  });
}
