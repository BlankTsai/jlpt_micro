// lib/screens/swipe/swipe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/word_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();

  // 建立 Supabase 的即時資料流 (Stream)
  // 記得確保你的 Supabase 資料表 'words' 已經開啟了 Realtime 功能
  final Stream<List<Map<String, dynamic>>> _wordsStream = Supabase
      .instance
      .client
      .from('words')
      .stream(primaryKey: ['id'])
      .order('id', ascending: false); // 讓最新的單字排在最前面

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
      // 💡 核心魔法：使用 StreamBuilder 自動監聽資料庫變化
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _wordsStream,
        builder: (context, snapshot) {
          // 狀態 1：正在連線或等待資料
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 狀態 2：連線發生錯誤
          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤：${snapshot.error}'));
          }

          // 狀態 3：沒有資料 (使用者剛註冊，還沒加單字)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '字卡庫空空如也 🍃\n快去「時事聽讀」把單字加進來吧！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 狀態 4：成功取得資料！將資料轉換為 WordCard 模型
          final List<WordCard> flashcards = snapshot.data!.map((json) {
            return WordCard(
              word: json['word'] ?? '',
              reading: json['reading'] ?? '',
              meaning: json['meaning'] ?? '',
            );
          }).toList();

          // 渲染滑動字卡 UI
          return SafeArea(
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
                    cardsCount: flashcards.length,
                    onSwipe: _onSwipe,
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(horizontal: true),
                    // 如果單字大於等於 3 個就顯示 3 張疊加效果，否則有幾張顯示幾張
                    numberOfCardsDisplayed: flashcards.length >= 3
                        ? 3
                        : flashcards.length,
                    padding: const EdgeInsets.all(24.0),
                    cardBuilder: (context, index, _, __) =>
                        _buildCard(flashcards[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 繪製單張字卡的 UI (保持你原本帥氣的設計)
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

  // 處理滑動邏輯
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // 之後可以在這裡加入演算法，例如：
    // 如果是往右滑 (direction == CardSwiperDirection.right)，就把這張卡的「熟悉度」加一並回傳資料庫
    // 如果是往左滑，就降低熟悉度
    debugPrint('滑動了第 $previousIndex 張卡片，方向: $direction');
    return true;
  }
}
