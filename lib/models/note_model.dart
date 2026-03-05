class Note {
  final String id;
  final String content;
  final DateTime timestamp; // Creation time
  final DateTime date;      // Note target date (for calendar)
  final bool isPrivate;
  final String userId;      // Device unique identifier

  Note({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.date,
    required this.userId,
    this.isPrivate = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp,
      'date': date,
      'isPrivate': isPrivate,
      'userId': userId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      date: (map['date'] as dynamic)?.toDate() ?? DateTime.now(),
      isPrivate: map['isPrivate'] ?? false,
      userId: map['userId'] ?? 'unknown',
    );
  }
}
