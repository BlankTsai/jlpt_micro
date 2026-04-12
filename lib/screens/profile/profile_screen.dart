import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('這裡是使用者個人頁面', style: TextStyle(fontSize: 24))),
    );
  }
}
