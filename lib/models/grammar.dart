// lib/models/grammar.dart

class Grammar {
  final int id;
  final String title;
  final String meaning;
  final String exampleJp;
  final String exampleCh;
  final String level;

  Grammar({
    required this.id,
    required this.title,
    required this.meaning,
    required this.exampleJp,
    required this.exampleCh,
    required this.level,
  });

  factory Grammar.fromJson(Map<String, dynamic> json) {
    return Grammar(
      id: json['id'] as int,
      title: json['title'] ?? '',
      meaning: json['meaning'] ?? '',
      exampleJp: json['example_jp'] ?? '',
      exampleCh: json['example_ch'] ?? '',
      level: json['level'] ?? 'N5',
    );
  }
}
