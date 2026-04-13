import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 引入套件
import '../../models/word_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();

  // 用來存放從雲端抓下來的單字
  List<WordCard> _flashcards = [];
  bool _isLoading = true; // 載入狀態

  @override
  void initState() {
    super.initState();
    _fetchWords(); // 畫面一初始化就去抓資料
  }

  // 從 Supabase 抓取資料的非同步函式
  Future<void> _fetchWords() async {
    try {
      final data = await Supabase.instance.client
          .from('words')
          .select(); // 相當於 SELECT * FROM words

      final List<WordCard> loadedWords = (data as List).map((json) {
        return WordCard(
          word: json['word'],
          reading: json['reading'],
          meaning: json['meaning'],
        );
      }).toList();

      setState(() {
        _flashcards = loadedWords;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('抓取資料失敗: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '今日微學習任務',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 載入中顯示轉圈圈
          : _flashcards.isEmpty
          ? const Center(child: Text('目前沒有單字，快去資料庫新增吧！'))
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    '向右滑: 記住了 👉\n👈 向左滑: 還不熟',
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: _flashcards.length,
                      onSwipe: _onSwipe,
                      allowedSwipeDirection:
                          const AllowedSwipeDirection.symmetric(
                            horizontal: true,
                          ),
                      numberOfCardsDisplayed: _flashcards.length >= 3
                          ? 3
                          : _flashcards.length,
                      padding: const EdgeInsets.all(24.0),
                      cardBuilder: (context, index, _, _) =>
                          _buildCard(_flashcards[index]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ... (保留原本的 _buildCard 與 _onSwipe 函式內容)
  Widget _buildCard(WordCard card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.reading,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              card.word,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                card.meaning,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    return true;
  }
}
