// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  /// 取得目前登入的使用者
  static User? get currentUser => _client.auth.currentUser;

  /// 取得目前的 Session
  static Session? get currentSession => _client.auth.currentSession;

  /// 是否已登入
  static bool get isLoggedIn => currentSession != null;

  /// 登入
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 註冊
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  /// 登出
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 發送密碼重置信
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
