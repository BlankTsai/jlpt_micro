// lib/services/grammar_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class GrammarService {
  static final _client = Supabase.instance.client;

  /// 取得指定級別的新文法（排除使用者已有進度的）
  static Future<List<Map<String, dynamic>>> getNewGrammars({
    required String level,
    required int limit,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final existing = await _client
        .from('user_grammar_progress')
        .select('grammar_id')
        .eq('user_id', userId);

    final existingIds =
        (existing as List).map((e) => e['grammar_id'] as int).toList();

    var query = _client.from('grammars').select().eq('level', level);

    if (existingIds.isNotEmpty) {
      query = query.not('id', 'in', existingIds);
    }

    final data = await query.limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 取得需要複習的文法
  static Future<List<Map<String, dynamic>>> getReviewGrammars({
    int limit = 10,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('user_grammar_progress')
        .select('*, grammars(*)')
        .neq('status', 'mastered')
        .lte('next_review_at', now)
        .order('next_review_at', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 建立文法進度記錄
  static Future<void> createProgress(int grammarId) async {
    await _client.from('user_grammar_progress').upsert({
      'grammar_id': grammarId,
      'status': 'learning',
      'familiarity': 0,
      'next_review_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// 標記文法為已學會
  static Future<void> markAsMastered(int progressId) async {
    await _client.from('user_grammar_progress').update({
      'status': 'mastered',
      'familiarity': 5,
    }).eq('id', progressId);
  }

  /// 標記文法為學習中（從已學會取消）
  static Future<void> markAsLearning(int progressId) async {
    await _client.from('user_grammar_progress').update({
      'status': 'learning',
      'familiarity': 0,
      'next_review_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', progressId);
  }

  /// 取得所有已學會的文法
  static Future<List<Map<String, dynamic>>> getMasteredGrammars() async {
    final data = await _client
        .from('user_grammar_progress')
        .select('*, grammars(*)')
        .eq('status', 'mastered')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 取得已學會的文法數量
  static Future<int> getMasteredCount() async {
    final data = await _client
        .from('user_grammar_progress')
        .select('id')
        .eq('status', 'mastered');
    return (data as List).length;
  }
}
