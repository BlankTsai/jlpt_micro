// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_layout.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  // 檢查是否為初次使用
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // 取得標記，如果沒有值 (null) 代表是第一次開啟，預設為 true
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    // 稍微延遲一下，讓使用者看到啟動畫面 (可選)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 因為 Widget 可能已經不在畫面上，需檢查 mounted
    if (!mounted) return;

    if (isFirstTime) {
      // 是第一次，去引導頁 (使用 pushReplacement 避免使用者按返回鍵回到這裡)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // 不是第一次，直接去主畫面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'JLPT Micro',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white), // 載入圈圈
          ],
        ),
      ),
    );
  }
}
