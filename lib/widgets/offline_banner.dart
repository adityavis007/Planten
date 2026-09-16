import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../providers/locale_provider.dart';
import '../services/network_monitor_service.dart';

/// A non-intrusive status banner indicating when the application is operating offline.
///
/// Complies with PRD Section 8, Section 13, and Task 54 specifications:
/// - Compact amber pill or strip layout.
/// - Informs farmers that AI inference functions 100% on-device without internet:
///   "Offline Mode — AI Diagnosis Works Normally" (EN) /
///   "ऑफलाइन मोड — एआई जांच चालू है" (HI).
/// - Reactively appears when [NetworkMonitorService.isOnline] is `false`
///   and automatically disappears when connection is restored.
/// - Designed with non-blocking touch behavior to ensure camera and scanning flows
///   remain completely uninterrupted.
class OfflineBanner extends StatelessWidget {
  /// Default English message per Task 54 specification.
  static const String defaultMessageEn =
      'Offline Mode — AI Diagnosis Works Normally';

  /// Default Vernacular Hindi message per Task 54 specification.
  static const String defaultMessageHi =
      'ऑफलाइन मोड — एआई जांच चालू है';

  /// Optional injected [NetworkMonitorService] instance.
  final NetworkMonitorService? networkMonitorService;

  /// Optional explicit online state override for testing or manual state control.
  final bool? isOnlineOverride;

  /// Optional injected [LocaleProvider] for testing.
  final LocaleProvider? localeProvider;

  /// Optional custom message override to display in the banner.
  final String? customMessage;

  /// Whether to render as a floating compact rounded pill (true) or full-width strip (false).
  final bool isPill;

  /// Optional animation duration for smooth appear/disappear transitions.
  final Duration animationDuration;

  const OfflineBanner({
    super.key,
    this.networkMonitorService,
    this.isOnlineOverride,
    this.localeProvider,
    this.customMessage,
    this.isPill = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  NetworkMonitorService? _getServiceFromContext(BuildContext context) {
    if (networkMonitorService != null) return networkMonitorService;
    try {
      return Provider.of<NetworkMonitorService>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  LocaleProvider? _getLocaleProvider(BuildContext context) {
    if (localeProvider != null) return localeProvider;
    try {
      return Provider.of<LocaleProvider>(context);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isOnlineOverride != null) {
      return _buildContent(context, isOnlineOverride!);
    }

    final service = networkMonitorService ?? _getServiceFromContext(context);
    if (service != null) {
      return StreamBuilder<bool>(
        stream: service.isOnlineStream,
        initialData: service.isOnline,
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? service.isOnline;
          return _buildContent(context, isOnline);
        },
      );
    }

    return _buildContent(context, true);
  }

  Widget _buildContent(BuildContext context, bool isOnline) {
    if (isOnline) {
      return const SizedBox.shrink();
    }

    final activeLocaleProvider = _getLocaleProvider(context);
    final isHindi = Localizations.localeOf(context).languageCode == 'hi' ||
        (activeLocaleProvider?.isHindi ?? false);

    final message = customMessage ??
        (isHindi ? OfflineBanner.defaultMessageHi : OfflineBanner.defaultMessageEn);

    return _buildBannerContainer(context, message, isHindi);
  }

  Widget _buildBannerContainer(
    BuildContext context,
    String message,
    bool isHindi,
  ) {
    return Container(
      key: const Key('offline_banner_container'),
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: widgetPillVerticalPadding,
      ),
      child: isPill
          ? _buildPill(context, message)
          : _buildStrip(context, message),
    );
  }

  double get widgetPillVerticalPadding => isPill ? 6.0 : 8.0;

  /// Compact rounded pill variant (PRD default)
  Widget _buildPill(BuildContext context, String message) {
    return Container(
      key: const Key('offline_banner_pill'),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Soft warm amber container
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: AppColors.warning,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFE65100), // Deep amber for outdoor contrast
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              message,
              key: const Key('offline_banner_text'),
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFE65100),
                fontWeight: FontWeight.w700,
                fontSize: 12.0,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width strip variant
  Widget _buildStrip(BuildContext context, String message) {
    return Container(
      key: const Key('offline_banner_strip'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              key: const Key('offline_banner_text'),
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
