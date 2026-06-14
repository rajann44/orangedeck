import 'package:dio/dio.dart';

class HnApiService {
  final Dio _dio;
  static const String _baseUrl = 'https://hacker-news.firebaseio.com/v0';

  HnApiService(this._dio) {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Fetches a list of story IDs from Hacker News based on the feed filter (e.g. top, new, best).
  Future<List<int>> fetchStoryIds(String apiKey) async {
    try {
      final response = await _dio.get<List<dynamic>>('$_baseUrl/${apiKey}stories.json');
      if (response.statusCode == 200 && response.data != null) {
        return response.data!.cast<int>();
      }
      throw Exception('Unexpected empty response or error code: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Network error while loading feed list: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error loading feed list: $e');
    }
  }

  /// Fetches details for a specific item ID.
  Future<Map<String, dynamic>> fetchItemDetails(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_baseUrl/item/$id.json');
      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      }
      throw Exception('Failed to fetch details for item ID: $id');
    } on DioException catch (e) {
      throw Exception('Network error while loading item $id: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error loading item $id: $e');
    }
  }
}
