// lib/screens/mastered/mastered_grammar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/grammar.dart';
import '../../services/grammar_service.dart';

class MasteredGrammarScreen extends StatefulWidget {
  const MasteredGrammarScreen({super.key});

  @override
  State<MasteredGrammarScreen> createState() => _MasteredGrammarScreenState();
}

class _MasteredGrammarScreenState extends State<MasteredGrammarScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<_MasteredGrammarItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadMasteredGrammars();
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

  Future<void> _loadMasteredGrammars() async {
    setState(() => _isLoading = true);
    try {
      final data = await GrammarService.getMasteredGrammars();
      final items = data.map((json) {
        final grammarData = json['grammars'] as Map<String, dynamic>? ?? {};
        return _MasteredGrammarItem(
          grammar: Grammar.fromJson({
            ...grammarData,
            'id': json['grammar_id'],
          }),
          progressId: json['id'] as int,
        );
      }).toList();

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 取消「已學會」標記，重新放回學習佇列
  Future<void> _unmaster(_MasteredGrammarItem item, int index) async {
    try {
      await GrammarService.markAsLearning(item.progressId);
      setState(() {
        _items.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${item.grammar.title}」已放回學習佇列'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失敗'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '已學會的文法',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    '還沒有學會的文法\n繼續加油！💪',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final grammar = item.grammar;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(
                          grammar.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            grammar.exampleCh,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                onPressed: () => _speak(grammar.exampleJp),
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Colors.teal,
                                ),
                                label: const Text(
                                  '朗讀',
                                  style: TextStyle(color: Colors.teal),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _unmaster(item, index),
                                icon: const Icon(
                                  Icons.replay,
                                  color: Colors.orange,
                                ),
                                label: const Text(
                                  '重新學習',
                                  style: TextStyle(color: Colors.orange),
                                ),
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
}

class _MasteredGrammarItem {
  final Grammar grammar;
  final int progressId;

  _MasteredGrammarItem({
    required this.grammar,
    required this.progressId,
  });
}
