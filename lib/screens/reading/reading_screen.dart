import 'package:flutter/material.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('這裡是新聞聽讀頁面', style: TextStyle(fontSize: 24))),
    );
  }
}
