import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../l10n/app_localizations.dart';
import '../models/weather_data.dart';
import '../providers/auth_provider.dart';
import '../providers/weather_provider.dart';

/// Outdoor-optimized real-time weather card designed for high contrast and sunlight legibility.
///
/// Features:
/// - Open-Meteo real-time live forecast display.
/// - Bilingual English & Hindi support for conditions and metric labels.
/// - High-contrast daylight typography compliant with WCAG AA.
/// - Offline cached indicator badge and interactive refresh action.
class WeatherCard extends StatelessWidget {
  /// Optional injected [WeatherProvider] for isolated testing.
  final WeatherProvider? weatherProvider;

  /// Optional injected [AuthProvider] for test verification.
  final AuthProvider? authProvider;

  /// Optional callback override for refresh button tap.
  final VoidCallback? onRefreshTap;

  /// Optional callback invoked when the weather card is tapped.
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    this.weatherProvider,
    this.authProvider,
    this.onRefreshTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    WeatherProvider? provider;
    try {
      provider = weatherProvider ?? context.watch<WeatherProvider>();
    } catch (_) {
      provider = weatherProvider;
    }

    AuthProvider? auth;
    try {
      auth = authProvider ?? context.watch<AuthProvider>();
    } catch (_) {
      auth = authProvider;
    }

    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

    if (provider == null) {
      return const SizedBox.shrink();
    }

    final isLoading = provider.isLoading;
    final weather = provider.weatherData;
    final errorMessage = provider.errorMessage;

    // 1. Error state (no cached data available)
    if (errorMessage != null && weather == null) {
      return _buildErrorState(context, provider, auth, l10n, languageCode);
    }

    // 2. Loading state (no cached data yet)
    if (isLoading && weather == null) {
      return _buildLoadingSkeleton(context, l10n);
    }

    // 3. Normal or Cached Weather Display
    if (weather != null) {
      return _buildWeatherContent(
        context: context,
        provider: provider,
        weather: weather,
        auth: auth,
        l10n: l10n,
        languageCode: languageCode,
        isLoading: isLoading,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildWeatherContent({
    required BuildContext context,
    required WeatherProvider provider,
    required WeatherData weather,
    required AuthProvider? auth,
    required AppLocalizations? l10n,
    required String languageCode,
    required bool isLoading,
  }) {
    final isCurrent = weather.locationName.isEmpty ||
        weather.locationName == 'Current Location';
    final locationText = isCurrent
        ? (l10n?.currentLocation ?? 'Current Location')
        : weather.locationName;

    final conditionText = weather.localizedCondition(languageCode);
    final isDark = context.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('weather_card_container'),
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            context.push(AppRoutes.weatherDetail);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.primary.withAlpha(40),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(40)
                    : AppColors.primary.withAlpha(12),
                blurRadius: 12.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Location name + Today's Weather + Cached badge + Refresh action
          Row(
            children: [
              // Location Icon & Name
              const Icon(
                Icons.location_on_rounded,
                size: 16.0,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationText,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n?.weatherToday ?? "Today's Weather",
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Cached badge if serving offline record
              if (weather.isFromCache) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(35),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 11.0,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 3.0),
                      Text(
                        l10n?.cachedWeather ?? 'Cached',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.amber[300] : const Color(0xFFC47F00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
              ],

              // Visual chevron affordance
              Icon(
                Icons.chevron_right_rounded,
                size: 20.0,
                color: context.textSecondaryColor,
              ),
              const SizedBox(width: 2.0),

              // Refresh Button
              Semantics(
                label: l10n?.retry ?? 'Refresh Weather',
                button: true,
                child: InkWell(
                  key: const ValueKey('weather_refresh_button'),
                  borderRadius: BorderRadius.circular(20.0),
                  onTap: isLoading
                      ? null
                      : () {
                          if (onRefreshTap != null) {
                            onRefreshTap!();
                          } else {
                            provider.refreshWeather(profile: auth?.profile);
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: isLoading
                        ? const SizedBox(
                            width: 16.0,
                            height: 16.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 19.0,
                            color: context.textSecondaryColor,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Main Section: Large Temperature Display + Weather Condition Icon & Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Weather Condition Icon in Container
              Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    weather.weatherIcon,
                    size: 30.0,
                    color: _iconColorForCode(weather.weatherCode, isDark),
                  ),
                ),
              ),
              const SizedBox(width: 14.0),

              // Temperature Value (High Contrast)
              Text(
                '${weather.temperature.round()}°C',
                style: AppTypography.headline.copyWith(
                  fontSize: 34.0,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryColor,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 12.0),

              // Condition Status Badge
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withAlpha(50)
                          : AppColors.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      conditionText,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14.0),

          // Divider Line
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(120),
          ),

          const SizedBox(height: 12.0),

          // Metrics Grid / Row: Humidity, Wind Speed, Rain Chance
          Row(
            children: [
              // 1. Humidity (नमी)
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  icon: Icons.opacity_rounded,
                  iconColor: const Color(0xFF1976D2),
                  label: l10n?.humidity ?? 'Humidity',
                  value: '${weather.humidity}%',
                ),
              ),

              // Vertical subtle separator
              Container(
                width: 1.0,
                height: 32.0,
                color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(120),
              ),

              // 2. Wind (हवा)
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF00897B),
                  label: l10n?.wind ?? 'Wind',
                  value: '${weather.windSpeed.round()} km/h',
                ),
              ),

              // Vertical subtle separator
              Container(
                width: 1.0,
                height: 32.0,
                color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(120),
              ),

              // 3. Rain Chance (बारिश)
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  icon: Icons.umbrella_rounded,
                  iconColor: const Color(0xFF5C6BC0),
                  label: l10n?.rainChance ?? 'Rain Chance',
                  value: '${weather.rainProbability}%',
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

  Widget _buildMetricItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.0, color: iconColor),
            const SizedBox(width: 4.0),
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context, AppLocalizations? l10n) {
    return Container(
      key: const ValueKey('weather_card_loading'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            l10n?.weatherToday ?? "Loading Weather...",
            style: AppTypography.body.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WeatherProvider provider,
    AuthProvider? auth,
    AppLocalizations? l10n,
    String languageCode,
  ) {
    return Container(
      key: const ValueKey('weather_card_error'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 24.0,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              l10n?.weatherError ?? 'Unable to load weather',
              style: AppTypography.body.copyWith(
                fontSize: 13.0,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          TextButton.icon(
            onPressed: () => provider.refreshWeather(profile: auth?.profile),
            icon: const Icon(Icons.refresh_rounded, size: 16.0),
            label: Text(l10n?.retry ?? 'Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _iconColorForCode(int code, bool isDark) {
    if (code == 0 || code == 1) {
      return isDark ? Colors.amber[300]! : const Color(0xFFF57F17); // Sun Amber
    }
    if (code >= 51 && code <= 67) {
      return isDark ? Colors.lightBlue[300]! : const Color(0xFF1E88E5); // Rain Blue
    }
    if (code >= 71 && code <= 77) {
      return isDark ? Colors.cyan[200]! : const Color(0xFF00ACC1); // Snow Cyan
    }
    if (code >= 95) {
      return isDark ? Colors.deepPurple[200]! : const Color(0xFF5E35B1); // Thunder Purple
    }
    return isDark ? Colors.blueGrey[200]! : const Color(0xFF546E7A); // Clouds
  }
}
