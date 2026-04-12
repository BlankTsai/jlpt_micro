// lib/models/word_card.dart

class WordCard {
  final String word; // 日文單字
  final String reading; // 讀音 (假名)
  final String meaning; // 中文意思

  WordCard({required this.word, required this.reading, required this.meaning});
}
