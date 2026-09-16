import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/crop.dart';
import '../../models/diagnosis_result.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/crops/crop_farming_detail_screen.dart';
import '../../screens/crops/my_crop_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/home/crop_selection_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/weather_detail_screen.dart';
import '../../screens/main_scaffold.dart';
import '../../screens/profile/disclaimer_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/profile_setup_screen.dart';
import '../../screens/result/result_screen.dart';
import '../../screens/scan/photo_preview_screen.dart';
import '../../screens/scan/scan_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/splash_screen.dart';

/// Semantic route path constants for Planten (AI Crop Doctor).
abstract final class AppRoutes {
  /// Splash screen checking initial auth and offline profile cache.
  static const String splash = '/splash';

  /// Phone number OTP / email login screen.
  static const String login = '/login';

  /// Email / Google signup screen.
  static const String signup = '/signup';

  /// First-time onboarding profile setup (name, village, primary crops).
  static const String profileSetup = '/profile-setup';

  /// Visual crop selection screen / modal (Tomato, Wheat, Potato, Chili, Cotton).
  static const String cropSelection = '/crop-selection';

  /// Home dashboard showcasing active crop and quick scan CTA (Shell Tab 0).
  static const String home = '/home';

  /// Full-screen camera viewfinder for leaf diagnosis.
  static const String scan = '/scan';

  /// Captured image preview and blur/lighting pre-check.
  static const String scanPreview = '/scan/preview';

  /// Full-screen diagnosis result and treatment guidance view.
  static const String result = '/result';

  /// History list of past diagnoses (Shell Tab 1).
  static const String history = '/history';

  /// Search past scans and treatment knowledge base.
  static const String search = '/search';

  /// My Crop farming and cultivation guide (Shell Tab 2).
  static const String myCrop = '/my-crop';

  /// Crop cultivation and farming detail screen.
  static const String cropDetail = '/crop-detail';

  /// Farmer profile, language switcher, and settings (Shell Tab 3).
  static const String profile = '/profile';

  /// In-app legal liability disclaimer and advisory notice screen.
  static const String disclaimer = '/disclaimer';

  /// Extended real-time agricultural weather details and spray advisory.
  static const String weatherDetail = '/weather-detail';
}

/// Declarative routing configuration for Planten using [GoRouter].
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'home');
  static final GlobalKey<NavigatorState> _historyNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'history');
  static final GlobalKey<NavigatorState> _myCropNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'myCrop');
  static final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profile');

  /// Creates and configures the app's [GoRouter] instance.
  static GoRouter createRouter({
    String initialLocation = AppRoutes.splash,
    List<NavigatorObserver>? observers,
  }) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      observers: observers,
      routes: [
        // Top-Level Route: Splash
        GoRoute(
          path: AppRoutes.splash,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SplashScreen(),
        ),

        // Top-Level Route: Login / Auth Gate
        GoRoute(
          path: AppRoutes.login,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LoginScreen(),
        ),

        // Top-Level Route: Signup / Account Creation
        GoRoute(
          path: AppRoutes.signup,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SignupScreen(),
        ),

        // Top-Level Route: Profile Setup Onboarding
        GoRoute(
          path: AppRoutes.profileSetup,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProfileSetupScreen(),
        ),

        // Top-Level Route: Visual Crop Selection
        GoRoute(
          path: AppRoutes.cropSelection,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CropSelectionScreen(),
        ),

        // Top-Level Route: Full-Screen Camera Scan
        GoRoute(
          path: AppRoutes.scan,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ScanScreen(),
        ),

        // Top-Level Route: Photo Preview & Quality Check
        GoRoute(
          path: AppRoutes.scanPreview,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final imagePath = state.extra as String? ?? '';
            return PhotoPreviewScreen(imagePath: imagePath);
          },
        ),

        // Top-Level Route: Full-Screen Diagnosis Result
        GoRoute(
          path: AppRoutes.result,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final scanResult = state.extra as DiagnosisResult?;
            return ResultScreen(result: scanResult);
          },
        ),

        // Top-Level Route: Legal Disclaimer & Advisory
        GoRoute(
          path: AppRoutes.disclaimer,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const DisclaimerScreen(),
        ),

        // Top-Level Route: Extended Agricultural Weather Details
        GoRoute(
          path: AppRoutes.weatherDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const WeatherDetailScreen(),
        ),

        // Top-Level Route: Search Scans & Knowledge Base
        GoRoute(
          path: AppRoutes.search,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SearchScreen(),
        ),

        // Top-Level Route: Crop Cultivation & Farming Detail Screen
        GoRoute(
          path: AppRoutes.cropDetail,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final crop = state.extra is Crop
                ? state.extra as Crop
                : (state.extra is String
                    ? Crop.fromId(state.extra as String)
                    : Crop.initialCrops.first);
            return CropFarmingDetailScreen(crop: crop);
          },
        ),

        // Bottom Navigation Shell Route (Tabs: Home, History, My Crop, Profile)
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Home Dashboard
            StatefulShellBranch(
              navigatorKey: _homeNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),

            // Branch 1: Scan History
            StatefulShellBranch(
              navigatorKey: _historyNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.history,
                  builder: (context, state) => const HistoryScreen(),
                ),
              ],
            ),

            // Branch 2: My Crop & Farming Guides
            StatefulShellBranch(
              navigatorKey: _myCropNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.myCrop,
                  builder: (context, state) => const MyCropScreen(),
                ),
              ],
            ),

            // Branch 3: Farmer Profile & Settings
            StatefulShellBranch(
              navigatorKey: _profileNavigatorKey,
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      ),
    );
  }

  /// Global singleton router instance initialized with default splash location.
  static final GoRouter router = createRouter();
}
