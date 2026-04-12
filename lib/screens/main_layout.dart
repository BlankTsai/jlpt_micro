import 'package:flutter/material.dart';

import 'home/swipe_screen.dart'; // Tab 0: 單字滑動
import 'grammar/grammar_screen.dart'; // Tab 1: 文法
import 'reading/reading_screen.dart'; // Tab 2: 聽讀
import 'profile/profile_screen.dart'; // Tab 3: 個人設定

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 記錄目前選中的分頁索引 (預設為 0，也就是單字滑動頁)
  int _currentIndex = 0;

  // 將四個分頁畫面放進一個 List 中
  final List<Widget> _pages = const [
    SwipeScreen(),
    GrammarScreen(),
    ReadingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 IndexedStack 包裝，以保留各分頁的狀態
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        // 當分頁超過 3 個時，必須設定為 fixed，否則 icon 會變成白色消失
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal, // 選中的顏色
        unselectedItemColor: Colors.grey, // 未選中的顏色
        onTap: (index) {
          // 當使用者點擊底部按鈕時，更新狀態切換畫面
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.style), // 圖示可以隨你喜好更換
            label: '每日字卡',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '文法'),
          BottomNavigationBarItem(icon: Icon(Icons.headset), label: '聽讀'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '個人'),
        ],
      ),
    );
  }
}
