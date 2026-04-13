// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../splash/splash_screen.dart'; // 引入啟動頁以便重置跳轉

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 變數：用來存放從本機讀取出來的目標級別
  String _targetLevel = '載入中...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 非同步函式：讀取 SharedPreferences 的資料
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 如果找不到 targetLevel，預設顯示 N5
      _targetLevel = prefs.getString('targetLevel') ?? 'N5';
    });
  }

  // 開發測試用：清除所有本機紀錄，並重新啟動 App
  Future<void> _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 清除標記！App 會以為你是第一次打開

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '個人主頁',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部大頭貼與名稱
            const Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '學習者',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '保持每天學習的節奏！',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 數據儀表板 (目前先放假資料展示 UI)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('目標', 'JLPT $_targetLevel', Icons.flag),
                  _buildStatItem('連續打卡', '3 天', Icons.local_fire_department),
                  _buildStatItem('熟記單字', '42', Icons.check_circle),
                ],
              ),
            ),

            const Spacer(), // 把下面的按鈕推到畫面最底部
            // 重置按鈕 (開發期間非常實用)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  '重置 App (重新測試引導頁)',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: _resetApp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 輔助函式：用來快速產生數據卡片的小工具
  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.teal),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
