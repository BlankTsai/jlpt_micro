// lib/screens/grammar/grammar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/grammar.dart';
import '../../services/grammar_service.dart';
import '../../services/daily_task_service.dart';
import '../../utils/shimmer_loading.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  List<_GrammarItem> _items = [];
  bool _isLoading = true;
  bool _isCompleted = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadDailyGrammars();
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

  /// 載入今日文法（新 + 複習）
  Future<void> _loadDailyGrammars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final level = await DailyTaskService.getTargetLevel();

      // 取得需要複習的文法
      final reviewData = await GrammarService.getReviewGrammars(limit: 5);
      final reviewItems = reviewData.map((json) {
        final grammarData = json['grammars'] as Map<String, dynamic>? ?? {};
        return _GrammarItem(
          grammar: Grammar.fromJson({...grammarData, 'id': json['grammar_id']}),
          progressId: json['id'] as int,
          status: json['status'] ?? 'learning',
          isNew: false,
        );
      }).toList();

      // 取得新文法
      final newData = await GrammarService.getNewGrammars(
        level: level,
        limit: DailyTaskService.dailyGrammars,
      );

      final newItems = <_GrammarItem>[];
      for (final data in newData) {
        final grammar = Grammar.fromJson(data);
        await GrammarService.createProgress(grammar.id);
        newItems.add(_GrammarItem(
          grammar: grammar,
          progressId: null, // 稍後需要重新查詢
          status: 'learning',
          isNew: true,
        ));
      }

      // 重新查詢新建立的進度記錄以取得 progressId
      if (newItems.isNotEmpty) {
        final freshReview = await GrammarService.getReviewGrammars(limit: 30);
        for (var i = 0; i < newItems.length; i++) {
          final match = freshReview.where(
            (r) => r['grammar_id'] == newItems[i].grammar.id,
          );
          if (match.isNotEmpty) {
            newItems[i] = _GrammarItem(
              grammar: newItems[i].grammar,
              progressId: match.first['id'] as int,
              status: 'learning',
              isNew: true,
            );
          }
        }
      }

      final allItems = [...reviewItems, ...newItems];

      setState(() {
        _items = allItems;
        _isLoading = false;
        _isCompleted = allItems.isEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入失敗：$e';
      });
    }
  }

  /// 載入額外文法
  Future<void> _loadBonusGrammars() async {
    setState(() => _isLoading = true);
    try {
      final level = await DailyTaskService.getTargetLevel();
      final newData = await GrammarService.getNewGrammars(level: level, limit: 3);
      final reviewData = await GrammarService.getReviewGrammars(limit: 3);

      final newItems = <_GrammarItem>[];
      for (final data in newData) {
        final grammar = Grammar.fromJson(data);
        await GrammarService.createProgress(grammar.id);
        newItems.add(_GrammarItem(
          grammar: grammar,
          progressId: null,
          status: 'learning',
          isNew: true,
        ));
      }

      // 重新查詢取得 progressId
      if (newItems.isNotEmpty) {
        final freshReview = await GrammarService.getReviewGrammars(limit: 30);
        for (var i = 0; i < newItems.length; i++) {
          final match = freshReview.where(
            (r) => r['grammar_id'] == newItems[i].grammar.id,
          );
          if (match.isNotEmpty) {
            newItems[i] = _GrammarItem(
              grammar: newItems[i].grammar,
              progressId: match.first['id'] as int,
              status: 'learning',
              isNew: true,
            );
          }
        }
      }

      final reviewItems = reviewData.map((json) {
        final grammarData = json['grammars'] as Map<String, dynamic>? ?? {};
        return _GrammarItem(
          grammar: Grammar.fromJson({...grammarData, 'id': json['grammar_id']}),
          progressId: json['id'] as int,
          status: json['status'] ?? 'learning',
          isNew: false,
        );
      }).toList();

      setState(() {
        _items = [...reviewItems, ...newItems];
        _isLoading = false;
        _isCompleted = _items.isEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入失敗：$e';
      });
    }
  }

  /// 標記為已學會（加入確認對話框提高門檻）
  Future<void> _markMastered(_GrammarItem item, int index) async {
    if (item.progressId == null) return;

    // 確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認已學會'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你確定已經學會「${item.grammar.title}」了嗎？'),
            const SizedBox(height: 12),
            Text(
              '意思：${item.grammar.meaning}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('再複習一下'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確定學會了！'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic UI
    setState(() {
      _items[index] = _GrammarItem(
        grammar: item.grammar,
        progressId: item.progressId,
        status: 'mastered',
        isNew: item.isNew,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已將「${item.grammar.title}」標記為學會！'),
          backgroundColor: Colors.teal,
        ),
      );
    }

    if (_items.every((i) => i.status == 'mastered')) {
      setState(() => _isCompleted = true);
    }

    _persistMastered(item.progressId!);
  }

  /// 背景持久化已學會的狀態
  Future<void> _persistMastered(int progressId) async {
    try {
      await Future.wait([
        GrammarService.markAsMastered(progressId),
        _updateGrammarSessionCount(),
      ]);
      if (_items.every((i) => i.status == 'mastered')) {
        await DailyTaskService.updateSession(isCompleted: true);
      }
    } catch (_) {
      // 靜默失敗，下次重新載入會修正狀態
    }
  }

  Future<void> _updateGrammarSessionCount() async {
    final session = await DailyTaskService.getOrCreateTodaySession();
    await DailyTaskService.updateSession(
      grammarsCompleted: (session['grammars_completed'] as int? ?? 0) + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '核心文法',
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
      return const ShimmerLoading(itemCount: 4, type: ShimmerType.card);
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyGrammars,
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
      onRefresh: _loadDailyGrammars,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _items.length,
        itemBuilder: (context, index) {
        final item = _items[index];
        final grammar = item.grammar;
        final isMastered = item.status == 'mastered';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: Icon(
              isMastered ? Icons.check_circle : (item.isNew ? Icons.fiber_new : Icons.replay),
              color: isMastered ? Colors.green : (item.isNew ? Colors.orange : Colors.blue),
            ),
            title: Text(
              grammar.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: isMastered ? TextDecoration.lineThrough : null,
                color: isMastered ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              grammar.meaning,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const Text(
                '📝 例句：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                grammar.exampleJp,
                style: const TextStyle(fontSize: 18, color: Colors.teal),
              ),
              const SizedBox(height: 4),
              Text(
                grammar.exampleCh,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () => _speak(grammar.exampleJp),
                    icon: const Icon(Icons.volume_up, color: Colors.teal),
                    label: const Text('朗讀例句', style: TextStyle(color: Colors.teal)),
                  ),
                  if (!isMastered)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('已學會'),
                      onPressed: () => _markMastered(item, index),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
            const Icon(Icons.menu_book, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            const Text(
              '🎉 今日文法任務完成！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '文法基礎越來越穩固了！',
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
                  '繼續學更多文法！',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _loadBonusGrammars,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarItem {
  final Grammar grammar;
  final int? progressId;
  final String status;
  final bool isNew;

  _GrammarItem({
    required this.grammar,
    required this.progressId,
    required this.status,
    required this.isNew,
  });
}
