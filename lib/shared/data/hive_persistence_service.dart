import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/article.dart';

class HivePersistenceService {
  static const String _boxName = 'saved_articles_box';
  static const String _cacheBoxName = 'cached_articles_box';
  static const String _settingsBoxName = 'settings_box';

  /// Initializes Hive and opens the boxes for saved, cached articles, and settings.
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_boxName);
    await Hive.openBox<dynamic>(_cacheBoxName);
    await Hive.openBox<dynamic>(_settingsBoxName);
  }

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);
  Box<dynamic> get _cacheBox => Hive.box<dynamic>(_cacheBoxName);
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(_settingsBoxName);

  /// Saves an article locally, appending a timestamp for chronological sorting.
  Future<void> saveArticle(Article article) async {
    final updatedArticle = article.copyWith(
      savedAt: DateTime.now(),
    );
    await _box.put(article.id.toString(), updatedArticle.toJson());
  }

  /// Deletes an article from local storage.
  Future<void> deleteArticle(int id) async {
    await _box.delete(id.toString());
  }

  /// Retrieves all saved articles, sorted chronologically with newest saved first.
  List<Article> fetchSavedArticles() {
    try {
      final List<Article> items = _box.values
          .map((dynamic value) {
            final map = Map<String, dynamic>.from(value as Map);
            return Article.fromJson(map);
          })
          .toList();

      items.sort((a, b) {
        final aTime = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // descending order
      });
      
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Checks if an article is already saved locally.
  bool isArticleSaved(int id) {
    return _box.containsKey(id.toString());
  }

  /// Caches a list of articles for offline fallback.
  Future<void> cacheArticles(List<Article> articles) async {
    try {
      final Map<String, dynamic> entries = {};
      for (final article in articles) {
        entries[article.id.toString()] = article.toJson();
      }
      if (entries.isNotEmpty) {
        await _cacheBox.putAll(entries);
      }
    } catch (e) {
      debugPrint('DEBUG: cacheArticles failed with error: $e');
    }
  }

  /// Retrieves all cached articles for offline viewing.
  List<Article> fetchCachedArticles() {
    try {
      final List<Article> items = _cacheBox.values
          .map((dynamic value) {
            final map = Map<String, dynamic>.from(value as Map);
            return Article.fromJson(map);
          })
          .toList();
      // Sort by time descending (newest first)
      items.sort((a, b) => b.time.compareTo(a.time));
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Persists the user's selected theme mode preference.
  Future<void> saveThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
  }

  /// Fetches the persisted theme mode, defaulting to 'system'.
  String getThemeMode() {
    return _settingsBox.get('theme_mode', defaultValue: 'system') as String;
  }

  /// Persists the user's selected accent color ARGB integer value.
  Future<void> saveAccentColor(int colorValue) async {
    await _settingsBox.put('accent_color', colorValue);
  }

  /// Fetches the persisted accent color value, or null if not yet customized.
  int? getAccentColor() {
    final val = _settingsBox.get('accent_color');
    return val != null ? val as int : null;
  }
}
