// lib/models/word_card.dart

class WordCard {
  final int id;
  final String word;
  final String reading;
  final String meaning;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? exampleMeaning;
  final String level;

  WordCard({
    required this.id,
    required this.word,
    required this.reading,
    required this.meaning,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleMeaning,
    this.level = 'N5',
  });

  factory WordCard.fromJson(Map<String, dynamic> json) {
    return WordCard(
      id: json['id'] as int,
      word: json['word'] ?? '',
      reading: json['reading'] ?? '',
      meaning: json['meaning'] ?? '',
      partOfSpeech: json['part_of_speech'],
      exampleSentence: json['example_sentence'],
      exampleMeaning: json['example_meaning'],
      level: json['level'] ?? 'N5',
    );
  }
}
