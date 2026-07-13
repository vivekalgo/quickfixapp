import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/core/services/hive_service.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

// Dynamic search configuration

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  String _query = '';
  String _selectedFilter = 'All'; // 'All', 'Services', 'Shops'
  List<String> _recentSearches = [];
  List<Shop> _searchResults = [];
  bool _isSearching = false;

  final List<String> _popularSuggestions = [
    'Sofa Cleaning',
    'AC Service',
    'Kitchen Cleaning',
    'Electrician',
    'Home Painting'
  ];

  @override
  void initState() {
    super.initState();
    _recentSearches = HiveService.getSearchHistory();
    // Auto-request focus on entrance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    try {
      final activeLocation = ref.read(currentAddressProvider);
      final repo = ref.read(homeRepositoryProvider);
      final results = await repo.searchShops(
        query: query,
        lat: activeLocation.latitude,
        lng: activeLocation.longitude,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
    });
    _performSearch(query);
  }

  void _triggerSearch(String query) {
    if (query.trim().isEmpty) return;
    AppHaptics.mediumTap();
    HiveService.addSearchQuery(query);
    setState(() {
      _query = query;
      _searchController.text = query;
      _recentSearches = HiveService.getSearchHistory();
    });
    _focusNode.unfocus();
    _performSearch(query);
  }

  void _clearSearch() {
    AppHaptics.lightTap();
    _searchController.clear();
    setState(() {
      _query = '';
    });
    _focusNode.requestFocus();
  }

  void _clearHistory() {
    AppHaptics.heavyTap();
    HiveService.clearSearchHistory();
    setState(() {
      _recentSearches = [];
    });
  }

  List<Shop> _getFilteredShops() {
    return _searchResults;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final results = _getFilteredShops();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            context.pop();
          },
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _triggerSearch,
                    decoration: const InputDecoration(
                      hintText: 'Search for sofa cleaning, AC fix...',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(Icons.close, color: AppColors.textSecondaryLight),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showVoiceSearchDialog(context, isDark),
                  child: const Icon(Icons.mic, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildSuggestionsLayout(isDark)
          : _buildSearchResultsLayout(results, isDark),
    );
  }

  // Suggestion screen layout shown when search is empty
  Widget _buildSuggestionsLayout(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: AppTextStyles.headingSmall(isDark),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textSecondaryLight),
                  onPressed: _clearHistory,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () => _triggerSearch(search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 6),
                        Text(
                          search,
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Popular Search suggestions
          Text(
            'Popular Services',
            style: AppTextStyles.headingSmall(isDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _triggerSearch(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        suggestion,
                        style: AppTextStyles.bodySmall(isDark).copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  // Layout rendered when filtering results
  Widget _buildSearchResultsLayout(List<Shop> results, bool isDark) {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_outlined,
                  color: AppColors.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No results found',
                style: AppTextStyles.headingMedium(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t find any service or shop matching "$_query". Check your spelling or try another keyword.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(isDark),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
    }

    return Column(
      children: [
        // Horizontal Filter Pill Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: ['All', 'Services', 'Shops'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (isDark ? Colors.white : AppColors.secondary) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? (isDark ? Colors.white : AppColors.secondary) 
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? (isDark ? AppColors.secondary : Colors.white) 
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Results List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    // Cache query to history first
                    HiveService.addSearchQuery(_query);
                    AppHaptics.mediumTap();
                    context.push('/shop/${item.id}', extra: item);
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.catPlumbing.withValues(alpha: isDark ? 0.15 : 1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: AppColors.catPlumbingIcon,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: AppTextStyles.headingSmall(isDark),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.categories.join(', '), style: AppTextStyles.bodySmall(isDark)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item.rating.toString(),
                                  style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.star, color: AppColors.success, size: 8),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${item.estimatedTimeDisplay} • ${item.distanceKm.toStringAsFixed(1)} km",
                            style: AppTextStyles.bodySmall(isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }

  // simulated Voice search overlay listening
  void _showVoiceSearchDialog(BuildContext context, bool isDark) {
    AppHaptics.heavyTap();
    Timer? dialogTimer;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        // Run simulation after a delay
        dialogTimer = Timer(const Duration(seconds: 3), () {
          if (dialogCtx.mounted) {
            Navigator.pop(dialogCtx);
            _triggerSearch('Deep Sofa Cleaning');
          }
        });
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Listening...',
                  style: AppTextStyles.headingMedium(isDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try saying "Deep Sofa Cleaning"',
                  style: AppTextStyles.bodyMedium(isDark),
                ),
                const SizedBox(height: 32),
                
                // Animated sound waves
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scaleY(
                        begin: 0.2, 
                        end: 1.2, 
                        duration: (400 + (index * 100)).ms, 
                        curve: Curves.easeInOut
                     );
                  }),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => dialogTimer?.cancel());
  }
}
