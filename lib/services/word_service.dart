// lib/services/word_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class WordService {
  static final _client = Supabase.instance.client;

  /// 從 vocabulary_bank 取得指定級別的新單字（排除使用者已有進度的）
  static Future<List<Map<String, dynamic>>> getNewWords({
    required String level,
    required int limit,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // 取得使用者已經有進度的 vocab_id 列表
    final existing = await _client
        .from('user_word_progress')
        .select('vocab_id')
        .eq('user_id', userId);

    final existingIds =
        (existing as List).map((e) => e['vocab_id'] as int).toList();

    // 從 vocabulary_bank 抓新單字
    var query = _client.from('vocabulary_bank').select().eq('level', level);

    if (existingIds.isNotEmpty) {
      // 使用 not.in 排除已有進度的單字
      query = query.not('id', 'in', existingIds);
    }

    final data = await query.limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 取得使用者需要複習的單字（next_review_at <= 現在 且 status != 'mastered'）
  static Future<List<Map<String, dynamic>>> getReviewWords({
    int limit = 20,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await _client
        .from('user_word_progress')
        .select('*, vocabulary_bank(*)')
        .neq('status', 'mastered')
        .lte('next_review_at', now)
        .order('next_review_at', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 建立使用者的單字進度記錄（第一次見到這個單字）
  static Future<void> createProgress(int vocabId) async {
    await _client.from('user_word_progress').upsert({
      'vocab_id': vocabId,
      'status': 'learning',
      'familiarity': 0,
      'ease_factor': 2.5,
      'interval_days': 0,
      'next_review_at': DateTime.now().toUtc().toIso8601String(),
      'times_seen': 0,
      'times_correct': 0,
    });
  }

  /// SM-2 演算法：使用者滑動後更新進度
  /// [isCorrect] true = 右滑（記住了）, false = 左滑（不熟）
  static Future<void> updateProgress({
    required int progressId,
    required bool isCorrect,
    required int currentFamiliarity,
    required double currentEF,
    required int currentInterval,
    required int timesSeen,
    required int timesCorrect,
  }) async {
    int newFamiliarity;
    double newEF;
    int newInterval;
    String newStatus;

    if (isCorrect) {
      // 答對：增加熟悉度
      newFamiliarity = (currentFamiliarity + 1).clamp(0, 5);
      // SM-2 EF 更新 (grade = 4 for correct)
      newEF = currentEF + (0.1 - (5 - 4) * (0.08 + (5 - 4) * 0.02));
      if (newEF < 1.3) newEF = 1.3;

      // 計算新的複習間隔
      if (currentFamiliarity == 0) {
        newInterval = 1; // 第一次答對：1天後複習
      } else if (currentFamiliarity == 1) {
        newInterval = 3; // 第二次答對：3天後
      } else {
        newInterval = (currentInterval * newEF).round();
      }

      // 到達最高熟悉度 → 標記為已學會
      newStatus = newFamiliarity >= 5 ? 'mastered' : 'learning';
    } else {
      // 答錯：重置
      newFamiliarity = 0;
      newEF = (currentEF - 0.2).clamp(1.3, 3.0);
      newInterval = 1; // 明天再出現
      newStatus = 'learning';
    }

    final nextReview =
        DateTime.now().toUtc().add(Duration(days: newInterval));

    await _client.from('user_word_progress').update({
      'familiarity': newFamiliarity,
      'ease_factor': newEF,
      'interval_days': newInterval,
      'next_review_at': nextReview.toIso8601String(),
      'status': newStatus,
      'times_seen': timesSeen + 1,
      'times_correct': isCorrect ? timesCorrect + 1 : timesCorrect,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', progressId);
  }

  /// 取得所有已學會的單字
  static Future<List<Map<String, dynamic>>> getMasteredWords() async {
    final data = await _client
        .from('user_word_progress')
        .select('*, vocabulary_bank(*)')
        .eq('status', 'mastered')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 取得已學會的單字數量
  static Future<int> getMasteredCount() async {
    final data = await _client
        .from('user_word_progress')
        .select('id')
        .eq('status', 'mastered');
    return (data as List).length;
  }

  /// 從新聞加入單字到 SRS 系統
  /// 1. 寫入 vocabulary_bank（標記 added_by 為當前使用者）
  /// 2. 自動建立 user_word_progress 記錄
  static Future<void> addWordFromNews({
    required String word,
    required String meaning,
    String reading = '',
  }) async {
    final userId = _client.auth.currentUser!.id;

    // 先檢查 vocabulary_bank 中是否已存在相同單字
    final existing = await _client
        .from('vocabulary_bank')
        .select('id')
        .eq('word', word)
        .maybeSingle();

    int vocabId;

    if (existing != null) {
      vocabId = existing['id'] as int;
    } else {
      // 新增到 vocabulary_bank
      final inserted = await _client
          .from('vocabulary_bank')
          .insert({
            'word': word,
            'reading': reading,
            'meaning': meaning,
            'level': 'N5', // 從新聞加入的預設為 N5
            'added_by': userId,
          })
          .select('id')
          .single();
      vocabId = inserted['id'] as int;
    }

    // 建立 SRS 進度（如果尚未存在）
    await createProgress(vocabId);
  }

  /// 切換單字收藏狀態
  static Future<void> toggleBookmark(int progressId, bool isBookmarked) async {
    await _client.from('user_word_progress').update({
      'is_bookmarked': isBookmarked,
    }).eq('id', progressId);
  }

  /// 取得所有收藏的單字
  static Future<List<Map<String, dynamic>>> getBookmarkedWords() async {
    final data = await _client
        .from('user_word_progress')
        .select('*, vocabulary_bank(*)')
        .eq('is_bookmarked', true)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
