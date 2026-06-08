import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secrets.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  // 確保 Flutter 核心已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 使用 secrets.dart 裡的變數進行初始化
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JLPT Microlearning',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // 自動跟隨系統深色模式
      home: const SplashScreen(),
    );
  }
}
