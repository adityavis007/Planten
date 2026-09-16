import 'package:flutter/material.dart';

/// Semantic color tokens for Planten (AI Crop Doctor)
/// Directly mapped from `AI_Crop_Doctor_Theme_Design_Brief.md`
abstract final class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF2E7D32); // Forest Green: App bar, primary buttons, active nav icon
  static const Color primaryLight = Color(0xFF66BB6A); // Leaf Green: Secondary buttons, progress indicators, highlights
  static const Color secondary = Color(0xFF8D6E63); // Soil Brown: Secondary accents, farm/soil icons
  static const Color accent = Color(0xFFF9A825); // Harvest Amber: Medium-confidence badges, CTAs needing attention

  // Status & Severity Colors
  static const Color success = Color(0xFF43A047); // Healthy Green: "Healthy" results, completed states
  static const Color warning = Color(0xFFFB8C00); // Amber Orange: Medium severity, "possible disease"
  static const Color error = Color(0xFFD84315); // Deep Rust: High severity, "consult expert now"

  // Neutral & Surface Colors
  static const Color background = Color(0xFFF7F9F5); // Off-white: Screen background
  static const Color surface = Color(0xFFFFFFFF); // White: Cards, sheets, dialogs
  static const Color textPrimary = Color(0xFF212121); // Charcoal: Headlines, body text
  static const Color textSecondary = Color(0xFF6B6B6B); // Warm Grey: Captions, timestamps, helper text
  static const Color border = Color(0xFFE0E0E0); // Outline/divider line color

  // Dark Theme Neutral & Surface Colors
  static const Color backgroundDark = Color(0xFF111811); // Deep slate green: Screen background
  static const Color surfaceDark = Color(0xFF1B241B); // Dark container surface
  static const Color appBarDark = Color(0xFF141D14); // Dark app bar
  static const Color textPrimaryDark = Color(0xFFE2ECE2); // Crisp high-contrast text
  static const Color textSecondaryDark = Color(0xFFA0ABA0); // Muted green-grey text
  static const Color borderDark = Color(0xFF2B3A2B); // Dark border

  // Dynamic Theme Resolvers
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surface;

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : background;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondary;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : border;

  static Color appBarBgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? appBarDark : Colors.white;
}

/// Helpful context extension for concise access to theme-aware colors
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => AppColors.surfaceOf(this);
  Color get backgroundColor => AppColors.backgroundOf(this);
  Color get textPrimaryColor => AppColors.textPrimaryOf(this);
  Color get textSecondaryColor => AppColors.textSecondaryOf(this);
  Color get borderColor => AppColors.borderOf(this);
  Color get appBarBgColor => AppColors.appBarBgOf(this);
}
