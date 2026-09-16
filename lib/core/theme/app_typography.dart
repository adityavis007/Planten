import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions for Planten (AI Crop Doctor)
/// Directly mapped from `AI_Crop_Doctor_Theme_Design_Brief.md`
/// Outdoor-optimized: Body text is never smaller than 14sp for sunlight readability.
abstract final class AppTypography {
  static const List<String> _fontFamilyFallbacks = [
    'Noto Sans Devanagari',
    'Roboto',
    'sans-serif',
  ];

  /// Headline: 22sp, Semibold (w600) — screen titles, major results
  static TextStyle get headline => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ).copyWith(fontFamilyFallback: _fontFamilyFallbacks);

  /// Section Title: 18sp, Semibold (w600) — card titles, subheadings
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      ).copyWith(fontFamilyFallback: _fontFamilyFallbacks);

  /// Body Regular: 14sp, Regular (w400) — descriptions, instructions
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      ).copyWith(fontFamilyFallback: _fontFamilyFallbacks);

  /// Body Medium: 14sp, Medium (w500) — emphasized body text, list labels
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.45,
      ).copyWith(fontFamilyFallback: _fontFamilyFallbacks);

  /// Caption: 12sp, Regular (w400) — timestamps, metadata, helper text
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ).copyWith(fontFamilyFallback: _fontFamilyFallbacks);

  /// Button: 15sp, Medium (w500) — CTAs, primary buttons
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 0.1,
      ).copyWith(fontFamilyFallback: _fontFamilyFallbacks);

  /// Builds a complete Material TextTheme configured with Inter & Devanagari fallbacks
  static TextTheme createTextTheme([Color? textColor]) {
    final baseColor = textColor ?? AppColors.textPrimary;
    return GoogleFonts.interTextTheme().copyWith(
      headlineLarge: headline.copyWith(color: baseColor),
      headlineMedium: headline.copyWith(fontSize: 20, color: baseColor),
      titleLarge: sectionTitle.copyWith(color: baseColor),
      titleMedium: sectionTitle.copyWith(fontSize: 16, color: baseColor),
      bodyLarge: bodyMedium.copyWith(color: baseColor),
      bodyMedium: body.copyWith(color: baseColor),
      bodySmall: caption,
      labelLarge: button,
    );
  }

  /// Style tailored specifically for Devanagari vernacular typography
  /// ensuring 1.45 line-height to prevent matra and conjunct clipping.
  static TextStyle devanagariStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return body.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      height: 1.45,
    );
  }

  /// Calculates the WCAG 2.1 contrast ratio between [foreground] and [background].
  /// Returns a ratio between 1.0:1 and 21.0:1.
  static double calculateContrastRatio(Color foreground, Color background) {
    final lum1 = foreground.computeLuminance();
    final lum2 = background.computeLuminance();
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
