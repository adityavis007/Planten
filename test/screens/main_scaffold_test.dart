import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/screens/crops/my_crop_screen.dart';
import 'package:planten/screens/history/history_screen.dart';
import 'package:planten/screens/home/home_screen.dart';
import 'package:planten/screens/main_scaffold.dart';
import 'package:planten/screens/profile/profile_screen.dart';
import 'package:planten/screens/scan/scan_screen.dart';
import 'package:planten/widgets/offline_banner.dart';

void main() {
  Widget buildTestableShellRouter({String initialLocation = AppRoutes.home}) {
    final router = AppRouter.createRouter(initialLocation: initialLocation);
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  group('MainScaffold (Task 22 & 5-slot Navbar)', () {
    testWidgets('renders Home, History, My Crop, Profile tabs and center elevated Scan button', (tester) async {
      await tester.pumpWidget(buildTestableShellRouter());
      await tester.pumpAndSettle();

      expect(find.byType(MainScaffold), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('My Crop'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    });

    testWidgets('tapping History, My Crop, and Profile switches tabs', (tester) async {
      await tester.pumpWidget(buildTestableShellRouter());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryScreen), findsOneWidget);

      // Tap My Crop tab
      await tester.tap(find.text('My Crop'));
      await tester.pumpAndSettle();

      expect(find.byType(MyCropScreen), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);

      // Tap Home tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('tapping center camera button navigates to /scan route', (tester) async {
      await tester.pumpWidget(buildTestableShellRouter());
      await tester.pumpAndSettle();

      // Tap elevated center camera button
      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ScanScreen), findsOneWidget);
    });

    testWidgets('renders OfflineBanner inside MainScaffold', (tester) async {
      await tester.pumpWidget(buildTestableShellRouter());
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
    });
  });
}
