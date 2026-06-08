// lib/models/daily_session.dart

class DailySession {
  final int id;
  final String userId;
  final DateTime sessionDate;
  final int wordsNew;
  final int wordsReviewed;
  final int grammarsCompleted;
  final int newsCompleted;
  final bool isCompleted;

  DailySession({
    required this.id,
    required this.userId,
    required this.sessionDate,
    this.wordsNew = 0,
    this.wordsReviewed = 0,
    this.grammarsCompleted = 0,
    this.newsCompleted = 0,
    this.isCompleted = false,
  });

  factory DailySession.fromJson(Map<String, dynamic> json) {
    return DailySession(
      id: json['id'] as int,
      userId: json['user_id'] ?? '',
      sessionDate: DateTime.parse(json['session_date']),
      wordsNew: json['words_new'] ?? 0,
      wordsReviewed: json['words_reviewed'] ?? 0,
      grammarsCompleted: json['grammars_completed'] ?? 0,
      newsCompleted: json['news_completed'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  int get totalWordsStudied => wordsNew + wordsReviewed;
}
