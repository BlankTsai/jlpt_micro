// lib/models/news_article.dart

class NewsVocab {
  final int id;
  final String word;
  final String meaning;

  NewsVocab({required this.id, required this.word, required this.meaning});

  factory NewsVocab.fromJson(Map<String, dynamic> json) {
    return NewsVocab(
      id: json['id'] as int,
      word: json['word'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }
}

class NewsArticle {
  final int id;
  final String title;
  final String content;
  final String translation;
  final String? newsDate;
  final List<NewsVocab> vocabList;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.translation,
    this.newsDate,
    this.vocabList = const [],
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final rawVocab = json['news_vocab'] as List? ?? [];
    return NewsArticle(
      id: json['id'] as int,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      translation: json['translation'] ?? '',
      newsDate: json['news_date'],
      vocabList: rawVocab.map((v) => NewsVocab.fromJson(v)).toList(),
    );
  }
}
