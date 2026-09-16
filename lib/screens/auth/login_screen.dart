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

/// Outdoor-optimized login screen allowing farmers to authenticate via Email and Password,
/// or Continue with Google.
///
/// Features:
/// - Prominent vernacular [LanguageToggleWidget] in header for instant Hindi/English switching.
/// - Planten brand emblem and tagline.
/// - Email/Username input and Password field with visibility toggle.
/// - "Forgot Password?" reset dialog.
/// - "Continue with Google" social login.
/// - "Don't have an account? Sign Up" navigation to [SignupScreen].
/// - Minimum 48dp touch targets and high-contrast outdoor readability.
/// - Integration with [AuthProvider] for reactive loading and error feedback.
class LoginScreen extends StatefulWidget {
  /// Optional injected [AuthProvider] for widget testing.
  final AuthProvider? authProvider;

  const LoginScreen({super.key, this.authProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  String? _clientValidationError;

  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider? auth) async {
    setState(() {
      _clientValidationError = null;
    });
    auth?.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();

    if (auth != null) {
      final success = await auth.loginWithEmail(email, password);
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

  Future<void> _handleGoogleLogin(AuthProvider? auth) async {
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

  void _showForgotPasswordDialog(
    BuildContext context,
    AuthProvider? auth,
    AppLocalizations? l10n,
  ) {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    String? resetError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    l10n?.resetPasswordTitle ?? 'Reset Password',
                    style: AppTypography.sectionTitle,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.resetPasswordInstructions ??
                      'Enter your email to receive a password reset link.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  key: const Key('reset_email_field'),
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n?.enterEmail ?? 'Enter your email address',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                if (resetError != null) ...[
                  const SizedBox(height: 10.0),
                  Text(
                    resetError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                key: const Key('submit_reset_password_button'),
                onPressed: () async {
                  final email = resetEmailController.text.trim();
                  if (email.isEmpty || !_emailRegex.hasMatch(email)) {
                    setDialogState(() {
                      resetError =
                          l10n?.invalidEmail ??
                          'Please enter a valid email address';
                    });
                    return;
                  }

                  if (auth != null) {
                    final sent = await auth.sendPasswordReset(email);
                    if (sent && ctx.mounted) {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n?.resetEmailSent ??
                                'Password reset link sent to your email.',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    } else if (ctx.mounted) {
                      setDialogState(() {
                        resetError =
                            auth.errorMessage ?? 'Could not send reset email.';
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(l10n?.sendResetLink ?? 'Send Reset Link'),
              ),
            ],
          );
        },
      ),
    );
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
              const SizedBox(height: 18.0),

              // Hero Brand Emblem
              Center(
                child: Container(
                  width: 84.0,
                  height: 84.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 18.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22.0),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      key: const ValueKey('app_logo_emblem'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14.0),

              // App Title & Tagline
              Center(
                child: Text(
                  l10n?.appTitle ?? 'Planten',
                  style: AppTypography.headline.copyWith(
                    fontSize: 30.0,
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
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),

              // Login Form Card
              Container(
                key: const ValueKey('login_card'),
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
                        l10n?.loginTitle ?? 'Login',
                        style: AppTypography.sectionTitle.copyWith(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Sign in to access your field diagnostics, crop health insights, and scan history.',
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
                        key: const Key('login_email_field'),
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
                        key: const Key('login_password_field'),
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
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
                            key: const Key('login_password_visibility_toggle'),
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
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleLogin(auth),
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('login_forgot_password_button'),
                          onPressed: () => _showForgotPasswordDialog(
                            context,
                            auth,
                            l10n,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 6.0,
                            ),
                            minimumSize: const Size(0, 36.0),
                          ),
                          child: Text(
                            l10n?.forgotPassword ?? 'Forgot Password?',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ),

                      // Error Banner
                      if (activeError != null) ...[
                        const SizedBox(height: 8.0),
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

                      const SizedBox(height: 18.0),

                      // Login Button
                      AppButton(
                        key: const Key('login_submit_button'),
                        text: l10n?.loginTitle ?? 'Login',
                        isLoading: auth?.isLoading ?? false,
                        onPressed: () => _handleLogin(auth),
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

                      // Google Sign-In Button
                      OutlinedButton(
                        key: const Key('login_google_button'),
                        onPressed: (auth?.isLoading ?? false)
                            ? null
                            : () => _handleGoogleLogin(auth),
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

              // Bottom Nav to Signup Screen
              Center(
                child: TextButton(
                  key: const Key('login_to_signup_button'),
                  onPressed: () => context.push(AppRoutes.signup),
                  child: Text(
                    l10n?.dontHaveAccount ?? "Don't have an account? Sign Up",
                    style: AppTypography.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12.0),

              // Trust & Security Notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Zero-cost authentication for farmers • Secure Cloud',
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
