// lib/screens/reading/reading_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 1. 引入語音套件

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  // 2. 建立語音發聲器實例
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts(); // 初始化語音設定
  }

  // 3. 設定語音參數
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ja-JP"); // 強制設定為日文發音
    await _flutterTts.setSpeechRate(0.4); // 語速調慢一點，適合學習者 (預設通常是 0.5)
    await _flutterTts.setVolume(1.0); // 音量開到最大
  }

  // 4. 播放語音的函式
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  // 5. 停止語音的函式 (切換頁面或按暫停時可以用)
  Future<void> _stop() async {
    await _flutterTts.stop();
  }

  // 離開頁面時記得釋放資源
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchNews() async {
    final data = await Supabase.instance.client
        .from('news')
        .select('*, news_vocab(*)');
    return List<Map<String, dynamic>>.from(data);
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('暫無時事新聞'));
          }

          final newsList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              final List vocabList = news['news_vocab'] ?? [];

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
                            news['news_date'] ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        news['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['content'],
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 6. 將播放按鈕與 _speak 函式綁定
                          TextButton.icon(
                            onPressed: () {
                              // 把標題和內文加在一起唸出來
                              _speak("${news['title']}。${news['content']}");
                            },
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.teal,
                            ),
                            label: const Text(
                              '聽朗讀',
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showTranslationSheet(
                              context,
                              news['translation'],
                              vocabList,
                            ),
                            icon: const Icon(
                              Icons.translate,
                              color: Colors.teal,
                            ),
                            label: const Text(
                              '看翻譯與單字',
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTranslationSheet(
    BuildContext context,
    String translation,
    List vocabList,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                translation,
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
              if (vocabList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '本篇文章暫無重點單字',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...vocabList.map((vocab) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_border, color: Colors.orange),
                  title: Text(vocab['word'] ?? ''),
                  subtitle: Text(vocab['meaning'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // 確保 Row 只佔用需要的寬度，防止排版崩潰
                    children: [
                      // 按鈕一：語音朗讀單字
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.teal),
                        onPressed: () {
                          _speak(vocab['word'] ?? '');
                        },
                      ),
                      // 按鈕二：加入雲端單字庫 (Supabase)
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.teal,
                        ),
                        onPressed: () async {
                          Navigator.pop(context); // 點擊後先自動收起底部視窗

                          try {
                            // 寫入 Supabase 資料庫，會自動帶入當前使用者的 uid
                            await Supabase.instance.client
                                .from('words')
                                .insert({
                                  'word': vocab['word'],
                                  'reading': '',
                                  'meaning': vocab['meaning'],
                                });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已將 ${vocab['word']} 加入每日字卡庫！'),
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
  }
}
