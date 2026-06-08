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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        animationDuration: const Duration(milliseconds: 400),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: '每日字卡',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '文法',
          ),
          NavigationDestination(
            icon: Icon(Icons.headset_outlined),
            selectedIcon: Icon(Icons.headset),
            label: '聽讀',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: '個人',
          ),
        ],
      ),
    );
  }
}
