// lib/screens/grammar/grammar_screen.dart

import 'package:flutter/material.dart';

class GrammarScreen extends StatelessWidget {
  const GrammarScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 8.0),
            child: Text(
              'N5 必備句型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          _buildGrammarCard(
            title: '〜は〜です',
            meaning: '...是...',
            exampleJP: '私は学生です。',
            exampleCH: '我是學生。',
          ),
          _buildGrammarCard(
            title: '〜にあります / います',
            meaning: '有... / 在...',
            exampleJP: '机の上に本があります。',
            exampleCH: '桌子上有書。',
          ),
          _buildGrammarCard(
            title: '〜ませんか',
            meaning: '要不要一起...？(邀約)',
            exampleJP: '一緒にご飯を食べませんか。',
            exampleCH: '要不要一起吃飯呢？',
          ),
        ],
      ),
    );
  }

  // 輔助函式：繪製可展開的文法卡片
  Widget _buildGrammarCard({
    required String title,
    required String meaning,
    required String exampleJP,
    required String exampleCH,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(meaning, style: TextStyle(color: Colors.grey.shade700)),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text('📝 例句：', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            exampleJP,
            style: const TextStyle(fontSize: 18, color: Colors.teal),
          ),
          const SizedBox(height: 4),
          Text(
            exampleCH,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
