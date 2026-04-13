import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secrets.dart';
//import 'screens/main_layout.dart';
import 'screens/splash/splash_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
