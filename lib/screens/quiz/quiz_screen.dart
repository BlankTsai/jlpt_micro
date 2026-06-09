// lib/screens/quiz/quiz_screen.dart

import 'package:flutter/material.dart';
import '../../services/quiz_service.dart';
import '../../services/daily_task_service.dart';
import '../../utils/shimmer_loading.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // 狀態
  String _phase = 'select'; // 'select', 'playing', 'result'
  String _quizType = 'vocab'; // 'vocab', 'grammar'
  bool _isLoading = false;

  // 題目
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedOption;
  bool _answered = false;

  // 答錯的題目（用於結果頁）
  final List<Map<String, String>> _wrongAnswers = [];

  // 動畫
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// 開始測驗
  Future<void> _startQuiz(String type) async {
    setState(() {
      _isLoading = true;
      _quizType = type;
    });

    final level = await DailyTaskService.getTargetLevel();

    List<QuizQuestion> questions;
    if (type == 'vocab') {
      questions = await QuizService.getVocabQuestions(level: level, count: 10);
    } else {
      questions =
          await QuizService.getGrammarQuestions(level: level, count: 10);
    }

    if (questions.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('題庫不足，至少需要 4 個項目')),
      );
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _questions = questions;
      _currentIndex = 0;
      _correctCount = 0;
      _selectedOption = null;
      _answered = false;
      _wrongAnswers.clear();
      _phase = 'playing';
      _isLoading = false;
    });
  }

  /// 選擇答案
  void _selectOption(String option) {
    if (_answered) return;

    final question = _questions[_currentIndex];
    final isCorrect = option == question.correctAnswer;

    if (isCorrect) {
      _correctCount++;
    } else {
      _wrongAnswers.add({
        'question': question.question,
        'yourAnswer': option,
        'correctAnswer': question.correctAnswer,
      });
    }

    setState(() {
      _selectedOption = option;
      _answered = true;
    });

    _feedbackController.forward(from: 0);

    // 1.2 秒後自動下一題
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _answered = false;
        });
      } else {
        setState(() => _phase = 'result');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase == 'select'
            ? '模擬測驗'
            : _phase == 'playing'
                ? '第 ${_currentIndex + 1} / ${_questions.length} 題'
                : '測驗結果'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading(itemCount: 4, type: ShimmerType.card);
    }

    switch (_phase) {
      case 'select':
        return _buildSelectPhase();
      case 'playing':
        return _buildPlayingPhase();
      case 'result':
        return _buildResultPhase();
      default:
        return const SizedBox();
    }
  }

  /// 選擇題型頁面
  Widget _buildSelectPhase() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 80,
            color: Colors.teal.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            '選擇測驗類型',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '每回合 10 題，測試你的學習成果！',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 48),
          _buildQuizTypeCard(
            icon: Icons.translate,
            title: '單字測驗',
            subtitle: '看日文單字，選正確的中文意思',
            onTap: () => _startQuiz('vocab'),
          ),
          const SizedBox(height: 16),
          _buildQuizTypeCard(
            icon: Icons.menu_book,
            title: '文法測驗',
            subtitle: '看文法意思，選正確的文法句型',
            onTap: () => _startQuiz('grammar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.teal.shade800
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 答題頁面
  Widget _buildPlayingPhase() {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
            ),
          ),
          const SizedBox(height: 32),

          // 題目
          Text(
            _quizType == 'vocab' ? '這個單字的意思是？' : '哪個文法符合這個意思？',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_quizType == 'vocab' &&
              question.extra?['reading'] != null) ...[
            const SizedBox(height: 8),
            Text(
              question.extra!['reading'],
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 40),

          // 選項
          ...question.options.map((option) => _buildOptionButton(option, question)),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, QuizQuestion question) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (!_answered) {
      bgColor = Theme.of(context).cardColor;
      borderColor = Colors.grey.shade300;
      textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    } else if (option == question.correctAnswer) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green;
      textColor = Colors.green.shade800;
    } else if (option == _selectedOption) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red;
      textColor = Colors.red.shade800;
    } else {
      bgColor = Theme.of(context).cardColor;
      borderColor = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleTransition(
        scale: (_answered && option == _selectedOption)
            ? _feedbackAnimation
            : const AlwaysStoppedAnimation(1.0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _answered ? null : () => _selectOption(option),
            style: OutlinedButton.styleFrom(
              backgroundColor: bgColor,
              side: BorderSide(color: borderColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_answered && option == question.correctAnswer)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
                if (_answered &&
                    option == _selectedOption &&
                    option != question.correctAnswer)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.cancel, color: Colors.red),
                  ),
                Flexible(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 成績結果頁面
  Widget _buildResultPhase() {
    final score = (_correctCount / _questions.length * 100).round();
    final isPerfect = score == 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 分數圓圈
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isPerfect
                    ? [Colors.amber.shade400, Colors.orange.shade400]
                    : score >= 60
                        ? [Colors.teal.shade400, Colors.green.shade400]
                        : [Colors.red.shade400, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPerfect ? Colors.amber : Colors.teal)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  '分',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPerfect
                ? '🎉 滿分！太厲害了！'
                : score >= 80
                    ? '👍 表現不錯！'
                    : score >= 60
                        ? '💪 繼續加油！'
                        : '📖 需要多複習喔！',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '答對 $_correctCount / ${_questions.length} 題',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // 答錯的題目
          if (_wrongAnswers.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '❌ 答錯的題目',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ...(_wrongAnswers.map((wrong) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wrong['question']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.cancel, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '你的答案：${wrong['yourAnswer']}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '正確答案：${wrong['correctAnswer']}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ))),
            const SizedBox(height: 24),
          ],

          // 操作按鈕
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _phase = 'select'),
                  icon: const Icon(Icons.replay),
                  label: const Text('再測一次'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, score),
                  icon: const Icon(Icons.check),
                  label: const Text('完成'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
