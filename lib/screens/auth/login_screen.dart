// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/daily_task_service.dart';
import '../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true; // 密碼顯示/隱藏

  // Email 格式驗證
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return '請輸入電子信箱';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) return '請輸入有效的電子信箱格式';
    return null;
  }

  // 密碼驗證
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return '請輸入密碼';
    if (value.trim().length < 6) return '密碼至少需要 6 個字元';
    return null;
  }

  // 核心邏輯：向 Supabase 發送認證請求
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await AuthService.signIn(email: email, password: password);
      } else {
        await AuthService.signUp(email: email, password: password);
      }

      // 登入/註冊成功後，將本機的級別設定同步到雲端
      final prefs = await SharedPreferences.getInstance();
      final localLevel = prefs.getString('targetLevel');
      if (localLevel != null) {
        await DailyTaskService.setTargetLevel(localLevel);
      }

      // 成功後，跳轉到 App 主畫面
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('發生錯誤: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('發生未知的錯誤'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 忘記密碼
  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('忘記密碼'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('請輸入您的電子信箱，我們將發送密碼重置連結給您。'),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: '電子信箱',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('發送重置信', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final email = resetEmailController.text.trim();
      if (email.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('請輸入電子信箱'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      try {
        await AuthService.resetPassword(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('密碼重置信已發送，請檢查您的信箱！'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('發送失敗：$e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    resetEmailController.dispose();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.translate,
                  size: 80,
                  color: isDark ? Colors.teal.shade300 : Colors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  'JLPT Micro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.teal.shade300 : Colors.teal,
                  ),
                ),
                const SizedBox(height: 40),

                // 信箱輸入框（含驗證）
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: '電子信箱',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // 密碼輸入框（含驗證 + 顯示/隱藏切換）
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: '密碼 (至少 6 碼)',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // 登入/註冊按鈕
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isLogin ? '登入' : '註冊帳號',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 切換模式
                TextButton(
                  onPressed: () {
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: Text(
                    _isLogin ? '還沒有帳號嗎？點此註冊' : '已經有帳號了？點此登入',
                    style: const TextStyle(color: Colors.teal, fontSize: 16),
                  ),
                ),

                // 忘記密碼（僅登入模式）
                if (_isLogin)
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      '忘記密碼？',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
