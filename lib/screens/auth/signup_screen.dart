import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/language_toggle_widget.dart';

/// Screen allowing new farmers to register an account using Email/Password or Google Sign-In.
///
/// Features:
/// - Brand emblem and tagline.
/// - Language switcher toggle in the header.
/// - Email, Password, and Confirm Password fields with validation.
/// - "Continue with Google" social login.
/// - Navigation back to [LoginScreen] for existing accounts.
/// - On successful creation, transitions seamlessly to [ProfileSetupScreen].
class SignupScreen extends StatefulWidget {
  /// Optional injected [AuthProvider] for widget testing.
  final AuthProvider? authProvider;

  const SignupScreen({super.key, this.authProvider});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _clientValidationError;

  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignup(AuthProvider? auth) async {
    setState(() {
      _clientValidationError = null;
    });
    auth?.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _clientValidationError =
            AppLocalizations.of(context)?.passwordsDoNotMatch ??
            'Passwords do not match';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    if (auth != null) {
      final success = await auth.registerWithEmail(email, password);
      if (!mounted) return;
      if (success) {
        context.go(AppRoutes.profileSetup);
      }
    }
  }

  Future<void> _handleGoogleSignup(AuthProvider? auth) async {
    setState(() {
      _clientValidationError = null;
    });
    auth?.clearError();

    FocusScope.of(context).unfocus();

    if (auth != null) {
      final success = await auth.loginWithGoogle();
      if (!mounted) return;
      if (success) {
        if (auth.isProfileComplete) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.profileSetup);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider? auth = widget.authProvider;
    try {
      auth ??= context.watch<AuthProvider>();
    } catch (_) {
      auth = null;
    }

    final l10n = AppLocalizations.of(context);
    final activeError = _clientValidationError ?? auth?.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Language Switcher
              const Align(
                alignment: Alignment.topRight,
                child: LanguageToggleWidget(isCompact: true),
              ),
              const SizedBox(height: 16.0),

              // Hero Brand Emblem
              Center(
                child: Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 16.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      key: const ValueKey('app_logo_emblem'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // App Title & Tagline
              Center(
                child: Text(
                  l10n?.appTitle ?? 'Planten',
                  style: AppTypography.headline.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Center(
                child: Text(
                  l10n?.appTagline ?? 'Your AI Crop Doctor',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14.0,
                  ),
                ),
              ),
              const SizedBox(height: 28.0),

              // Signup Form Card
              Container(
                key: const ValueKey('signup_card'),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n?.signupTitle ?? 'Create Account',
                        style: AppTypography.sectionTitle.copyWith(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Join thousands of farmers protecting their crops with AI diagnostics.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13.0,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Email Field
                      Text(
                        l10n?.emailLabel ?? 'Email',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        key: const Key('signup_email_field'),
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.body.copyWith(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              l10n?.enterEmail ?? 'Enter your email address',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textSecondary.withAlpha(140),
                            fontSize: 14.0,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20.0,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.invalidEmail ??
                                'Please enter a valid email address';
                          }
                          if (!_emailRegex.hasMatch(value.trim())) {
                            return l10n?.invalidEmail ??
                                'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Password Field
                      Text(
                        l10n?.passwordLabel ?? 'Password',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        key: const Key('signup_password_field'),
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.body.copyWith(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              l10n?.enterPassword ?? 'Enter your password',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textSecondary.withAlpha(140),
                            fontSize: 14.0,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20.0,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            key: const Key('signup_password_visibility_toggle'),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20.0,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return l10n?.passwordTooShort ??
                                'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Confirm Password Field
                      Text(
                        l10n?.confirmPasswordLabel ?? 'Confirm Password',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFormField(
                        key: const Key('signup_confirm_password_field'),
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        style: AppTypography.body.copyWith(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              l10n?.enterConfirmPassword ??
                              'Re-enter your password',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textSecondary.withAlpha(140),
                            fontSize: 14.0,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_reset_rounded,
                            size: 20.0,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            key: const Key(
                              'signup_confirm_password_visibility_toggle',
                            ),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20.0,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.8,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.enterConfirmPassword ??
                                'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return l10n?.passwordsDoNotMatch ??
                                'Passwords do not match';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSignup(auth),
                      ),

                      // Error Banner
                      if (activeError != null) ...[
                        const SizedBox(height: 14.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(24),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: AppColors.error.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18.0,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  activeError,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.error,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22.0),

                      // Create Account Button
                      AppButton(
                        key: const Key('signup_submit_button'),
                        text: l10n?.createAccount ?? 'Create Account',
                        isLoading: auth?.isLoading ?? false,
                        onPressed: () => _handleSignup(auth),
                        trailingIcon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),

                      const SizedBox(height: 20.0),

                      // OR Divider
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.border),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Text(
                              l10n?.orDivider ?? 'OR',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.border),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16.0),

                      // Google Sign-Up Button
                      OutlinedButton(
                        key: const Key('signup_google_button'),
                        onPressed: (auth?.isLoading ?? false)
                            ? null
                            : () => _handleGoogleSignup(auth),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 28.0,
                              color: Color(0xFF4285F4),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              l10n?.continueWithGoogle ??
                                  'Continue with Google',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              // Bottom Nav to Login Screen
              Center(
                child: TextButton(
                  key: const Key('signup_to_login_button'),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: Text(
                    l10n?.alreadyHaveAccount ??
                        'Already have an account? Login',
                    style: AppTypography.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12.0),

              // Trust notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 15.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Safe & Secure agricultural cloud storage',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
