import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';

/// 6-digit OTP verification view with auto-focus, resend countdown timer,
/// and automatic routing to `/home` or `/profile-setup` upon success.
class OtpVerificationView extends StatefulWidget {
  /// The phone number for which OTP was dispatched.
  final String phoneNumber;

  /// Optional injected [AuthProvider] for widget testing.
  final AuthProvider? authProvider;

  /// Optional custom callback invoked upon successful verification.
  final VoidCallback? onVerificationSuccess;

  /// Duration for resend countdown. Defaults to 60 seconds.
  final int countdownDurationSeconds;

  const OtpVerificationView({
    super.key,
    required this.phoneNumber,
    this.authProvider,
    this.onVerificationSuccess,
    this.countdownDurationSeconds = 60,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _countdownTimer;
  late int _secondsRemaining;
  String? _clientValidationError;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdownDurationSeconds;
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendOtp(AuthProvider? auth) async {
    if (_secondsRemaining > 0 || auth == null) return;

    setState(() {
      _secondsRemaining = widget.countdownDurationSeconds;
      _clientValidationError = null;
    });
    auth.clearError();
    _startCountdownTimer();

    await auth.sendOtp(widget.phoneNumber);
  }

  Future<void> _handleVerify(AuthProvider? auth) async {
    setState(() {
      _clientValidationError = null;
    });
    auth?.clearError();

    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _clientValidationError = 'Please enter all 6 digits of the OTP.';
      });
      return;
    }

    if (auth == null) return;

    FocusScope.of(context).unfocus();

    final success = await auth.verifyOtp(code);
    if (!mounted) return;

    if (success) {
      if (widget.onVerificationSuccess != null) {
        widget.onVerificationSuccess!();
        return;
      }

      if (auth.isProfileComplete) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.profileSetup);
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

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.enterOtp ?? 'Enter OTP',
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                key: const Key('otp_close_button'),
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                tooltip: 'Change Phone Number',
                onPressed: () {
                  auth?.resetOtpState();
                },
              ),
            ],
          ),
          const SizedBox(height: 4.0),

          // Subtext with Phone Number & Edit Action
          Row(
            children: [
              Expanded(
                child: Text(
                  'Code sent to ${widget.phoneNumber}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ),
              TextButton(
                key: const Key('otp_change_number_button'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  auth?.resetOtpState();
                },
                child: Text(
                  'Change',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // 6-Digit PIN Entry Box View
          GestureDetector(
            onTap: () => _otpFocusNode.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hidden native input managing keyboard & text events
                Opacity(
                  opacity: 0.0,
                  child: TextField(
                    key: const Key('otp_hidden_text_field'),
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _handleVerify(auth),
                  ),
                ),

                // Visual Pin Box Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final enteredText = _otpController.text;
                    final char = index < enteredText.length ? enteredText[index] : '';
                    final isFocused = _otpFocusNode.hasFocus && index == enteredText.length;
                    final hasChar = char.isNotEmpty;

                    Color borderColor = AppColors.border;
                    if (activeError != null) {
                      borderColor = AppColors.error;
                    } else if (isFocused) {
                      borderColor = AppColors.primary;
                    } else if (hasChar) {
                      borderColor = AppColors.primaryLight;
                    }

                    return Container(
                      width: 44.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: borderColor,
                          width: (isFocused || activeError != null) ? 2.0 : 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: AppTypography.headline.copyWith(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Error Banner
          if (activeError != null) ...[
            const SizedBox(height: 14.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(24),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.error.withAlpha(60)),
              ),
              child: Row(
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

          const SizedBox(height: 20.0),

          // Resend Timer Row
          Center(
            child: _secondsRemaining > 0
                ? Text(
                    l10n?.resendOtpIn(_secondsRemaining) ??
                        'Resend OTP in ${_secondsRemaining}s',
                    key: const Key('otp_countdown_text'),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : TextButton.icon(
                    key: const Key('otp_resend_button'),
                    icon: const Icon(Icons.refresh_rounded, size: 18.0, color: AppColors.primary),
                    label: Text(
                      l10n?.resendOtp ?? 'Resend OTP',
                      style: AppTypography.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _handleResendOtp(auth),
                  ),
          ),

          const SizedBox(height: 20.0),

          // Verify Button
          AppButton(
            key: const Key('otp_verify_button'),
            text: l10n?.verifyOtp ?? 'Verify & Proceed',
            isLoading: auth?.isLoading ?? false,
            onPressed: () => _handleVerify(auth),
            trailingIcon: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
