import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/article.dart';
import '../../../../shared/data/hive_persistence_service.dart';
import '../../../deck/presentation/providers/deck_notifier.dart';

final savedArticlesProvider = StateNotifierProvider<SavedNotifier, List<Article>>((ref) {
  final persistenceService = ref.watch(persistenceServiceProvider);
  return SavedNotifier(persistenceService);
});

class SavedNotifier extends StateNotifier<List<Article>> {
  final HivePersistenceService _persistenceService;

  SavedNotifier(this._persistenceService) : super([]) {
    loadSavedArticles();
  }

  /// Loads saved articles from Hive storage and updates local state.
  void loadSavedArticles() {
    state = _persistenceService.fetchSavedArticles();
  }

  /// Saves an article locally and updates the list state.
  Future<void> saveArticle(Article article) async {
    await _persistenceService.saveArticle(article);
    loadSavedArticles();
  }

  /// Deletes an article locally and updates the list state.
  Future<void> deleteArticle(int id) async {
    await _persistenceService.deleteArticle(id);
    loadSavedArticles();
  }

  /// Undo delete operation by re-saving the deleted article.
  Future<void> undoDelete(Article article) async {
    await _persistenceService.saveArticle(article);
    loadSavedArticles();
  }
}
