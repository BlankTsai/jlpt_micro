// lib/screens/grammar/grammar_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrammarScreen extends StatelessWidget {
  const GrammarScreen({super.key});

  // 異步向 Supabase 請求文法資料
  Future<List<Map<String, dynamic>>> _fetchGrammars() async {
    final data = await Supabase.instance.client
        .from('grammars')
        .select()
        .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(data);
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGrammars(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('暫無文法資料'));
          }

          final grammars = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: grammars.length,
            itemBuilder: (context, index) {
              final grammar = grammars[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  title: Text(
                    grammar['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    grammar['meaning'],
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
                      grammar['example_jp'],
                      style: const TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      grammar['example_ch'],
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
