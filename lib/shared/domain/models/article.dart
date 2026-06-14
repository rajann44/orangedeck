class Article {
  final int id;
  final String title;
  final String? url;
  final String by;
  final int score;
  final int commentCount;
  final int time; // Unix timestamp
  final String? text; // For text-based cards (Ask HN)
  final DateTime? savedAt; // Metadata for sorting local saved list
  final List<int> commentIds; // List of top-level comment IDs

  Article({
    required this.id,
    required this.title,
    this.url,
    required this.by,
    required this.score,
    required this.commentCount,
    required this.time,
    this.text,
    this.savedAt,
    this.commentIds = const [],
  });

  /// Extracts clean hostname from the article's URL.
  /// Defaults to 'self.HackerNews' if URL is missing (e.g. Ask HN).
  String get domain {
    if (url == null || url!.isEmpty) return 'self.HackerNews';
    try {
      final uri = Uri.parse(url!);
      final host = uri.host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return 'external';
    }
  }

  /// Converts Article model to JSON for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'by': by,
      'score': score,
      'descendants': commentCount,
      'time': time,
      'text': text,
      'savedAt': savedAt?.toIso8601String(),
      'kids': commentIds,
    };
  }

  /// Instantiates Article model from API or Hive JSON structure
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String? ?? '[No Title]',
      url: json['url'] as String?,
      by: json['by'] as String? ?? 'anonymous',
      score: json['score'] as int? ?? 0,
      commentCount: json['descendants'] as int? ?? 0,
      time: json['time'] as int? ?? 0,
      text: json['text'] as String?,
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String)
          : null,
      commentIds: json['kids'] != null
          ? List<int>.from(json['kids'] as List)
          : const [],
    );
  }

  /// Creates a copy of Article with updated fields
  Article copyWith({
    int? id,
    String? title,
    String? url,
    String? by,
    int? score,
    int? commentCount,
    int? time,
    String? text,
    DateTime? savedAt,
    List<int>? commentIds,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      by: by ?? this.by,
      score: score ?? this.score,
      commentCount: commentCount ?? this.commentCount,
      time: time ?? this.time,
      text: text ?? this.text,
      savedAt: savedAt ?? this.savedAt,
      commentIds: commentIds ?? this.commentIds,
    );
  }
}
