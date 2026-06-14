import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/models/comment.dart';
import 'deck_notifier.dart';

/// Riverpod future provider family that fetches the details of the top 3 comment IDs concurrently
final commentsPreviewProvider = FutureProvider.family<List<Comment>, List<int>>((ref, commentIds) async {
  if (commentIds.isEmpty) return const [];
  
  final apiService = ref.watch(apiServiceProvider);
  
  // Take first 3 comments
  final idsToFetch = commentIds.take(3).toList();
  
  final futures = idsToFetch.map((id) => apiService.fetchItemDetails(id).then((json) {
        if (json['dead'] == true || json['deleted'] == true) {
          return null;
        }
        return Comment.fromJson(json);
      }).catchError((_) => null));
      
  final results = await Future.wait(futures);
  return results.whereType<Comment>().toList();
});
