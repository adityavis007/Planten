import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../models/crop.dart';
import '../../models/diagnosis_result.dart';
import '../../providers/history_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/scan_history_card.dart';

/// Screen presenting past leaf diagnosis history with horizontal crop filter chips,
/// date-grouped scan cards, and review mode navigation.
///
/// Features:
/// - Horizontal scrollable filter bar ("All Crops", "Tomato", "Wheat", "Potato", etc.).
/// - Chronologically grouped list of [ScanHistoryCard] items (Today, Yesterday, or formatted date).
/// - Clean agricultural empty state with actionable scan CTA.
/// - Tap-to-review opening [ResultScreen] with the complete diagnosis and guidance.
/// - Offline sync status badge highlighting pending local scans.
class HistoryScreen extends StatefulWidget {
  /// Callback when a scan card is tapped to open review mode.
  final void Function(DiagnosisResult scan)? onScanTap;

  /// Callback when the empty state "Scan Leaf" button is tapped.
  final VoidCallback? onScanCtaTap;

  /// Optional [HistoryProvider] instance override for isolated testing.
  final HistoryProvider? historyProviderOverride;

  const HistoryScreen({
    super.key,
    this.onScanTap,
    this.onScanCtaTap,
    this.historyProviderOverride,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryProvider? _internalProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = _resolveProvider(context, listen: false);
      provider.loadHistory();
    });
  }

  @override
  void dispose() {
    _internalProvider?.dispose();
    super.dispose();
  }

  HistoryProvider _resolveProvider(
    BuildContext context, {
    bool listen = false,
  }) {
    if (widget.historyProviderOverride != null) {
      return widget.historyProviderOverride!;
    }
    try {
      final fromContext = Provider.of<HistoryProvider?>(
        context,
        listen: listen,
      );
      if (fromContext != null) {
        return fromContext;
      }
    } catch (_) {}

    return _internalProvider ??= HistoryProvider(autoLoad: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final isHindi = langCode == 'hi';

    final historyProvider = _resolveProvider(context, listen: true);

    return ListenableBuilder(
      listenable: historyProvider,
      builder: (context, _) =>
          _buildScaffold(context, historyProvider, l10n, langCode, isHindi),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    HistoryProvider? historyProvider,
    AppLocalizations? l10n,
    String langCode,
    bool isHindi,
  ) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarBgColor,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(25),
        title: Text(
          l10n?.historyTitle ?? (isHindi ? 'जांच इतिहास' : 'Scan History'),
          style: AppTypography.headline.copyWith(
            fontSize: 20.0,
            color: context.isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          if (historyProvider != null && historyProvider.hasUnsyncedScans)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  key: const ValueKey('unsynced_scans_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: AppColors.warning.withAlpha(120),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_queue_rounded,
                        size: 14.0,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${historyProvider.unsyncedCount} ${isHindi ? 'बाकी' : 'pending'}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (historyProvider != null && historyProvider.allScans.isNotEmpty)
            IconButton(
              key: const ValueKey('clear_all_history_button'),
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip:
                  l10n?.clearHistory ??
                  (isHindi ? 'सारा इतिहास हटाएं' : 'Clear All History'),
              color: AppColors.error,
              onPressed: () =>
                  _confirmClearAll(context, historyProvider, l10n, isHindi),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Crop Filter Bar
            _buildCropFilterBar(
              context,
              historyProvider,
              l10n,
              langCode,
              isHindi,
            ),

            Divider(height: 1.0, thickness: 0.8, color: context.borderColor),

            // Body: Grouped List or Empty State
            Expanded(
              child: _buildBody(
                context,
                historyProvider,
                l10n,
                langCode,
                isHindi,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontally scrollable row of crop filter chips ("All Crops", "Tomato", "Wheat", etc.).
  Widget _buildCropFilterBar(
    BuildContext context,
    HistoryProvider? provider,
    AppLocalizations? l10n,
    String langCode,
    bool isHindi,
  ) {
    final activeFilter = provider?.activeFilterCropId?.toLowerCase();

    return Container(
      color: context.surfaceColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // "All Crops" Filter Chip
            _buildFilterChip(
              context: context,
              key: const ValueKey('crop_filter_all'),
              label: l10n?.allCrops ?? (isHindi ? 'सभी फसलें' : 'All Crops'),
              isSelected: activeFilter == null,
              onTap: () => provider?.filterByCrop(null),
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(width: 8.0),

            // Individual Crop Filter Chips
            ...Crop.initialCrops.map((crop) {
              final isSelected = activeFilter == crop.id.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildFilterChip(
                  context: context,
                  key: ValueKey('crop_filter_${crop.id}'),
                  label: crop.localizedName(langCode),
                  isSelected: isSelected,
                  onTap: () => provider?.filterByCrop(crop.id),
                  icon: Icons.grass_rounded,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Single selectable filter chip with rich tactile styling.
  Widget _buildFilterChip({
    required BuildContext context,
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: isSelected ? AppColors.primary : context.surfaceColor,
      elevation: isSelected ? 1.5 : 0.0,
      shadowColor: AppColors.primary.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.borderColor,
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15.0,
                  color: isSelected ? Colors.white : context.textSecondaryColor,
                ),
                const SizedBox(width: 6.0),
              ],
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? Colors.white : context.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the body content: empty state or date-grouped list.
  Widget _buildBody(
    BuildContext context,
    HistoryProvider? provider,
    AppLocalizations? l10n,
    String langCode,
    bool isHindi,
  ) {
    if (provider == null || provider.isEmpty) {
      return _buildEmptyState(context, provider, l10n, langCode, isHindi);
    }

    final groupedScans = _groupScansByDate(provider.scans, langCode, isHindi);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => provider.loadHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
        itemCount: groupedScans.length,
        itemBuilder: (context, index) {
          final group = groupedScans[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              _buildDateHeader(
                context,
                group.dateLabel,
                group.scans.length,
                isHindi,
              ),
              const SizedBox(height: 8.0),

              // Scan History Cards
              ...group.scans.map(
                (scan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: ValueKey('dismissible_scan_${scan.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _showDeleteConfirmationDialog(
                      context,
                      scan,
                      l10n,
                      isHindi,
                    ),
                    onDismissed: (_) async {
                      await provider.deleteScan(scan.id);
                      if (context.mounted) {
                        _showDeletedSnackBar(context, l10n, isHindi);
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            l10n?.delete ?? (isHindi ? 'हटाएं' : 'Delete'),
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.white,
                            size: 24.0,
                          ),
                        ],
                      ),
                    ),
                    child: ScanHistoryCard(
                      scan: scan,
                      languageCode: langCode,
                      onTap: () => _handleScanTap(scan),
                      onDelete: () async {
                        final confirmed = await _showDeleteConfirmationDialog(
                          context,
                          scan,
                          l10n,
                          isHindi,
                        );
                        if (confirmed == true) {
                          await provider.deleteScan(scan.id);
                          if (context.mounted) {
                            _showDeletedSnackBar(context, l10n, isHindi);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          );
        },
      ),
    );
  }

  /// Formats date header with scan count badge.
  Widget _buildDateHeader(
    BuildContext context,
    String dateLabel,
    int count,
    bool isHindi,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: AppTypography.sectionTitle.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              '$count ${isHindi ? 'स्कैन' : (count == 1 ? 'scan' : 'scans')}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean agricultural empty state with actionable scan CTA.
  Widget _buildEmptyState(
    BuildContext context,
    HistoryProvider? provider,
    AppLocalizations? l10n,
    String langCode,
    bool isHindi,
  ) {
    final activeCropId = provider?.activeFilterCropId;
    final String emptyTitle;
    final String emptySubtitle;

    if (activeCropId != null) {
      final cropName = _resolveCropName(activeCropId, langCode);
      emptyTitle =
          l10n?.noHistoryForCrop(cropName) ??
          (isHindi
              ? '$cropName के लिए कोई पिछला स्कैन मौजूद नहीं है।'
              : 'No scans recorded yet for $cropName.');
      emptySubtitle = isHindi
          ? 'इस फसल की पत्ती की फोटो लें और तुरंत रोग निदान प्राप्त करें।'
          : 'Capture a leaf photo to diagnose diseases for this crop.';
    } else {
      emptyTitle = isHindi
          ? 'कोई पिछला स्कैन मौजूद नहीं है'
          : 'No Scan History Yet';
      emptySubtitle = isHindi
          ? 'अपनी फसल की पत्तियों की जांच करने के लिए नया स्कैन करें।'
          : 'Tap Scan to diagnose your first crop leaf and protect your harvest.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular illustration container
            Container(
              key: const ValueKey('empty_history_icon'),
              width: 96.0,
              height: 96.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(50),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.spa_rounded,
                size: 48.0,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20.0),

            // Title
            Text(
              emptyTitle,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8.0),

            // Subtitle
            Text(
              emptySubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: context.textSecondaryColor,
                fontSize: 14.0,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28.0),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                key: const ValueKey('empty_state_scan_button'),
                text:
                    l10n?.scanLeafCta ??
                    (isHindi ? 'पत्ती की जांच करें' : 'Scan Leaf for Disease'),
                leadingIcon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20.0,
                ),
                onPressed: _handleScanCta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Groups sorted scans by calendar day.
  List<({String dateLabel, List<DiagnosisResult> scans})> _groupScansByDate(
    List<DiagnosisResult> scans,
    String langCode,
    bool isHindi,
  ) {
    final groups = <String, List<DiagnosisResult>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final scan in scans) {
      final scanDay = DateTime(
        scan.timestamp.year,
        scan.timestamp.month,
        scan.timestamp.day,
      );
      final String label;

      if (scanDay.isAtSameMomentAs(today)) {
        label = isHindi ? 'आज' : 'Today';
      } else if (scanDay.isAtSameMomentAs(yesterday)) {
        label = isHindi ? 'कल' : 'Yesterday';
      } else {
        label = DateFormat('dd MMMM yyyy').format(scan.timestamp);
      }

      groups.putIfAbsent(label, () => []).add(scan);
    }

    return groups.entries
        .map((e) => (dateLabel: e.key, scans: e.value))
        .toList();
  }

  /// Helper to resolve localized crop name from ID.
  String _resolveCropName(String cropId, String langCode) {
    final crop = Crop.initialCrops.firstWhere(
      (c) => c.id.toLowerCase() == cropId.toLowerCase(),
      orElse: () => Crop(
        id: cropId,
        nameEn: cropId.isNotEmpty
            ? cropId[0].toUpperCase() + cropId.substring(1)
            : 'Crop',
        nameHi: cropId,
        iconAssetPath: 'assets/icons/crops/tomato.png',
      ),
    );
    return crop.localizedName(langCode);
  }

  /// Reopens scan in review mode on [ResultScreen].
  void _handleScanTap(DiagnosisResult scan) {
    if (widget.onScanTap != null) {
      widget.onScanTap!(scan);
      return;
    }
    try {
      context.push(AppRoutes.result, extra: scan);
    } catch (_) {}
  }

  /// Triggers scan camera workflow.
  void _handleScanCta() {
    if (widget.onScanCtaTap != null) {
      widget.onScanCtaTap!();
      return;
    }
    try {
      context.push(AppRoutes.scan);
    } catch (_) {
      try {
        context.go(AppRoutes.scan);
      } catch (_) {}
    }
  }

  /// Displays confirmation dialog to safely delete an individual scan.
  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    DiagnosisResult scan,
    AppLocalizations? l10n,
    bool isHindi,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.deleteScan ?? (isHindi ? 'स्कैन हटाएं' : 'Delete Scan'),
                style: AppTypography.headline.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          l10n?.deleteScanConfirm ??
              (isHindi
                  ? 'क्या आप वाकई इस स्कैन रिकॉर्ड को हटाना चाहते हैं?'
                  : 'Are you sure you want to delete this scan record?'),
          style: AppTypography.body.copyWith(
            color: dialogContext.textSecondaryColor,
            fontSize: 14.5,
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_delete_scan_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n?.cancel ?? (isHindi ? 'रद्द करें' : 'Cancel'),
              style: TextStyle(color: dialogContext.textSecondaryColor),
            ),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_scan_button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n?.delete ?? (isHindi ? 'हटाएं' : 'Delete')),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Displays temporary floating SnackBar after an individual scan is deleted.
  void _showDeletedSnackBar(
    BuildContext context,
    AppLocalizations? l10n,
    bool isHindi,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.scanDeleted ??
              (isHindi
                  ? 'स्कैन सफलतापूर्वक हटा दिया गया'
                  : 'Scan deleted successfully'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Prompts farmer confirmation before permanently clearing all scan records.
  Future<void> _confirmClearAll(
    BuildContext context,
    HistoryProvider provider,
    AppLocalizations? l10n,
    bool isHindi,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.error,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.clearHistory ??
                    (isHindi ? 'सारा इतिहास हटाएं' : 'Clear All History'),
                style: AppTypography.headline.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          l10n?.clearHistoryConfirm ??
              (isHindi
                  ? 'क्या आप वाकई सभी स्कैन रिकॉर्ड हटाना चाहते हैं? यह क्रिया वापस नहीं ली जा सकती।'
                  : 'Are you sure you want to delete all scan history? This action cannot be undone.'),
          style: AppTypography.body.copyWith(
            color: dialogContext.textSecondaryColor,
            fontSize: 14.5,
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_clear_all_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n?.cancel ?? (isHindi ? 'रद्द करें' : 'Cancel'),
              style: TextStyle(color: dialogContext.textSecondaryColor),
            ),
          ),
          FilledButton(
            key: const ValueKey('confirm_clear_all_button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n?.clearHistory ??
                  (isHindi ? 'सारा इतिहास हटाएं' : 'Clear All History'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.historyCleared ??
                  (isHindi
                      ? 'सारा स्कैन इतिहास हटा दिया गया'
                      : 'All scan history cleared'),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
