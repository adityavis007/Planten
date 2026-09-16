import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Style variants for [AppButton].
enum AppButtonType {
  /// Forest green filled button for major primary actions.
  primary,

  /// Leaf green filled button for secondary affirmative actions.
  secondary,

  /// Outlined button with green border and transparent background.
  outline,
}

/// Accessible, outdoor-optimized action button adhering to the Planten Design System.
///
/// Guarantees a minimum touch target height of 48dp, 12px rounded corners,
/// and support for loading spinner, disabled state, and optional leading/trailing icons.
class AppButton extends StatelessWidget {
  /// The text label to display on the button.
  final String text;

  /// Callback executed when button is tapped. If null, button appears disabled.
  final VoidCallback? onPressed;

  /// The visual variant of the button (primary, secondary, outline).
  final AppButtonType type;

  /// If true, displays a centered loading spinner and disables tap callbacks.
  final bool isLoading;

  /// Optional leading icon displayed before the label.
  final Widget? leadingIcon;

  /// Optional trailing icon displayed after the label.
  final Widget? trailingIcon;

  /// Height of the button. Minimum is enforced at 48.0 dp for accessibility.
  final double height;

  /// Whether the button expands to fill available horizontal width.
  final bool isFullWidth;

  /// Custom padding inside the button.
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 48.0,
    this.isFullWidth = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final effectiveHeight = height < 48.0 ? 48.0 : height;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.primary.withAlpha(120);
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case AppButtonType.secondary:
        backgroundColor = isEnabled ? AppColors.primaryLight : AppColors.primaryLight.withAlpha(120);
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? AppColors.primary : AppColors.primary.withAlpha(120);
        borderSide = BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.primary.withAlpha(120),
          width: 1.5,
        );
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor,
      disabledForegroundColor: foregroundColor.withAlpha(180),
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderSide,
      ),
      minimumSize: Size(isFullWidth ? double.infinity : 48.0, effectiveHeight),
      textStyle: AppTypography.button,
    );

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else {
      final children = <Widget>[];

      if (leadingIcon != null) {
        children.add(leadingIcon!);
        children.add(const SizedBox(width: 8));
      }

      children.add(
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.button.copyWith(color: foregroundColor),
              maxLines: 1,
            ),
          ),
        ),
      );

      if (trailingIcon != null) {
        children.add(const SizedBox(width: 8));
        children.add(trailingIcon!);
      }

      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }

    return SizedBox(
      height: effectiveHeight,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: buttonStyle,
        child: content,
      ),
    );
  }
}
