// lib/services/daily_task_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyTaskService {
  static final _client = Supabase.instance.client;

  // 每日任務預設量
  static const int dailyNewWords = 10;
  static const int dailyGrammars = 3;
  static const int dailyNews = 1;
  static const int bonusNewWords = 5;

  /// 取得或建立今日的學習 Session
  static Future<Map<String, dynamic>> getOrCreateTodaySession() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 嘗試取得今天的 session
    final existing = await _client
        .from('daily_sessions')
        .select()
        .eq('session_date', today)
        .maybeSingle();

    if (existing != null) return existing;

    // 建立新的 session
    final created = await _client
        .from('daily_sessions')
        .insert({'session_date': today})
        .select()
        .single();

    return created;
  }

  /// 更新今日 Session 的進度
  static Future<void> updateSession({
    int? wordsNew,
    int? wordsReviewed,
    int? grammarsCompleted,
    int? newsCompleted,
    bool? isCompleted,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final updates = <String, dynamic>{};

    if (wordsNew != null) updates['words_new'] = wordsNew;
    if (wordsReviewed != null) updates['words_reviewed'] = wordsReviewed;
    if (grammarsCompleted != null) {
      updates['grammars_completed'] = grammarsCompleted;
    }
    if (newsCompleted != null) updates['news_completed'] = newsCompleted;
    if (isCompleted != null) updates['is_completed'] = isCompleted;

    if (updates.isNotEmpty) {
      await _client
          .from('daily_sessions')
          .update(updates)
          .eq('session_date', today);
    }
  }

  /// 計算連續打卡天數
  static Future<int> getStreak() async {
    final data = await _client
        .from('daily_sessions')
        .select('session_date')
        .eq('is_completed', true)
        .order('session_date', ascending: false)
        .limit(365);

    final dates = (data as List)
        .map((e) => DateTime.parse(e['session_date']))
        .toList();

    if (dates.isEmpty) return 0;

    int streak = 0;
    // 從今天或昨天開始算（允許今天尚未完成但昨天有完成的情況）
    DateTime checkDate = DateTime.now();
    // 先標準化為只有日期的 DateTime
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    for (final date in dates) {
      final d = DateTime(date.year, date.month, date.day);
      final diff = checkDate.difference(d).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        checkDate = d;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 取得使用者目標等級（優先從雲端讀取，本機作備援）
  static Future<String> getTargetLevel() async {
    try {
      // 優先從 Supabase 讀取
      final profile = await _client
          .from('user_profiles')
          .select('target_level')
          .maybeSingle();

      if (profile != null) {
        final level = profile['target_level'] as String;
        // 同步到本機
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('targetLevel', level);
        return level;
      }
    } catch (_) {
      // Supabase 查詢失敗，用本機備援
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('targetLevel') ?? 'N5';
  }

  /// 設定使用者目標等級（同時存到雲端和本機）
  static Future<void> setTargetLevel(String level) async {
    // 存到本機
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('targetLevel', level);

    // 存到雲端
    try {
      await _client.from('user_profiles').upsert({
        'target_level': level,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // 雲端失敗不影響使用
    }
  }

  /// 取得最近的學習 session 資料（用於圖表）
  static Future<List<Map<String, dynamic>>> getRecentSessions({
    required String startDate,
    int limit = 7,
  }) async {
    final data = await _client
        .from('daily_sessions')
        .select()
        .gte('session_date', startDate)
        .order('session_date', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }
}
