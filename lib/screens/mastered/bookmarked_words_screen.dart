// lib/screens/mastered/bookmarked_words_screen.dart

import 'package:flutter/material.dart';
import '../../models/word_progress.dart';
import '../../services/word_service.dart';
import '../../utils/shimmer_loading.dart';

class BookmarkedWordsScreen extends StatefulWidget {
  const BookmarkedWordsScreen({super.key});

  @override
  State<BookmarkedWordsScreen> createState() => _BookmarkedWordsScreenState();
}

class _BookmarkedWordsScreenState extends State<BookmarkedWordsScreen> {
  List<WordProgress> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarked();
  }

  Future<void> _loadBookmarked() async {
    setState(() => _isLoading = true);
    try {
      final data = await WordService.getBookmarkedWords();
      if (mounted) {
        setState(() {
          _words = data.map((e) => WordProgress.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeBookmark(WordProgress word) async {
    await WordService.toggleBookmark(word.id, false);
    setState(() => _words.removeWhere((w) => w.id == word.id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已取消收藏「${word.word}」')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const ShimmerLoading(itemCount: 5, type: ShimmerType.list)
          : _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        '還沒有收藏任何單字',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '在字卡頁面點擊 ⭐ 即可收藏',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookmarked,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _words.length,
                    itemBuilder: (context, index) {
                      final word = _words[index];
                      return Dismissible(
                        key: Key('bookmark_${word.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        onDismissed: (_) => _removeBookmark(word),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('⭐', style: TextStyle(fontSize: 20)),
                              ),
                            ),
                            title: Text(
                              word.word ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${word.reading ?? ''} ・ ${word.meaning ?? ''}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.bookmark_remove,
                                  color: Colors.amber),
                              onPressed: () => _removeBookmark(word),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
