import 'package:flutter/foundation.dart';
import '../../../shared/domain/models/article.dart';
import 'hn_api_service.dart';

class DeckRepository {
  final HnApiService _apiService;

  DeckRepository(this._apiService);

  /// Fetches a batch of items in parallel. Filters out comments, polls, dead, or deleted items.
  Future<List<Article>> fetchArticlesBatch(List<int> ids) async {
    // Resolve item details concurrently
    final futures = ids.map((id) => _apiService.fetchItemDetails(id).then((json) {
          final type = json['type'] as String?;
          
          // Filter out comments, polls, etc. Only allow stories, asks, shows, and jobs.
          if (type != 'story' && type != 'show_hn' && type != 'ask_hn' && type != 'job') {
            return null;
          }

          // Filter out deleted or dead items
          if (json['deleted'] == true || json['dead'] == true) {
            return null;
          }

          // Filter out articles older than 90 days (approx. 3 months) to satisfy News policy
          final time = json['time'] as int?;
          if (time != null) {
            final threshold = DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch ~/ 1000;
            if (time < threshold) {
              return null;
            }
          }

          // Title is mandatory to represent a valid card
          final title = json['title'] as String?;
          if (title == null || title.trim().isEmpty) {
            return null;
          }

          return Article.fromJson(json);
        }).catchError((Object error) {
          debugPrint('DEBUG: Failed to fetch details for item $id: $error');
          return null;
        }));

    final List<Article?> results = await Future.wait(futures);
    
    // Filter out all null entries
    return results.whereType<Article>().toList();
  }
}
