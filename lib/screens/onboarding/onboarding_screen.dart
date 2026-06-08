// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // 記錄使用者選擇的難度，預設 N5
  String _selectedLevel = 'N5';

  // 當使用者看完引導頁，按下完成時觸發
  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // 標記已經不是第一次開啟了！
    await prefs.setBool('isFirstTime', false);
    // 把難度也存起來，之後抓單字可以用
    await prefs.setString('targetLevel', _selectedLevel);

    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "每天 5 分鐘",
          body: "繁忙的現代生活，無需死記硬背。利用通勤的零碎時間，每天輕鬆累積日文實力。",
          image: const Center(
            child: Icon(Icons.timer, size: 120, color: Colors.teal),
          ),
          decoration: const PageDecoration(pageColor: Colors.white),
        ),
        PageViewModel(
          title: "滑動記憶法",
          body: "向右滑代表記住了，向左滑代表還不熟。\n我們會自動為你安排最聰明的複習計畫。",
          image: const Center(
            child: Icon(Icons.swipe, size: 120, color: Colors.teal),
          ),
          decoration: const PageDecoration(pageColor: Colors.white),
        ),
        PageViewModel(
          title: "選擇你的目標",
          bodyWidget: Column(
            children: [
              const Text("請選擇你目前想挑戰的 JLPT 級別：", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              // 難度選擇下拉式選單
              DropdownButton<String>(
                value: _selectedLevel,
                items: ['N5', 'N4', 'N3', 'N2', 'N1'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      'JLPT $value',
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedLevel = newValue!;
                  });
                },
              ),
            ],
          ),
          image: const Center(
            child: Icon(Icons.flag, size: 120, color: Colors.teal),
          ),
          decoration: const PageDecoration(pageColor: Colors.white),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // 允許使用者跳過
      showSkipButton: true,
      skip: const Text(
        "跳過",
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
      ),
      next: const Icon(Icons.arrow_forward, color: Colors.teal),
      done: const Text(
        "開始學習",
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Colors.teal,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
