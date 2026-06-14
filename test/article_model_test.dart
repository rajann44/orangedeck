import 'package:flutter_test/flutter_test.dart';
import 'package:orangedeck/shared/domain/models/article.dart';

void main() {
  group('Article Model Parsing Tests', () {
    test('Should parse valid story JSON correctly', () {
      final json = {
        'id': 12345,
        'title': 'Test Hacker News Article',
        'url': 'https://github.com/HackerNews/API',
        'by': 'dhh',
        'score': 150,
        'descendants': 42,
        'time': 1609459200,
        'text': null,
      };

      final article = Article.fromJson(json);

      expect(article.id, 12345);
      expect(article.title, 'Test Hacker News Article');
      expect(article.url, 'https://github.com/HackerNews/API');
      expect(article.by, 'dhh');
      expect(article.score, 150);
      expect(article.commentCount, 42);
      expect(article.time, 1609459200);
      expect(article.text, isNull);
      expect(article.domain, 'github.com');
    });

    test('Should handle missing URL and default to self.HackerNews', () {
      final json = {
        'id': 67890,
        'title': 'Ask HN: What is your favorite tool?',
        'by': 'pg',
        'score': 200,
        'descendants': 12,
        'time': 1609459200,
        'text': '<p>Here is some <i>italicized</i> text.</p>',
      };

      final article = Article.fromJson(json);

      expect(article.url, isNull);
      expect(article.domain, 'self.HackerNews');
      expect(article.text, contains('<i>italicized</i>'));
    });

    test('Should handle malformed or missing fields gracefully', () {
      final json = {
        'id': 11111,
        'time': 1609459200,
      };

      final article = Article.fromJson(json);

      expect(article.id, 11111);
      expect(article.title, '[No Title]');
      expect(article.by, 'anonymous');
      expect(article.score, 0);
      expect(article.commentCount, 0);
    });
  });
}
