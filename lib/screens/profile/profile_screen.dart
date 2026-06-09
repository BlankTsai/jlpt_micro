// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/word_service.dart';
import '../../services/grammar_service.dart';
import '../../services/daily_task_service.dart';
import '../../services/achievement_service.dart';
import '../../utils/shimmer_loading.dart';
import '../../utils/page_transitions.dart';
import '../splash/splash_screen.dart';
import '../mastered/mastered_words_screen.dart';
import '../mastered/mastered_grammar_screen.dart';
import '../mastered/bookmarked_words_screen.dart';
import '../quiz/quiz_screen.dart';
import '../achievements/achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _targetLevel = '載入中...';
  int _streak = 0;
  int _masteredWords = 0;
  int _masteredGrammars = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyData = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final level = await DailyTaskService.getTargetLevel();
      final streak = await DailyTaskService.getStreak();
      final masteredWords = await WordService.getMasteredCount();
      final masteredGrammars = await GrammarService.getMasteredCount();
      final weeklyData = await _loadWeeklyStats();

      if (mounted) {
        setState(() {
          _targetLevel = level;
          _streak = streak;
          _masteredWords = masteredWords;
          _masteredGrammars = masteredGrammars;
          _weeklyData = weeklyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 載入最近 7 天的學習數據
  Future<List<Map<String, dynamic>>> _loadWeeklyStats() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final startDate = sevenDaysAgo.toIso8601String().substring(0, 10);

      final data = await DailyTaskService.getRecentSessions(
        startDate: startDate,
        limit: 7,
      );
      return data;
    } catch (_) {
      return [];
    }
  }

  /// 檢查並顯示新解鎖的成就
  Future<void> _checkNewAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievements = await AchievementService.checkAchievements();

      for (final a in achievements) {
        if (a.unlocked) {
          final key = 'achievement_shown_${a.id}';
          final alreadyShown = prefs.getBool(key) ?? false;
          if (!alreadyShown && mounted) {
            await prefs.setBool(key, true);
            if (!mounted) return;
            showAchievementUnlocked(context, a);
            break; // 一次只顯示一個
          }
        }
      }
    } catch (_) {}
  }

  /// 登出
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('登出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  /// 切換目標級別
  Future<void> _changeLevel() async {
    final levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('選擇目標級別'),
        children: levels.map((level) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, level),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    level == _targetLevel
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'JLPT $level',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: level == _targetLevel
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null && selected != _targetLevel) {
      await DailyTaskService.setTargetLevel(selected);
      setState(() => _targetLevel = selected);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('目標已切換為 JLPT $selected')),
        );
      }
    }
  }

  /// 重置 App (開發用)
  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置 App'),
        content: const Text('此操作會清除所有本機設定，確定嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確定重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '學習者';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '個人主頁',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const ShimmerLoading(itemCount: 5, type: ShimmerType.list)
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 大頭貼與名稱
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: isDark ? Colors.teal.shade700 : Colors.teal,
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                '保持每天學習的節奏！',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 數據儀表板
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            '目標',
                            'JLPT $_targetLevel',
                            Icons.flag,
                          ),
                          _buildStatItem(
                            '連續打卡',
                            '$_streak 天',
                            Icons.local_fire_department,
                          ),
                          _buildStatItem(
                            '熟記單字',
                            '$_masteredWords',
                            Icons.check_circle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 📊 本週學習統計圖表
                    _buildWeeklyChart(isDark),
                    const SizedBox(height: 24),

                    // 功能列表
                    _buildMenuTile(
                      icon: Icons.collections_bookmark,
                      title: '已學會的單字',
                      subtitle: '共 $_masteredWords 個',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          SlidePageRoute(page: const MasteredWordsScreen()),
                        );
                        _loadUserData();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.library_books,
                      title: '已學會的文法',
                      subtitle: '共 $_masteredGrammars 條',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          SlidePageRoute(page: const MasteredGrammarScreen()),
                        );
                        _loadUserData();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.bookmark,
                      title: '我的收藏',
                      subtitle: '收藏的重點單字',
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: const BookmarkedWordsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuTile(
                      icon: Icons.quiz,
                      title: '模擬測驗',
                      subtitle: '測試你的學習成果',
                      onTap: () async {
                        final score = await Navigator.push<int>(
                          context,
                          SlidePageRoute(page: const QuizScreen()),
                        );
                        // 檢查是否解鎖新成就
                        if (score != null && mounted) {
                          _checkNewAchievements();
                          if (score == 100) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('best_quiz_score', 100);
                          }
                        }
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.emoji_events,
                      title: '學習成就',
                      subtitle: '查看你的徽章收集',
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: const AchievementsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuTile(
                      icon: Icons.swap_horiz,
                      title: '切換目標級別',
                      subtitle: '目前: JLPT $_targetLevel',
                      onTap: _changeLevel,
                    ),
                    const SizedBox(height: 24),

                    // 登出按鈕
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('登出', style: TextStyle(fontSize: 16)),
                        onPressed: _logout,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 重置按鈕 (開發用)
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
                          '重置 App (開發測試用)',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: _resetApp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 本週學習統計圖表
  Widget _buildWeeklyChart(bool isDark) {
    final now = DateTime.now();
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    // 建立 7 天的數據
    final List<double> dailyWords = List.filled(7, 0);
    for (final session in _weeklyData) {
      final date = DateTime.parse(session['session_date']);
      final daysAgo = now.difference(date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final index = 6 - daysAgo;
        dailyWords[index] =
            ((session['words_new'] ?? 0) + (session['words_reviewed'] ?? 0))
                .toDouble();
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 本週學習統計',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (dailyWords.reduce((a, b) => a > b ? a : b) + 5)
                    .clamp(10, 100),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} 字',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= 7) {
                          return const SizedBox();
                        }
                        final dayOfWeek =
                            now.subtract(Duration(days: 6 - idx)).weekday;
                        return Text(
                          weekdays[dayOfWeek - 1],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyWords[i],
                        color: Colors.teal.shade400,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
