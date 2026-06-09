// lib/services/quiz_service.dart

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 測驗題目
class QuizQuestion {
  final String question; // 題目文字（日文單字或例句）
  final String correctAnswer; // 正確答案
  final List<String> options; // 4 個選項（已亂序）
  final String type; // 'vocab' or 'grammar'
  final Map<String, dynamic>? extra; // 額外資訊（reading 等）

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.type,
    this.extra,
  });
}

class QuizService {
  static final _client = Supabase.instance.client;
  static final _random = Random();

  /// 產生單字選擇題
  /// 給日文單字，從 4 個中文意思中選正確的
  static Future<List<QuizQuestion>> getVocabQuestions({
    required String level,
    int count = 10,
  }) async {
    // 抓該級別所有單字
    final allWords = await _client
        .from('vocabulary_bank')
        .select('word, reading, meaning')
        .eq('level', level);

    final wordList = List<Map<String, dynamic>>.from(allWords);
    if (wordList.length < 4) return [];

    wordList.shuffle(_random);
    final selected = wordList.take(count.clamp(1, wordList.length)).toList();

    final questions = <QuizQuestion>[];
    for (final word in selected) {
      final correctMeaning = word['meaning'] as String;

      // 取 3 個不重複的干擾選項
      final distractors = wordList
          .where((w) => w['meaning'] != correctMeaning)
          .map((w) => w['meaning'] as String)
          .toSet()
          .toList();
      distractors.shuffle(_random);
      final wrongOptions = distractors.take(3).toList();

      final options = [correctMeaning, ...wrongOptions];
      options.shuffle(_random);

      questions.add(QuizQuestion(
        question: word['word'] as String,
        correctAnswer: correctMeaning,
        options: options,
        type: 'vocab',
        extra: {'reading': word['reading']},
      ));
    }

    return questions;
  }

  /// 產生文法填空題
  /// 給句子意思，從 4 個文法中選正確的
  static Future<List<QuizQuestion>> getGrammarQuestions({
    required String level,
    int count = 10,
  }) async {
    final allGrammars = await _client
        .from('grammars')
        .select('title, meaning, example_jp, example_ch')
        .eq('level', level);

    final grammarList = List<Map<String, dynamic>>.from(allGrammars);
    if (grammarList.length < 4) return [];

    grammarList.shuffle(_random);
    final selected =
        grammarList.take(count.clamp(1, grammarList.length)).toList();

    final questions = <QuizQuestion>[];
    for (final grammar in selected) {
      final correctTitle = grammar['title'] as String;

      final distractors = grammarList
          .where((g) => g['title'] != correctTitle)
          .map((g) => g['title'] as String)
          .toSet()
          .toList();
      distractors.shuffle(_random);
      final wrongOptions = distractors.take(3).toList();

      final options = [correctTitle, ...wrongOptions];
      options.shuffle(_random);

      questions.add(QuizQuestion(
        question: grammar['meaning'] as String,
        correctAnswer: correctTitle,
        options: options,
        type: 'grammar',
        extra: {
          'example_jp': grammar['example_jp'],
          'example_ch': grammar['example_ch'],
        },
      ));
    }

    return questions;
  }
}
