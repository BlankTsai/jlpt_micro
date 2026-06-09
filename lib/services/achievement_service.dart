// lib/services/achievement_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// 成就定義
class Achievement {
  final String id;
  final String icon;
  final String title;
  final String description;
  final bool unlocked;
  final int current; // 目前進度
  final int target; // 目標值

  Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.current,
    required this.target,
  });

  double get progress => (current / target).clamp(0.0, 1.0);
}

class AchievementService {
  static final _client = Supabase.instance.client;

  /// 檢查所有成就，返回完整列表（含解鎖狀態）
  static Future<List<Achievement>> checkAchievements() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _getDefaultAchievements();

    // 平行查詢所有需要的數據
    final futures = await Future.wait<int>([
      _getSessionCount(),          // 0: 總打卡天數
      _getStreak(),                // 1: 連續打卡天數
      _getMasteredWordCount(),     // 2: 已學會單字數
      _getMasteredGrammarCount(),  // 3: 已學會文法數
      _getReadNewsCount(),         // 4: 已讀新聞數
      _getBestQuizScore(),         // 5: 最佳測驗分數
    ]);

    final totalSessions = futures[0];
    final streak = futures[1];
    final masteredWords = futures[2];
    final masteredGrammars = futures[3];
    final readNews = futures[4];
    final bestScore = futures[5];

    return [
      Achievement(
        id: 'first_learn',
        icon: '🌱',
        title: '初心者',
        description: '完成第一次學習',
        unlocked: totalSessions >= 1,
        current: totalSessions.clamp(0, 1),
        target: 1,
      ),
      Achievement(
        id: 'streak_3',
        icon: '🔥',
        title: '三日連續',
        description: '連續打卡 3 天',
        unlocked: streak >= 3,
        current: streak.clamp(0, 3),
        target: 3,
      ),
      Achievement(
        id: 'streak_7',
        icon: '💪',
        title: '七日戰士',
        description: '連續打卡 7 天',
        unlocked: streak >= 7,
        current: streak.clamp(0, 7),
        target: 7,
      ),
      Achievement(
        id: 'words_100',
        icon: '📚',
        title: '百字達人',
        description: '學會 100 個單字',
        unlocked: masteredWords >= 100,
        current: masteredWords.clamp(0, 100),
        target: 100,
      ),
      Achievement(
        id: 'grammar_20',
        icon: '📖',
        title: '文法高手',
        description: '學會 20 條文法',
        unlocked: masteredGrammars >= 20,
        current: masteredGrammars.clamp(0, 20),
        target: 20,
      ),
      Achievement(
        id: 'perfect_quiz',
        icon: '🎯',
        title: '滿分通過',
        description: '模擬測驗得 100 分',
        unlocked: bestScore >= 100,
        current: bestScore.clamp(0, 100),
        target: 100,
      ),
      Achievement(
        id: 'news_10',
        icon: '🌍',
        title: '世界觀察家',
        description: '閱讀 10 篇新聞',
        unlocked: readNews >= 10,
        current: readNews.clamp(0, 10),
        target: 10,
      ),
      Achievement(
        id: 'streak_30',
        icon: '👑',
        title: '月度冠軍',
        description: '連續打卡 30 天',
        unlocked: streak >= 30,
        current: streak.clamp(0, 30),
        target: 30,
      ),
    ];
  }

  // ---- 查詢方法 ----

  static Future<int> _getSessionCount() async {
    final data = await _client
        .from('daily_sessions')
        .select('id');
    return (data as List).length;
  }

  static Future<int> _getStreak() async {
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
    DateTime checkDate = DateTime.now();
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

  static Future<int> _getMasteredWordCount() async {
    final data = await _client
        .from('user_word_progress')
        .select('id')
        .eq('status', 'mastered');
    return (data as List).length;
  }

  static Future<int> _getMasteredGrammarCount() async {
    final data = await _client
        .from('user_grammar_progress')
        .select('id')
        .eq('status', 'mastered');
    return (data as List).length;
  }

  static Future<int> _getReadNewsCount() async {
    final data = await _client
        .from('user_news_progress')
        .select('id');
    return (data as List).length;
  }

  static Future<int> _getBestQuizScore() async {
    // 從 SharedPreferences 讀取最佳分數（quiz 不存 DB）
    // 這裡暫時返回 0，由 ProfileScreen 在測驗完後更新
    return 0;
  }

  static List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(id: 'first_learn', icon: '🌱', title: '初心者',
          description: '完成第一次學習', unlocked: false, current: 0, target: 1),
    ];
  }
}
