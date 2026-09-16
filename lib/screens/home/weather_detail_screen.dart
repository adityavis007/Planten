import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../models/weather_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';

/// Dedicated full-screen weather details view designed for farmers.
///
/// Showcases:
/// - Hero weather condition card with min/max & feels-like temperature.
/// - Smart Agricultural Spray Advisory Card (Favorable vs High Risk).
/// - 24-Hour horizontal forecast slider.
/// - 7-Day daily forecast outlook.
/// - 2x2 agricultural metrics grid (Humidity, Wind, Rain Probability, Daylight/UV).
class WeatherDetailScreen extends StatelessWidget {
  /// Optional injected [WeatherProvider] for test verification.
  final WeatherProvider? weatherProvider;

  /// Optional injected [AuthProvider] for test verification.
  final AuthProvider? authProvider;

  const WeatherDetailScreen({
    super.key,
    this.weatherProvider,
    this.authProvider,
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
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isDark = context.isDarkMode;

    final weather = provider?.weatherData;
    final isLoading = provider?.isLoading ?? false;

    final isCurrent =
        weather == null ||
        weather.locationName.isEmpty ||
        weather.locationName == 'Current Location';
    final locationTitle = isCurrent
        ? (l10n?.currentLocation ?? 'Current Location')
        : weather.locationName;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16.0,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4.0),
                Flexible(
                  child: Text(
                    locationTitle,
                    style: AppTypography.sectionTitle.copyWith(
                      fontSize: 16.0,
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              l10n?.weatherDetails ?? 'Weather Details',
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
        leading: IconButton(
          key: const ValueKey('weather_detail_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('weather_detail_refresh_button'),
            tooltip: l10n?.retry ?? 'Refresh',
            icon: isLoading
                ? const SizedBox(
                    width: 18.0,
                    height: 18.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: isLoading
                ? null
                : () => provider?.refreshWeather(profile: auth?.profile),
          ),
        ],
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
      ),
      body: weather == null
          ? _buildEmptyOrLoading(context, isLoading, l10n)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Weather Card
                  _buildHeroWeatherCard(
                    context,
                    weather,
                    l10n,
                    languageCode,
                    isDark,
                  ),
                  const SizedBox(height: 16.0),

                  // 2. Smart Spray Advisory Card (कृषि सलाह)
                  _buildSprayAdvisoryCard(context, weather, l10n, isDark),
                  const SizedBox(height: 20.0),

                  // 3. 24-Hour Forecast Slider
                  if (weather.hourlyForecast.isNotEmpty) ...[
                    _buildHourlySection(
                      context,
                      weather,
                      l10n,
                      languageCode,
                      isDark,
                    ),
                    const SizedBox(height: 20.0),
                  ],

                  // 4. 7-Day Forecast List
                  if (weather.dailyForecast.isNotEmpty) ...[
                    _buildDailySection(
                      context,
                      weather,
                      l10n,
                      languageCode,
                      isDark,
                    ),
                    const SizedBox(height: 20.0),
                  ],

                  // 5. 2x2 Detailed Agricultural Metrics Grid
                  _buildDetailedMetricsGrid(context, weather, l10n, isDark),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyOrLoading(
    BuildContext context,
    bool isLoading,
    AppLocalizations? l10n,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16.0),
            Text(
              l10n?.weatherToday ?? 'Loading Weather...',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        l10n?.weatherError ?? 'Unable to load weather details.',
        style: AppTypography.body,
      ),
    );
  }

  Widget _buildHeroWeatherCard(
    BuildContext context,
    WeatherData weather,
    AppLocalizations? l10n,
    String languageCode,
    bool isDark,
  ) {
    final condition = weather.localizedCondition(languageCode);
    final minTemp =
        weather.tempMin?.round() ?? (weather.temperature - 3).round();
    final maxTemp =
        weather.tempMax?.round() ?? (weather.temperature + 4).round();
    final feels = weather.feelsLike?.round() ?? weather.temperature.round();

    return Container(
      key: const ValueKey('weather_hero_card'),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A1E), const Color(0xFF112211)]
              : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(isDark ? 40 : 60),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: AppTypography.headline.copyWith(
                      fontSize: 44.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${l10n?.feelsLike ?? 'Feels like'} $feels°C',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13.0,
                      color: Colors.white.withAlpha(220),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  weather.weatherIcon,
                  size: 38.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Condition Pill Badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    condition,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // Min/Max Temperature
              Text(
                'L: $minTemp°C  •  H: $maxTemp°C',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withAlpha(230),
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSprayAdvisoryCard(
    BuildContext context,
    WeatherData weather,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    final isFavorable = weather.isSprayFavorable;

    final bgColor = isFavorable
        ? (isDark ? const Color(0xFF142914) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF331E14) : const Color(0xFFFFF3E0));

    final borderColor = isFavorable
        ? (isDark
              ? AppColors.primaryLight.withAlpha(80)
              : const Color(0xFFA5D6A7))
        : (isDark ? AppColors.warning.withAlpha(80) : const Color(0xFFFFCC80));

    final accentColor = isFavorable ? AppColors.success : AppColors.warning;

    final title = l10n?.sprayAdvisoryTitle ?? 'Farming Spray Advisory';
    final message = isFavorable
        ? (l10n?.sprayFavorable ??
              'Favorable conditions for field work & spraying')
        : (l10n?.sprayUnfavorable ??
              'Avoid spraying chemicals today (High rain/wind risk)');
    final subtitle = isFavorable
        ? (l10n?.sprayAdvisoryFavorableSubtitle ??
              'Wind < 20 km/h and low rain risk')
        : (l10n?.sprayAdvisoryUnfavorableSubtitle ??
              'High wind or rain may wash away chemicals');

    return Container(
      key: const ValueKey('weather_spray_advisory_card'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorable
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: accentColor,
              size: 26.0,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(isDark ? 60 : 35),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        isFavorable ? 'Favorable' : 'High Risk',
                        style: AppTypography.caption.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  message,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: isDark ? Colors.grey[200] : const Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySection(
    BuildContext context,
    WeatherData weather,
    AppLocalizations? l10n,
    String languageCode,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.hourlyForecast ?? '24-Hour Forecast',
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 16.0,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 10.0),
        SizedBox(
          height: 122.0,
          child: ListView.separated(
            key: const ValueKey('hourly_forecast_list'),
            scrollDirection: Axis.horizontal,
            itemCount: weather.hourlyForecast.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8.0),
            itemBuilder: (context, index) {
              final item = weather.hourlyForecast[index];
              final timeFormatted = DateFormat('h a').format(item.time);

              return Container(
                width: 72.0,
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 6.0,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: context.borderColor, width: 1.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeFormatted,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Icon(item.icon, size: 24.0, color: AppColors.primary),
                    Text(
                      '${item.temperature.round()}°',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.0,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (item.rainProbability > 0)
                      Text(
                        '${item.rainProbability}%',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1976D2),
                        ),
                      )
                    else
                      const SizedBox(height: 12.0),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailySection(
    BuildContext context,
    WeatherData weather,
    AppLocalizations? l10n,
    String languageCode,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.dailyForecast ?? '7-Day Forecast',
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 16.0,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          key: const ValueKey('daily_forecast_list'),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: context.borderColor, width: 1.0),
          ),
          child: Column(
            children: weather.dailyForecast.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == weather.dailyForecast.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        // Day Label
                        SizedBox(
                          width: 68.0,
                          child: Text(
                            item.localizedDayName(languageCode),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ),

                        // Icon
                        Icon(item.icon, size: 22.0, color: AppColors.primary),
                        const SizedBox(width: 8.0),

                        // Rain Chance
                        SizedBox(
                          width: 44.0,
                          child: item.rainProbability > 0
                              ? Text(
                                  '${item.rainProbability}%',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1976D2),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const Spacer(),

                        // Min - Max Range
                        Text(
                          '${item.minTemp.round()}°',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        // Range Bar Indicator
                        Container(
                          width: 60.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.0),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF81C784), Color(0xFFFFB74D)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        Text(
                          '${item.maxTemp.round()}°',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: context.borderColor,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetricsGrid(
    BuildContext context,
    WeatherData weather,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    final daylightStatus = weather.isDay == 1
        ? (l10n?.daytime ?? 'Daytime')
        : (l10n?.nighttime ?? 'Night');

    final uvText = weather.uvIndex != null
        ? '$daylightStatus (UV ${weather.uvIndex!.toStringAsFixed(1)})'
        : daylightStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agricultural Metrics',
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 16.0,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 10.0),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 1.6,
          children: [
            _buildMetricTile(
              context: context,
              icon: Icons.opacity_rounded,
              iconColor: const Color(0xFF1976D2),
              title: l10n?.humidity ?? 'Humidity',
              value: '${weather.humidity}%',
            ),
            _buildMetricTile(
              context: context,
              icon: Icons.air_rounded,
              iconColor: const Color(0xFF00897B),
              title: l10n?.wind ?? 'Wind Speed',
              value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
            ),
            _buildMetricTile(
              context: context,
              icon: Icons.umbrella_rounded,
              iconColor: const Color(0xFF5C6BC0),
              title: l10n?.rainChance ?? 'Rain Probability',
              value: '${weather.rainProbability}%',
            ),
            _buildMetricTile(
              context: context,
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFFFA000),
              title: l10n?.daylight ?? 'Daylight / UV',
              value: uvText,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon, size: 18.0, color: iconColor),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Center(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
