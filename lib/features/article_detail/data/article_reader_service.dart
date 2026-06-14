import 'dart:math' as math;
import 'package:dio/dio.dart';

class ArticleReaderService {
  final Dio _dio = Dio();

  /// Fetches the raw HTML of the article URL and extracts its main text contents
  Future<String> fetchReadableContent(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load page content');
      }

      final String html = response.data.toString();
      return _extractMainText(html);
    } catch (e) {
      throw Exception('Could not retrieve readable text: $e');
    }
  }

  String _extractMainText(String html) {
    // 1. Strip scripts, styles, heads, headers, and footers
    var cleanHtml = html
        .replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<header\b[^<]*(?:(?!<\/header>)<[^<]*)*<\/header>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<footer\b[^<]*(?:(?!<\/footer>)<[^<]*)*<\/footer>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<nav\b[^<]*(?:(?!<\/nav>)<[^<]*)*<\/nav>', caseSensitive: false), '');

    // 2. Find all <p> paragraphs
    final paragraphRegExp = RegExp(r'<p\b[^>]*>(.*?)<\/p>', caseSensitive: false, dotAll: true);
    final matches = paragraphRegExp.allMatches(cleanHtml);

    final List<String> paragraphs = [];
    for (final match in matches) {
      var pText = match.group(1) ?? '';
      
      // Clean inner formatting tags (e.g. <a>, <strong>, <span>)
      pText = pText.replaceAll(RegExp(r'<[^>]*>'), '');
      
      // Decode basic HTML entities
      pText = _decodeHtmlEntities(pText.trim());

      // Keep only paragraphs containing descriptive textual sentences (length > 60 chars)
      if (pText.length > 60) {
        paragraphs.add(pText);
      }
    }

    if (paragraphs.isEmpty) {
      // Fallback: if no paragraph tags found, strip all HTML tags and grab the first segment
      var fallback = cleanHtml.replaceAll(RegExp(r'<[^>]*>'), '');
      fallback = _decodeHtmlEntities(fallback.trim());
      // Collapse multiple whitespace
      fallback = fallback.replaceAll(RegExp(r'\s+'), ' ');
      if (fallback.length > 200) {
        return '${fallback.substring(0, math.min(1500, fallback.length))}...';
      }
      throw Exception('No readable text found on this page.');
    }

    return paragraphs.join('\n\n');
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&middot;', '·')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—');
  }
}
