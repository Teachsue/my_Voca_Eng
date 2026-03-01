import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'todays_quiz_result_page.dart';
import 'theme_manager.dart';

class QuizPage extends StatefulWidget {
  final List<Word> dayWords;
  final int questionCount;
  final String category;
  final String level;
  final int? dayNumber;
  final bool isWrongAnswerQuiz;

  const QuizPage({
    super.key,
    required this.dayWords,
    this.questionCount = 0,
    this.category = '',
    this.level = '',
    this.dayNumber,
    this.isWrongAnswerQuiz = false,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  int _score = 0;
  List<Map<String, dynamic>> _quizData = [];
  List<Map<String, dynamic>> _wrongAnswersList = [];
  bool _isChecked = false;
  bool _isCorrect = false;
  String? _userSelectedAnswer;
  late String _cacheKey;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  void _initializeQuiz() {
    _cacheKey = widget.isWrongAnswerQuiz ? "quiz_progress_wrong" : "quiz_progress_${widget.category}_${widget.level}_${widget.dayNumber ?? 'all'}";
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResumeDialog(savedData));
    } else {
      if (widget.questionCount > 0) _loadNewQuizData(widget.questionCount);
      else if (widget.dayWords.length > 30) WidgetsBinding.instance.addPostFrameCallback((_) => _showQuestionCountSelection());
      else _loadNewQuizData(widget.dayWords.length);
    }
  }

  void _showResumeDialog(dynamic savedData) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 24),
            Text("퀴즈 이어 풀기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: ThemeManager.textColor)),
            const SizedBox(height: 12),
            Text("이전에 풀던 기록이 있습니다.\n이어서 푸시겠습니까?", textAlign: TextAlign.center, style: TextStyle(color: ThemeManager.subTextColor, fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () { _clearProgress(); Navigator.pop(context, true); _initializeQuiz(); },
                    child: Text("새로 풀기", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(context, true); _restoreFromCache(savedData); },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text("이어서 풀기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionCountSelection() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("문제 수 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: ThemeManager.textColor)),
              const SizedBox(height: 24),
              ...[10, 20, 30].map((count) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () { Navigator.pop(dialogContext, true); _loadNewQuizData(count); },
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: primaryColor.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text("$count문제", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _loadNewQuizData(int count) {
    List<Word> shuffled = List<Word>.from(widget.dayWords)..shuffle();
    List<Word> selected = shuffled.take(count).toList();
    final box = Hive.box<Word>('words');
    final allWords = box.values.where((w) => w.type == 'Word').toList();
    _quizData = [];
    final random = Random();
    for (var word in selected) {
      bool isSpellingToMeaning = random.nextBool();
      String question; String correctAnswer; Map<String, String> answerToInfo = {};
      if (isSpellingToMeaning) {
        question = word.spelling; correctAnswer = word.meaning;
        List<Word> distractors = allWords.where((w) => w.meaning != correctAnswer).toList()..shuffle();
        answerToInfo[correctAnswer] = word.spelling;
        for (var d in distractors.take(3)) answerToInfo[d.meaning] = d.spelling;
      } else {
        question = word.meaning; correctAnswer = word.spelling;
        List<Word> distractors = allWords.where((w) => w.spelling != correctAnswer).toList()..shuffle();
        answerToInfo[correctAnswer] = word.meaning;
        for (var d in distractors.take(3)) answerToInfo[d.spelling] = d.meaning;
      }
      List<String> options = answerToInfo.keys.toList()..shuffle();
      _quizData.add({'question': question, 'correctAnswer': correctAnswer, 'options': options, 'answerToInfo': answerToInfo, 'isSpellingToMeaning': isSpellingToMeaning, 'spelling': word.spelling});
    }
    setState(() {});
  }

  void _restoreFromCache(dynamic savedData) {
    setState(() {
      _currentIndex = savedData['index'] ?? 0;
      _score = savedData['score'] ?? 0;
      _quizData = (savedData['quizData'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      _wrongAnswersList = (savedData['wrongAnswers'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;
    final current = _quizData[_currentIndex];
    bool correct = (selectedAnswer == current['correctAnswer']);
    if (correct) _score++;
    else _wrongAnswersList.add({'spelling': current['spelling'], 'userAnswer': selectedAnswer, 'correctAnswer': current['correctAnswer']});
    setState(() { _isChecked = true; _userSelectedAnswer = selectedAnswer; _isCorrect = correct; });
    _saveProgress();
  }

  void _nextQuestion() {
    if (_currentIndex < _quizData.length - 1) {
      setState(() { _currentIndex++; _isChecked = false; _userSelectedAnswer = null; });
      _saveProgress();
    } else {
      _clearProgress();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TodaysQuizResultPage(wrongAnswers: _wrongAnswersList, totalCount: _quizData.length, isTodaysQuiz: false)));
    }
  }

  void _saveProgress() { Hive.box('cache').put(_cacheKey, {'index': _currentIndex, 'score': _score, 'quizData': _quizData, 'wrongAnswers': _wrongAnswersList}); }
  void _clearProgress() { Hive.box('cache').delete(_cacheKey); }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    if (_quizData.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final current = _quizData[_currentIndex];
    final options = current['options'] as List<String>;
    final answerToInfo = Map<String, String>.from(current['answerToInfo']);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.isWrongAnswerQuiz ? "오답노트 퀴즈" : "퀴즈 (${_currentIndex + 1}/${_quizData.length})", style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () { _saveProgress(); Navigator.pop(context); }),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? (_isCorrect ? Colors.green[400] : primaryColor) : (isDark ? Colors.white10 : Colors.grey[300]),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text(_isChecked ? (_currentIndex < _quizData.length - 1 ? "다음 문제" : "결과 보기") : "정답을 선택하세요", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]),
              child: Column(
                children: [
                  Text(current['isSpellingToMeaning'] ? "뜻을 선택하세요" : "단어를 선택하세요", style: TextStyle(color: ThemeManager.subTextColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Text(current['question'], textAlign: TextAlign.center, style: TextStyle(fontSize: current['isSpellingToMeaning'] ? 32 : 26, fontWeight: FontWeight.w900, color: ThemeManager.textColor)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ...options.map((option) {
              bool isCorrectOption = option == current['correctAnswer'];
              bool isSelected = option == _userSelectedAnswer;
              Color btnColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
              Color borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
              Color textColor = ThemeManager.textColor;
              if (_isChecked) {
                if (isCorrectOption) { btnColor = Colors.green[400]!.withOpacity(0.15); borderColor = Colors.green[400]!; textColor = isDark ? Colors.green[300]! : Colors.green[700]!; }
                else if (isSelected) { btnColor = Colors.red[400]!.withOpacity(0.15); borderColor = Colors.red[400]!; textColor = isDark ? Colors.red[300]! : Colors.red[700]!; }
                else { textColor = ThemeManager.subTextColor.withOpacity(0.5); }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 75),
                  child: OutlinedButton(
                    onPressed: () => _checkAnswer(option),
                    style: OutlinedButton.styleFrom(backgroundColor: btnColor, side: BorderSide(color: borderColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                    child: Text(_isChecked ? "$option\n(${answerToInfo[option]})" : option, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: isCorrectOption && _isChecked ? FontWeight.w900 : FontWeight.w700, color: textColor)),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
