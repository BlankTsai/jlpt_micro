// lib/screens/home/swipe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../models/word_progress.dart';
import '../../services/word_service.dart';
import '../../services/daily_task_service.dart';
import '../../utils/shimmer_loading.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  List<_StudyCard> _cards = [];
  bool _isLoading = true;
  bool _isCompleted = false;
  int _completedCount = 0;
  int _totalCount = 0;
  String _errorMessage = '';

  // 追蹤是否翻面
  final Map<int, bool> _flippedCards = {};

  @override
  void initState() {
    super.initState();
    _loadDailyCards();
  }

  /// 載入今日的單字卡片（新卡 + 複習卡）
  Future<void> _loadDailyCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final level = await DailyTaskService.getTargetLevel();
      final session = await DailyTaskService.getOrCreateTodaySession();

      // 取得需要複習的舊卡
      final reviewData = await WordService.getReviewWords(limit: 15);
      final reviewCards = reviewData.map((json) {
        final progress = WordProgress.fromJson(json);
        return _StudyCard(progress: progress, isNew: false);
      }).toList();

      // 計算還需要多少新卡
      final existingNewCount = session['words_new'] as int? ?? 0;
      final newNeeded =
          (DailyTaskService.dailyNewWords - existingNewCount).clamp(0, 20);

      List<_StudyCard> newCards = [];
      if (newNeeded > 0) {
        final newData =
            await WordService.getNewWords(level: level, limit: newNeeded);
        // 為新單字建立進度記錄
        for (final vocab in newData) {
          await WordService.createProgress(vocab['id'] as int);
        }
        // 重新從 user_word_progress 取得（這樣才有 progress ID）
        if (newData.isNotEmpty) {
          final freshReview = await WordService.getReviewWords(limit: 30);
          final newVocabIds = newData.map((v) => v['id'] as int).toSet();
          newCards = freshReview
              .where((json) => newVocabIds.contains(json['vocab_id']))
              .map((json) {
            final progress = WordProgress.fromJson(json);
            return _StudyCard(progress: progress, isNew: true);
          }).toList();
        }
      }

      // 混合新卡和複習卡（複習卡排前面，讓使用者先複習）
      final allCards = [...reviewCards, ...newCards];

      setState(() {
        _cards = allCards;
        _totalCount = allCards.length;
        _completedCount = 0;
        _isLoading = false;
        _isCompleted = allCards.isEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入失敗：$e';
      });
    }
  }

  /// 載入額外卡片（繼續學習）
  Future<void> _loadBonusCards() async {
    setState(() => _isLoading = true);

    try {
      final level = await DailyTaskService.getTargetLevel();

      // 額外 5 張新卡
      final newData = await WordService.getNewWords(
        level: level,
        limit: DailyTaskService.bonusNewWords,
      );
      for (final vocab in newData) {
        await WordService.createProgress(vocab['id'] as int);
      }

      // 加上一些複習卡
      final reviewData = await WordService.getReviewWords(limit: 5);

      List<_StudyCard> bonusCards = [];

      if (newData.isNotEmpty) {
        final freshReview = await WordService.getReviewWords(limit: 30);
        final newVocabIds = newData.map((v) => v['id'] as int).toSet();
        bonusCards = freshReview
            .where((json) => newVocabIds.contains(json['vocab_id']))
            .map((json) =>
                _StudyCard(progress: WordProgress.fromJson(json), isNew: true))
            .toList();
      }

      final reviewCards = reviewData
          .map((json) =>
              _StudyCard(progress: WordProgress.fromJson(json), isNew: false))
          .toList();

      final allCards = [...reviewCards, ...bonusCards];

      setState(() {
        _cards = allCards;
        _totalCount = allCards.length;
        _completedCount = 0;
        _isLoading = false;
        _isCompleted = allCards.isEmpty;
        _flippedCards.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入失敗：$e';
      });
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading(itemCount: 1, type: ShimmerType.flashcard);
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyCards,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_isCompleted) {
      return _buildCompletedView();
    }

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // 進度條
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '進度：$_completedCount / $_totalCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '👈 不熟   記住了 👉',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _totalCount > 0
                        ? _completedCount / _totalCount
                        : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _cards.length,
              onSwipe: _onSwipe,
              allowedSwipeDirection:
                  const AllowedSwipeDirection.symmetric(horizontal: true),
              numberOfCardsDisplayed:
                  _cards.length >= 3 ? 3 : _cards.length,
              padding: const EdgeInsets.all(24.0),
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
                  _buildCard(_cards[index], index),
            ),
          ),
        ],
      ),
    );
  }

  /// 任務完成畫面
  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              '🎉 今日單字任務完成！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '太棒了！繼續保持學習的節奏吧！',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
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
                  '我還想繼續學！',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _loadBonusCards,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 繪製單張字卡（可點擊翻面看例句）
  Widget _buildCard(_StudyCard card, int index) {
    final isFlipped = _flippedCards[index] ?? false;
    final p = card.progress;

    return GestureDetector(
      onTap: () {
        setState(() {
          _flippedCards[index] = !isFlipped;
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isFlipped
            ? _buildCardBack(p, index)
            : _buildCardFront(p, card.isNew, index),
      ),
    );
  }

  /// 字卡正面
  Widget _buildCardFront(WordProgress p, bool isNew, int index) {
    return Container(
      key: ValueKey('front_$index'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ⭐ 收藏按鈕（左上角）
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: Icon(
                p.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: p.isBookmarked ? Colors.amber : Colors.grey.shade400,
                size: 28,
              ),
              onPressed: () {
                final newState = !p.isBookmarked;
                setState(() {
                  _cards[index] = _StudyCard(
                    progress: WordProgress(
                      id: p.id,
                      userId: p.userId,
                      vocabId: p.vocabId,
                      status: p.status,
                      familiarity: p.familiarity,
                      easeFactor: p.easeFactor,
                      intervalDays: p.intervalDays,
                      nextReviewAt: p.nextReviewAt,
                      timesSeen: p.timesSeen,
                      timesCorrect: p.timesCorrect,
                      createdAt: p.createdAt,
                      updatedAt: p.updatedAt,
                      word: p.word,
                      reading: p.reading,
                      meaning: p.meaning,
                      partOfSpeech: p.partOfSpeech,
                      exampleSentence: p.exampleSentence,
                      exampleMeaning: p.exampleMeaning,
                      level: p.level,
                      isBookmarked: newState,
                    ),
                    isNew: isNew,
                  );
                });
                WordService.toggleBookmark(p.id, newState);
              },
            ),
          ),
          // 新卡 / 複習標籤
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNew
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isNew ? '🆕 新' : '🔄 複習',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isNew ? Colors.orange : Colors.blue,
                ),
              ),
            ),
          ),
          // 翻面提示
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '👆 點擊翻面看例句',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          // 主要內容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.reading ?? '',
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  p.word ?? '',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    p.meaning ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (p.partOfSpeech != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.partOfSpeech!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 字卡背面（例句）
  Widget _buildCardBack(WordProgress p, int index) {
    return Container(
      key: ValueKey('back_$index'),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.word ?? '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 24),
              if (p.exampleSentence != null && p.exampleSentence!.isNotEmpty) ...[
                const Text(
                  '📝 例句',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  p.exampleSentence!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  p.exampleMeaning ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else
                Text(
                  '暫無例句',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                '👆 點擊翻回正面',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 處理滑動邏輯：更新 SM-2 進度
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final card = _cards[previousIndex];
    final p = card.progress;
    final isCorrect = direction == CardSwiperDirection.right;

    // 非同步更新資料庫（不阻塞 UI）
    WordService.updateProgress(
      progressId: p.id,
      isCorrect: isCorrect,
      currentFamiliarity: p.familiarity,
      currentEF: p.easeFactor,
      currentInterval: p.intervalDays,
      timesSeen: p.timesSeen,
      timesCorrect: p.timesCorrect,
    );

    // 更新 daily session
    _updateSessionProgress(card.isNew, isCorrect);

    setState(() {
      _completedCount++;
      if (_completedCount >= _totalCount) {
        _isCompleted = true;
        // 標記今日任務完成
        DailyTaskService.updateSession(isCompleted: true);
      }
    });

    return true;
  }

  /// 更新今日 session 的計數
  Future<void> _updateSessionProgress(bool isNew, bool isCorrect) async {
    try {
      final session = await DailyTaskService.getOrCreateTodaySession();
      if (isNew) {
        await DailyTaskService.updateSession(
          wordsNew: (session['words_new'] as int? ?? 0) + 1,
        );
      } else {
        await DailyTaskService.updateSession(
          wordsReviewed: (session['words_reviewed'] as int? ?? 0) + 1,
        );
      }
    } catch (_) {}
  }
}

/// 學習用字卡（包含進度資訊 + 是否為新卡標記）
class _StudyCard {
  final WordProgress progress;
  final bool isNew;

  _StudyCard({required this.progress, required this.isNew});
}
