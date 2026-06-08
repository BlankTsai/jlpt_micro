// lib/services/news_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class NewsService {
  static final _client = Supabase.instance.client;

  /// 取得使用者尚未閱讀的新聞（按級別篩選）
  static Future<List<Map<String, dynamic>>> getNewNews({
    int limit = 1,
    String? level,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final existing = await _client
        .from('user_news_progress')
        .select('news_id')
        .eq('user_id', userId);

    final existingIds =
        (existing as List).map((e) => e['news_id'] as int).toList();

    var query = _client.from('news').select('*, news_vocab(*)');

    // 按級別篩選
    if (level != null) {
      query = query.eq('level', level);
    }

    if (existingIds.isNotEmpty) {
      query = query.not('id', 'in', existingIds);
    }

    final data = await query.order('news_date', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 取得所有新聞（含已讀狀態）
  static Future<List<Map<String, dynamic>>> getAllNews() async {
    final data = await _client
        .from('news')
        .select('*, news_vocab(*)')
        .order('news_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// 標記新聞為已讀
  static Future<void> markAsRead(int newsId) async {
    await _client.from('user_news_progress').upsert({
      'news_id': newsId,
      'status': 'read',
    });
  }

  /// 標記新聞為已學會
  static Future<void> markAsMastered(int newsId) async {
    await _client.from('user_news_progress').upsert({
      'news_id': newsId,
      'status': 'mastered',
    });
  }

  /// 取得已讀新聞數量
  static Future<int> getReadCount() async {
    final data = await _client
        .from('user_news_progress')
        .select('id');
    return (data as List).length;
  }
}
