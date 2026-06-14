class Comment {
  final int id;
  final String by;
  final String text;
  final int time;

  Comment({
    required this.id,
    required this.by,
    required this.text,
    required this.time,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      by: (json['by'] as String?) ?? 'anonymous',
      text: (json['text'] as String?) ?? '',
      time: (json['time'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'by': by,
      'text': text,
      'time': time,
    };
  }
}
