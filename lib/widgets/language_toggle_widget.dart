import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/locale_provider.dart';

/// Segmented pill switcher allowing farmers to switch between English and vernacular Hindi (हिन्दी).
///
/// Directly bound to [LocaleProvider] and designed for placement in AppBars,
/// Login screen headers, and profile settings.
class LanguageToggleWidget extends StatelessWidget {
  /// Whether to render a compact variant suitable for AppBars and navigation headers.
  final bool isCompact;

  /// Custom active segment highlight color. Defaults to [AppColors.primary].
  final Color? activeColor;

  /// Custom active text color. Defaults to [Colors.white].
  final Color? activeTextColor;

  /// Custom inactive text color. Defaults to [AppColors.textSecondary].
  final Color? inactiveTextColor;

  /// Custom container background color. Defaults to [AppColors.surface].
  final Color? backgroundColor;

  /// Custom border color. Defaults to [AppColors.border].
  final Color? borderColor;

  const LanguageToggleWidget({
    super.key,
    this.isCompact = false,
    this.activeColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    LocaleProvider? localeProvider;
    try {
      localeProvider = Provider.of<LocaleProvider>(context);
    } catch (_) {
      localeProvider = null;
    }
    final isHindi = localeProvider?.isHindi ?? false;

    final effectiveActiveColor = activeColor ?? (context.isDarkMode ? AppColors.primaryLight : AppColors.primary);
    final effectiveActiveTextColor = activeTextColor ?? (context.isDarkMode ? const Color(0xFF0F1A0F) : Colors.white);
    final effectiveInactiveTextColor = inactiveTextColor ?? context.textSecondaryColor;
    final effectiveBgColor = backgroundColor ?? context.surfaceColor;
    final effectiveBorderColor = borderColor ?? context.borderColor;

    final englishLabel = isCompact ? 'EN' : 'English';
    const hindiLabel = 'हिन्दी';

    return Container(
      height: isCompact ? 34.0 : 42.0,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: effectiveBorderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // English Segment
          _buildSegment(
            text: englishLabel,
            isActive: !isHindi,
            activeBgColor: effectiveActiveColor,
            activeTextColor: effectiveActiveTextColor,
            inactiveTextColor: effectiveInactiveTextColor,
            onTap: () {
              if (isHindi) {
                localeProvider?.setLocale(const Locale('en'));
              }
            },
          ),

          // Hindi Segment
          _buildSegment(
            text: hindiLabel,
            isActive: isHindi,
            activeBgColor: effectiveActiveColor,
            activeTextColor: effectiveActiveTextColor,
            inactiveTextColor: effectiveInactiveTextColor,
            onTap: () {
              if (!isHindi) {
                localeProvider?.setLocale(const Locale('hi'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String text,
    required bool isActive,
    required Color activeBgColor,
    required Color activeTextColor,
    required Color inactiveTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10.0 : 16.0,
          vertical: isCompact ? 4.0 : 6.0,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBgColor.withAlpha(50),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: (isCompact ? AppTypography.caption : AppTypography.bodyMedium).copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? activeTextColor : inactiveTextColor,
              fontSize: isCompact ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }
}
