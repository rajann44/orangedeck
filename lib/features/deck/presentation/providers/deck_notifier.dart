import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../shared/data/hive_persistence_service.dart';
import '../../domain/models/story_filter.dart';
import '../../../../shared/domain/models/article.dart';
import '../../data/deck_repository.dart';
import '../../data/hn_api_service.dart';

class DeckState {
  final List<Article> cards;
  final bool isLoading;
  final String? errorMessage;
  final List<int> allFeedIds;
  final int currentFeedIndex;
  final List<Article> swipeHistory;
  final bool isOffline;

  DeckState({
    required this.cards,
    required this.isLoading,
    this.errorMessage,
    required this.allFeedIds,
    required this.currentFeedIndex,
    this.swipeHistory = const [],
    this.isOffline = false,
  });

  DeckState copyWith({
    List<Article>? cards,
    bool? isLoading,
    String? errorMessage,
    List<int>? allFeedIds,
    int? currentFeedIndex,
    List<Article>? swipeHistory,
    bool? isOffline,
  }) {
    return DeckState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      allFeedIds: allFeedIds ?? this.allFeedIds,
      currentFeedIndex: currentFeedIndex ?? this.currentFeedIndex,
      swipeHistory: swipeHistory ?? this.swipeHistory,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// Network and Service Singletons
final dioProvider = Provider<Dio>((ref) => Dio());

final apiServiceProvider = Provider<HnApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return HnApiService(dio);
});

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return DeckRepository(api);
});

final persistenceServiceProvider = Provider<HivePersistenceService>((ref) {
  return HivePersistenceService();
});

// Currently selected feed category filter
final selectedFilterProvider = StateProvider<StoryFilter>((ref) => StoryFilter.top);

// StateNotifierProvider that dynamically watches selectedFilterProvider
final deckNotifierProvider = StateNotifierProvider.autoDispose<DeckNotifier, DeckState>((ref) {
  final repository = ref.watch(deckRepositoryProvider);
  final apiService = ref.watch(apiServiceProvider);
  final persistence = ref.watch(persistenceServiceProvider);
  final filter = ref.watch(selectedFilterProvider);
  
  return DeckNotifier(repository, apiService, persistence, filter);
});

class DeckNotifier extends StateNotifier<DeckState> {
  final DeckRepository _repository;
  final HnApiService _apiService;
  final HivePersistenceService _persistenceService;
  final StoryFilter _filter;
  
  // Set to keep track of items dismissed in the current session
  final Set<int> _dismissedIds = {};

  static const int _batchSize = 15;

  DeckNotifier(this._repository, this._apiService, this._persistenceService, this._filter)
      : super(DeckState(cards: [], isLoading: true, allFeedIds: [], currentFeedIndex: 0)) {
    loadFeed();
  }

  /// Fetches story IDs from HN and starts fetching details for the first batch
  Future<void> loadFeed() async {
    print('DEBUG: loadFeed() started for filter: ${_filter.apiKey}');
    state = state.copyWith(isLoading: true, errorMessage: null, cards: [], swipeHistory: [], isOffline: false);
    try {
      final ids = await _apiService.fetchStoryIds(_filter.apiKey);
      print('DEBUG: loadFeed() successfully fetched ${ids.length} story IDs.');
      _dismissedIds.clear();

      if (ids.isEmpty) {
        state = state.copyWith(cards: [], isLoading: false, allFeedIds: []);
        return;
      }

      state = state.copyWith(allFeedIds: ids, currentFeedIndex: 0);
      await fetchNextBatch();
    } catch (e) {
      print('DEBUG: loadFeed() failed with error: $e. Falling back to cached stories.');
      // Offline fallback: load from cached box!
      final cachedArticles = _persistenceService.fetchCachedArticles();
      
      // Filter out already processed items in current session
      final filtered = cachedArticles.where((a) => !_dismissedIds.contains(a.id)).toList();
      
      if (filtered.isNotEmpty) {
        state = state.copyWith(
          cards: filtered,
          allFeedIds: filtered.map((a) => a.id).toList(),
          currentFeedIndex: filtered.length,
          isLoading: false,
          isOffline: true,
          errorMessage: null, // Clear error since we have a fallback
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Offline. No cached stories available.',
          isOffline: true,
        );
      }
    }
  }

  /// Fetches the details for the next chunk of IDs from the active feed
  Future<void> fetchNextBatch() async {
    print('DEBUG: fetchNextBatch() started. Current index: ${state.currentFeedIndex}, Total IDs: ${state.allFeedIds.length}');
    if (state.currentFeedIndex >= state.allFeedIds.length) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final end = (state.currentFeedIndex + _batchSize).clamp(0, state.allFeedIds.length);
    final batchIds = state.allFeedIds.sublist(state.currentFeedIndex, end);
    print('DEBUG: fetchNextBatch() loading items for IDs: $batchIds');

    try {
      final newArticles = await _repository.fetchArticlesBatch(batchIds);
      print('DEBUG: fetchNextBatch() retrieved ${newArticles.length} articles from repository.');
      
      // Cache these fetched articles for offline fallback
      await _persistenceService.cacheArticles(newArticles);
      
      // Deduplicate against currently swiped or in-stack cards
      final filtered = newArticles.where((article) {
        final inStack = state.cards.any((card) => card.id == article.id);
        return !_dismissedIds.contains(article.id) && !inStack;
      }).toList();
      print('DEBUG: fetchNextBatch() filtered down to ${filtered.length} new cards.');

      state = state.copyWith(
        cards: [...state.cards, ...filtered],
        currentFeedIndex: end,
        isLoading: false,
      );
    } catch (e) {
      print('DEBUG: fetchNextBatch() failed with error: $e');
      // If error occurs and we already have cards in the stack, don't crash, just log error.
      if (state.cards.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Removes card from the top of the stack and handles queue buffer checks
  void popCard(int id) {
    // Find the article we are popping
    final poppedArticleIndex = state.cards.indexWhere((article) => article.id == id);
    if (poppedArticleIndex != -1) {
      final poppedArticle = state.cards[poppedArticleIndex];
      // Push to history
      final newHistory = List<Article>.from(state.swipeHistory)..add(poppedArticle);
      if (newHistory.length > 10) {
        newHistory.removeAt(0); // Limit to last 10 items
      }
      _dismissedIds.add(id);
      final updated = List<Article>.from(state.cards)..removeAt(poppedArticleIndex);
      state = state.copyWith(cards: updated, swipeHistory: newHistory);
    } else {
      _dismissedIds.add(id);
      final updated = List<Article>.from(state.cards)..removeWhere((article) => article.id == id);
      state = state.copyWith(cards: updated);
    }

    // Prefetch next items when active card count is low (buffer of 4 items)
    if (state.cards.length < 4 && !state.isLoading) {
      fetchNextBatch();
    }
  }

  /// Restores the last swiped card from history to the top of the stack
  void undoSwipe() {
    if (state.swipeHistory.isEmpty) return;

    final restored = state.swipeHistory.last;
    final newHistory = List<Article>.from(state.swipeHistory)..removeLast();
    _dismissedIds.remove(restored.id);

    state = state.copyWith(
      cards: [restored, ...state.cards],
      swipeHistory: newHistory,
    );
  }
}
