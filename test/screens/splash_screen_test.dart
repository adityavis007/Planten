import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/models/farmer_profile.dart';
import 'package:planten/screens/splash_screen.dart';
import 'package:planten/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableSplash({
    required LocalStorageService storageService,
    Duration splashDuration = const Duration(milliseconds: 100),
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => SplashScreen(
            localStorageService: storageService,
            splashDuration: splashDuration,
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Scaffold(body: Text('Login Screen Destination')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Scaffold(body: Text('Home Screen Destination')),
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          builder: (context, state) => const Scaffold(body: Text('Profile Setup Destination')),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  group('SplashScreen (Task 23)', () {
    testWidgets('renders brand emblem, app title, and tagline', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs: prefs);

      await tester.pumpWidget(
        buildTestableSplash(
          storageService: storage,
          splashDuration: const Duration(milliseconds: 500),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Planten'), findsOneWidget);
      expect(find.text('Your AI Crop Doctor'), findsOneWidget);
      expect(find.byKey(const ValueKey('app_logo_emblem')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('routes to /login when no profile is cached', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs: prefs);

      await tester.pumpWidget(
        buildTestableSplash(
          storageService: storage,
          splashDuration: const Duration(milliseconds: 50),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Login Screen Destination'), findsOneWidget);
    });

    testWidgets('routes to /home when complete profile is cached', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs: prefs);

      await storage.saveUserProfile(
        FarmerProfile(
          uid: 'user-001',
          phoneNumber: '+919876543210',
          name: 'Shyam Lal',
          village: 'Kalyanpur',
          district: 'Kanpur',
          state: 'Uttar Pradesh',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableSplash(
          storageService: storage,
          splashDuration: const Duration(milliseconds: 50),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Home Screen Destination'), findsOneWidget);
    });

    testWidgets('routes to /profile-setup when cached profile is incomplete', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs: prefs);

      await storage.saveUserProfile(
        FarmerProfile(
          uid: 'user-incomplete',
          phoneNumber: '+919876543210',
          name: 'Shyam Lal',
          village: '', // Missing village makes profile incomplete
          district: '',
          state: '',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableSplash(
          storageService: storage,
          splashDuration: const Duration(milliseconds: 50),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Profile Setup Destination'), findsOneWidget);
    });
  });
}
