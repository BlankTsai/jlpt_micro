// lib/models/word_progress.dart

class WordProgress {
  final int id;
  final String userId;
  final int vocabId;
  final String status; // 'new', 'learning', 'mastered'
  final int familiarity; // 0~5
  final double easeFactor; // SM-2 EF, starts at 2.5
  final int intervalDays;
  final DateTime nextReviewAt;
  final int timesSeen;
  final int timesCorrect;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 關聯的 WordCard 資料（join 查詢時帶入）
  final String? word;
  final String? reading;
  final String? meaning;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? exampleMeaning;
  final String? level;

  WordProgress({
    required this.id,
    required this.userId,
    required this.vocabId,
    required this.status,
    required this.familiarity,
    required this.easeFactor,
    required this.intervalDays,
    required this.nextReviewAt,
    required this.timesSeen,
    required this.timesCorrect,
    required this.createdAt,
    required this.updatedAt,
    this.word,
    this.reading,
    this.meaning,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleMeaning,
    this.level,
  });

  factory WordProgress.fromJson(Map<String, dynamic> json) {
    // 處理 join 查詢帶入的 vocabulary_bank 資料
    final vocab =
        json['vocabulary_bank'] as Map<String, dynamic>? ?? {};

    return WordProgress(
      id: json['id'] as int,
      userId: json['user_id'] ?? '',
      vocabId: json['vocab_id'] as int,
      status: json['status'] ?? 'new',
      familiarity: json['familiarity'] ?? 0,
      easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
      intervalDays: json['interval_days'] ?? 0,
      nextReviewAt: DateTime.parse(
        json['next_review_at'] ?? DateTime.now().toIso8601String(),
      ),
      timesSeen: json['times_seen'] ?? 0,
      timesCorrect: json['times_correct'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      word: vocab['word'],
      reading: vocab['reading'],
      meaning: vocab['meaning'],
      partOfSpeech: vocab['part_of_speech'],
      exampleSentence: vocab['example_sentence'],
      exampleMeaning: vocab['example_meaning'],
      level: vocab['level'],
    );
  }

  bool get isMastered => status == 'mastered';
  bool get isDueForReview => nextReviewAt.isBefore(DateTime.now());
}
