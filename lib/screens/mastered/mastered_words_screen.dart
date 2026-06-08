// lib/screens/mastered/mastered_words_screen.dart

import 'package:flutter/material.dart';
import '../../models/word_progress.dart';
import '../../services/word_service.dart';

class MasteredWordsScreen extends StatefulWidget {
  const MasteredWordsScreen({super.key});

  @override
  State<MasteredWordsScreen> createState() => _MasteredWordsScreenState();
}

class _MasteredWordsScreenState extends State<MasteredWordsScreen> {
  List<WordProgress> _words = [];
  List<WordProgress> _filteredWords = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMasteredWords();
  }

  Future<void> _loadMasteredWords() async {
    setState(() => _isLoading = true);
    try {
      final data = await WordService.getMasteredWords();
      final words = data.map((json) => WordProgress.fromJson(json)).toList();
      setState(() {
        _words = words;
        _filteredWords = words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterWords(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredWords = _words;
      } else {
        _filteredWords = _words.where((w) {
          final word = (w.word ?? '').toLowerCase();
          final reading = (w.reading ?? '').toLowerCase();
          final meaning = (w.meaning ?? '').toLowerCase();
          final q = query.toLowerCase();
          return word.contains(q) || reading.contains(q) || meaning.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '已學會的單字',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜尋框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterWords,
              decoration: InputDecoration(
                hintText: '搜尋單字、讀音或意思...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // 計數
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '共 ${_filteredWords.length} 個單字',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWords.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? '還沒有學會的單字\n繼續加油！💪'
                              : '找不到符合的單字',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredWords.length,
                        itemBuilder: (context, index) {
                          final word = _filteredWords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: Text(
                                  word.level ?? 'N5',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    word.word ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    word.reading ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(word.meaning ?? ''),
                              trailing: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
