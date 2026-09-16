import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../services/user_profile_service.dart';

/// Splash screen displaying the Planten brand and resolving initial navigation.
///
/// Workflow:
/// 1. Displays the Planten emblem, brand title, and tagline.
/// 2. Initializes [LocalStorageService].
/// 3. Inspects cached authentication and profile completeness.
/// 4. Routes cleanly to `/home`, `/profile-setup`, or `/login` within ~1.2 seconds.
class SplashScreen extends StatefulWidget {
  /// Optional injected [LocalStorageService] instance.
  final LocalStorageService? localStorageService;

  /// Optional custom route resolver function for tests.
  final Future<String> Function()? authCheckCallback;

  /// Duration to display splash branding. Defaults to 1200ms.
  final Duration splashDuration;

  const SplashScreen({
    super.key,
    this.localStorageService,
    this.authCheckCallback,
    this.splashDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _splashTimer;
  final Completer<void> _timerCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    if (!_timerCompleter.isCompleted) {
      _timerCompleter.complete();
    }
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppAndNavigate() async {
    _splashTimer = Timer(widget.splashDuration, () {
      if (!_timerCompleter.isCompleted) {
        _timerCompleter.complete();
      }
    });

    final initFuture = _initializeServices();

    // Wait for minimum splash presentation and service initialization in parallel
    await Future.wait([_timerCompleter.future, initFuture]);

    if (!mounted) return;

    final destination = await _determineDestinationRoute();
    if (!mounted) return;

    context.go(destination);
  }

  Future<void> _initializeServices() async {
    try {
      final storage = widget.localStorageService ?? LocalStorageService();
      await storage.init();
    } catch (e) {
      debugPrint('Error during splash service initialization: $e');
    }
  }

  Future<String> _determineDestinationRoute() async {
    if (widget.authCheckCallback != null) {
      return widget.authCheckCallback!();
    }

    try {
      final storage = widget.localStorageService ?? LocalStorageService();
      await storage.init();

      var profile = storage.getUserProfile();

      // If no local cached profile, check if Firebase Auth session is active
      if (profile == null && FirebaseService.instance.isAvailable) {
        final currentAuthUser = FirebaseService.instance.auth?.currentUser;
        if (currentAuthUser != null) {
          final profileService = UserProfileService(localStorageService: storage);
          profile = await profileService.getProfile(currentAuthUser.uid, forceRemote: true);
        }
      }

      if (profile != null) {
        if (profile.isProfileComplete) {
          return AppRoutes.home;
        } else {
          return AppRoutes.profileSetup;
        }
      }
    } catch (e) {
      debugPrint('Error evaluating auth route: $e');
    }

    return AppRoutes.login;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Planten Brand Logo Emblem
                Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(50),
                        blurRadius: 20.0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      key: const ValueKey('app_logo_emblem'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // App Title
                Text(
                  'Planten',
                  style: AppTypography.headline.copyWith(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6.0),

                // Tagline
                Text(
                  'Your AI Crop Doctor',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 15.0,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 48.0),

                // Subtle Progress Indicator
                const SizedBox(
                  width: 22.0,
                  height: 22.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
