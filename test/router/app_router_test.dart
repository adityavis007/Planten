import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/models/diagnosis_result.dart';
import 'package:planten/models/severity_level.dart';
import 'package:planten/screens/auth/login_screen.dart';
import 'package:planten/screens/crops/my_crop_screen.dart';
import 'package:planten/screens/history/history_screen.dart';
import 'package:planten/screens/home/home_screen.dart';
import 'package:planten/screens/profile/disclaimer_screen.dart';
import 'package:planten/screens/profile/profile_screen.dart';
import 'package:planten/screens/result/result_screen.dart';
import 'package:planten/screens/scan/scan_screen.dart';
import 'package:planten/screens/search/search_screen.dart';
import 'package:planten/screens/splash_screen.dart';

void main() {
  group('AppRouter Declarative Navigation (Task 21)', () {
    test('defines all core routes per specification', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.profileSetup,
        AppRoutes.cropSelection,
        AppRoutes.home,
        AppRoutes.scan,
        AppRoutes.scanPreview,
        AppRoutes.result,
        AppRoutes.history,
        AppRoutes.search,
        AppRoutes.myCrop,
        AppRoutes.cropDetail,
        AppRoutes.profile,
        AppRoutes.disclaimer,
      ];
      expect(routes.length, 14);
    });

    testWidgets('initialLocation defaults to AppRoutes.splash', (tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Planten'), findsOneWidget);

      // Drain splash screen duration
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('navigates to shell routes (home, history, myCrop, search, profile)', (tester) async {
      final router = AppRouter.createRouter(initialLocation: AppRoutes.home);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to History tab
      router.go(AppRoutes.history);
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      // Navigate to My Crop tab
      router.go(AppRoutes.myCrop);
      await tester.pumpAndSettle();
      expect(find.byType(MyCropScreen), findsOneWidget);

      // Navigate to Search route
      router.go(AppRoutes.search);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);

      // Navigate to Profile tab
      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('navigates to full-screen scan and login routes', (tester) async {
      final router = AppRouter.createRouter(initialLocation: AppRoutes.login);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      router.go(AppRoutes.scan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ScanScreen), findsOneWidget);
    });

    testWidgets('parses DiagnosisResult extra on /result route', (tester) async {
      final router = AppRouter.createRouter(initialLocation: AppRoutes.home);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final mockResult = DiagnosisResult(
        id: 'result-123',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        diseaseNameEn: 'Early Blight',
        diseaseNameHi: 'अगेती झुलसा',
        confidenceScore: 0.92,
        severity: SeverityLevel.medium,
        timestamp: DateTime.now(),
        localImagePath: '/tmp/leaf.jpg',
      );

      router.go(AppRoutes.result, extra: mockResult);
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('Diagnosis Result'), findsOneWidget);
      expect(find.text('Likely Early Blight'), findsOneWidget);
    });

    testWidgets('navigates to /disclaimer route and renders DisclaimerScreen', (tester) async {
      final router = AppRouter.createRouter(initialLocation: AppRoutes.home);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.disclaimer);
      await tester.pumpAndSettle();

      expect(find.byType(DisclaimerScreen), findsOneWidget);
      expect(find.text('Legal Disclaimer & Advisory'), findsOneWidget);
    });
  });
}
