import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/crop.dart';
import '../../models/diagnosis_result.dart';
import '../../models/treatment_guidance.dart';
import '../../services/history_service.dart';
import '../../services/knowledge_base_service.dart';
import '../../widgets/treatment_guidance_view.dart';

/// Full-featured, offline-ready search screen for Planten (AI Crop Doctor).
///
/// Features:
/// - Sectioned results:
///   1. Past scan records from [HistoryService].
///   2. Verified disease & treatment guidance from [KnowledgeBaseService].
/// - Instant search across crop names, disease names (EN & Hindi), and symptoms.
/// - Farmer-friendly empty state with quick suggestion chips.
/// - Clear "No results found" state with actionable hints.
/// - Tap handlers to view full scan diagnosis report or treatment guidance modal.
class SearchScreen extends StatefulWidget {
  /// Optional injected [HistoryService] for dependency injection and testing.
  final HistoryService? historyService;

  /// Optional injected [KnowledgeBaseService] for dependency injection and testing.
  final KnowledgeBaseService? knowledgeBaseService;

  const SearchScreen({
    super.key,
    this.historyService,
    this.knowledgeBaseService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  late final HistoryService _historyService;
  late final KnowledgeBaseService _knowledgeBaseService;

  String _query = '';
  List<DiagnosisResult> _matchingScans = [];
  List<TreatmentGuidance> _matchingGuidance = [];
  bool _isSearching = false;

  final List<String> _popularSuggestionsEn = [
    'Tomato',
    'Early Blight',
    'Late Blight',
    'Wheat Rust',
    'Potato',
    'Cotton',
  ];

  final List<String> _popularSuggestionsHi = [
    'टमाटर',
    'अगेती झुलसा',
    'पछेती झुलसा',
    'गेहूं का रतुआ',
    'आलू',
    'कपास',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _historyService = widget.historyService ?? HistoryService();
    _knowledgeBaseService =
        widget.knowledgeBaseService ?? KnowledgeBaseService();
    _initKnowledgeBase();
  }

  Future<void> _initKnowledgeBase() async {
    if (!_knowledgeBaseService.isInitialized) {
      await _knowledgeBaseService.init();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    setState(() {
      _query = trimmed;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _matchingScans = [];
        _matchingGuidance = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    await _initKnowledgeBase();

    final scans = await _historyService.searchScans(trimmed);
    final guidance = _knowledgeBaseService.search(trimmed);

    if (mounted) {
      setState(() {
        _matchingScans = scans;
        _matchingGuidance = guidance;
        _isSearching = false;
      });
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _performSearch(suggestion);
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isHindi = languageCode == 'hi';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.appBarBgColor,
        elevation: 0,
        title: Text(
          isHindi ? 'खोजें' : 'Search',
          style: AppTypography.headline.copyWith(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
            color: context.surfaceColor,
            child: TextField(
              key: const ValueKey('search_input_field'),
              controller: _searchController,
              onChanged: _performSearch,
              textInputAction: TextInputAction.search,
              style: AppTypography.body.copyWith(
                color: context.textPrimaryColor,
                fontSize: 15.0,
              ),
              decoration: InputDecoration(
                hintText: isHindi
                    ? 'फसल, रोग या लक्षण खोजें...'
                    : 'Search crop, disease, or symptoms...',
                hintStyle: AppTypography.body.copyWith(
                  color: context.textSecondaryColor.withAlpha(160),
                  fontSize: 14.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22.0,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        key: const ValueKey('search_clear_button'),
                        icon: const Icon(Icons.close_rounded, size: 20.0),
                        color: context.textSecondaryColor,
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: context.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: context.borderColor,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: context.borderColor,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Search Body
          Expanded(child: _buildSearchContent(context, isHindi, languageCode)),
        ],
      ),
    );
  }

  Widget _buildSearchContent(
    BuildContext context,
    bool isHindi,
    String languageCode,
  ) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_query.isEmpty) {
      return _buildEmptyState(context, isHindi);
    }

    if (_matchingScans.isEmpty && _matchingGuidance.isEmpty) {
      return _buildNoResultsState(context, isHindi);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      children: [
        // Section 1: Past Scans
        if (_matchingScans.isNotEmpty) ...[
          _buildSectionHeader(
            context: context,
            icon: Icons.history_rounded,
            title: isHindi
                ? 'पिछली जांच का इतिहास (${_matchingScans.length})'
                : 'Past Scan History (${_matchingScans.length})',
          ),
          const SizedBox(height: 8.0),
          ..._matchingScans.map(
            (scan) =>
                _buildScanResultCard(context, scan, languageCode, isHindi),
          ),
          const SizedBox(height: 16.0),
        ],

        // Section 2: Knowledge Base
        if (_matchingGuidance.isNotEmpty) ...[
          _buildSectionHeader(
            context: context,
            icon: Icons.menu_book_rounded,
            title: isHindi
                ? 'रोग ज्ञान व उपचार सलाह (${_matchingGuidance.length})'
                : 'Crop Knowledge & Care (${_matchingGuidance.length})',
          ),
          const SizedBox(height: 8.0),
          ..._matchingGuidance.map(
            (guidance) => _buildGuidanceResultCard(
              context,
              guidance,
              languageCode,
              isHindi,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isHindi) {
    final suggestions = isHindi ? _popularSuggestionsHi : _popularSuggestionsEn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20.0),
          Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.search_rounded,
                size: 40.0,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            isHindi ? 'फसल डॉक्टर में खोजें' : 'Search Crop Doctor',
            style: AppTypography.headline.copyWith(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            isHindi ? 'फसल, रोग, लक्षण या अपनी पिछली जांच रिपोर्ट खोजें।' : 'Find disease treatments, cultural care advice, or review your past scan reports.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: context.textSecondaryColor,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isHindi ? 'लोकप्रिय खोजें' : 'Popular Searches',
              style: AppTypography.sectionTitle.copyWith(
                fontSize: 14.0,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: suggestions.map((term) {
              return ActionChip(
                backgroundColor: context.surfaceColor,
                side: BorderSide(color: context.borderColor, width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                label: Text(
                  term,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
                onPressed: () => _onSuggestionTap(term),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56.0,
              color: AppColors.textSecondary.withAlpha(140),
            ),
            const SizedBox(height: 16.0),
            Text(
              isHindi ? 'कोई परिणाम नहीं मिला' : 'No matching results found',
              style: AppTypography.headline.copyWith(
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isHindi
                  ? 'कृपया फसल का नाम (जैसे टमाटर, गेहूं) या रोग का लक्षण बदलकर पुनः खोजें।'
                  : 'Try searching with different keywords, crop names (e.g. Tomato, Wheat), or disease symptoms.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: context.textSecondaryColor,
                fontSize: 13.0,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.0, color: AppColors.primary),
        const SizedBox(width: 8.0),
        Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildScanResultCard(
    BuildContext context,
    DiagnosisResult scan,
    String languageCode,
    bool isHindi,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(scan.timestamp);
    final diseaseTitle = isHindi ? scan.diseaseNameHi : scan.diseaseNameEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 1.0,
      shadowColor: Colors.black.withAlpha(20),
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          context.push(AppRoutes.result, extra: scan);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Leaf Thumbnail / Icon
              _buildScanThumbnail(scan),
              const SizedBox(width: 12.0),

              // Title, Crop, and Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3.0),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            scan.crop.localizedName(languageCode),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Confidence badge / arrow
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanThumbnail(DiagnosisResult scan) {
    if (scan.localImagePath.isNotEmpty) {
      final file = File(scan.localImagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.file(
            file,
            width: 44.0,
            height: 44.0,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildDefaultThumbnail(),
          ),
        );
      }
    }

    if (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          scan.remoteImageUrl!,
          width: 44.0,
          height: 44.0,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildDefaultThumbnail(),
        ),
      );
    }

    return _buildDefaultThumbnail();
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 44.0,
      height: 44.0,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 24.0),
      ),
    );
  }

  Widget _buildGuidanceResultCard(
    BuildContext context,
    TreatmentGuidance guidance,
    String languageCode,
    bool isHindi,
  ) {
    final title = isHindi ? guidance.nameHi : guidance.nameEn;
    final symptoms = isHindi ? guidance.symptomsHi : guidance.symptomsEn;
    final crop = Crop.fromId(guidance.crop);

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 1.0,
      shadowColor: Colors.black.withAlpha(20),
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: context.borderColor, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _showGuidanceBottomSheet(context, guidance, languageCode),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      crop.localizedName(languageCode),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13.0,
                    color: context.textSecondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                symptoms,
                style: AppTypography.body.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: 12.5,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 14.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    isHindi
                        ? '${guidance.culturalStepsHi.length} रोकथाम उपाय उपलब्ध'
                        : '${guidance.culturalStepsEn.length} cultural actions',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
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

  void _showGuidanceBottomSheet(
    BuildContext context,
    TreatmentGuidance guidance,
    String languageCode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                    child: TreatmentGuidanceView(
                      guidance: guidance,
                      languageCode: languageCode,
                      initialExpandSymptoms: true,
                      initialExpandPrevention: true,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
