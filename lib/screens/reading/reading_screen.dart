// lib/screens/reading/reading_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import '../../services/word_service.dart';
import '../../services/daily_task_service.dart';
import '../../utils/shimmer_loading.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  bool _isCompleted = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadDailyNews();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP");
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  /// 載入今日新聞
  Future<void> _loadDailyNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final level = await DailyTaskService.getTargetLevel();
      final data = await NewsService.getNewNews(
        limit: DailyTaskService.dailyNews,
        level: level,
      );

      setState(() {
        _articles = data.map((json) => NewsArticle.fromJson(json)).toList();
        _isLoading = false;
        _isCompleted = _articles.isEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入失敗：$e';
      });
    }
  }

  /// 載入額外新聞
  Future<void> _loadBonusNews() async {
    setState(() => _isLoading = true);
    try {
      final level = await DailyTaskService.getTargetLevel();
      final data = await NewsService.getNewNews(limit: 2, level: level);
      setState(() {
        _articles = data.map((json) => NewsArticle.fromJson(json)).toList();
        _isLoading = false;
        _isCompleted = _articles.isEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入失敗：$e';
      });
    }
  }

  /// 標記已學會（Optimistic UI：先更新畫面，再背景寫 DB）
  void _markArticleMastered(NewsArticle article, int index) {
    // 1. 立即更新 UI
    setState(() {
      _articles.removeAt(index);
      if (_articles.isEmpty) {
        _isCompleted = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已標記為學會！'),
        backgroundColor: Colors.teal,
      ),
    );

    // 2. 背景寫入資料庫
    _persistNewsMastered(article.id);
  }

  /// 背景持久化新聞已學會狀態
  Future<void> _persistNewsMastered(int newsId) async {
    try {
      await NewsService.markAsMastered(newsId);
      final session = await DailyTaskService.getOrCreateTodaySession();
      await DailyTaskService.updateSession(
        newsCompleted: (session['news_completed'] as int? ?? 0) + 1,
      );
    } catch (_) {
      // 靜默失敗
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '時事聽讀',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading(itemCount: 2, type: ShimmerType.card);
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyNews,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_isCompleted) {
      return _buildCompletedView();
    }

    return RefreshIndicator(
      onRefresh: _loadDailyNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _buildNewsCard(article, index);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NHK Easy',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  article.newsDate ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _speak("${article.title}。${article.content}");
                  },
                  icon: const Icon(Icons.volume_up, color: Colors.teal),
                  label: const Text(
                    '聽朗讀',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showTranslationSheet(
                    context,
                    article,
                  ),
                  icon: const Icon(Icons.translate, color: Colors.teal),
                  label: const Text(
                    '看翻譯與單字',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('已學會這篇'),
                onPressed: () => _markArticleMastered(article, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.headset, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            const Text(
              '🎉 今日聽讀任務完成！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '聽力和閱讀能力持續提升中！',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  '繼續閱讀更多新聞！',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _loadBonusNews,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranslationSheet(BuildContext context, NewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  const Text(
                    '中文翻譯',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.translation,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '文章重點單字',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (article.vocabList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '本篇文章暫無重點單字',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...article.vocabList.map((vocab) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.star_border, color: Colors.orange),
                      title: Text(vocab.word),
                      subtitle: Text(vocab.meaning),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.teal),
                            onPressed: () {
                              // 取出括號前的日文部分朗讀
                              final wordOnly = vocab.word.split(' ').first;
                              _speak(wordOnly);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.teal,
                            ),
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              try {
                                await WordService.addWordFromNews(
                                  word: vocab.word,
                                  meaning: vocab.meaning,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('已將 ${vocab.word} 加入字卡庫！'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('加入失敗，請稍後再試'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
