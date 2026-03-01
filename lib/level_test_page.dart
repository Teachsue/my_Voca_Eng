import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';
import 'theme_manager.dart';

class LevelTestPage extends StatefulWidget {
  const LevelTestPage({super.key});

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage> {
  int _currentIndex = 0;
  int _score = 0;
  Map<String, int> _levelScores = {'500': 0, '700': 0, '900+': 0};
  List<Map<String, dynamic>> _testData = [];
  bool _isChecked = false;
  String? _userSelectedAnswer;
  final String _cacheKey = 'level_test_progress';

  @override
  void initState() {
    super.initState();
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);
    if (savedData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeDialog(savedData);
      });
    } else {
      _generateLevelTestData();
    }
  }

  void _showResumeDialog(dynamic savedData) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, color: Colors.amber, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                "테스트 이어 풀기",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: ThemeManager.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "진행 중이던 기록이 있습니다.\n이어서 푸시겠습니까?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ThemeManager.subTextColor,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _clearProgress();
                        Navigator.pop(context);
                        _generateLevelTestData();
                      },
                      child: Text(
                        "새로 풀기",
                        style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _restoreFromCache(savedData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("이어서 풀기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _restoreFromCache(dynamic savedData) {
    setState(() {
      _currentIndex = savedData['index'] ?? 0;
      _score = savedData['score'] ?? 0;
      final Map<dynamic, dynamic> rawScores = savedData['levelScores'] ?? {'500': 0, '700': 0, '900+': 0};
      _levelScores = rawScores.map((k, v) => MapEntry(k.toString(), v as int));
      _testData = (savedData['testData'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  void _generateLevelTestData() {
    final box = Hive.box<Word>('words');
    final allWords = box.values.where((w) => w.type == 'Word').toList();
    List<Word> testPool = [];
    final levels = ['500', '700', '900+'];
    for (var level in levels) {
      final levelWords = allWords.where((w) => w.level == level).toList();
      levelWords.shuffle();
      testPool.addAll(levelWords.take(5));
    }
    _testData = [];
    final random = Random();
    for (var word in testPool) {
      bool isSpellingToMeaning = random.nextBool();
      String question;
      String correctAnswer;
      Map<String, String> answerToInfo = {};
      if (isSpellingToMeaning) {
        question = word.spelling;
        correctAnswer = word.meaning;
        List<Word> distractors = allWords.where((w) => w.meaning != correctAnswer).toList();
        distractors.shuffle();
        answerToInfo[correctAnswer] = word.spelling;
        for (var d in distractors.take(3)) {
          answerToInfo[d.meaning] = d.spelling;
        }
      } else {
        question = word.meaning;
        correctAnswer = word.spelling;
        List<Word> distractors = allWords.where((w) => w.spelling != correctAnswer).toList();
        distractors.shuffle();
        answerToInfo[correctAnswer] = word.meaning;
        for (var d in distractors.take(3)) {
          answerToInfo[d.spelling] = d.meaning;
        }
      }
      List<String> options = answerToInfo.keys.toList();
      options.shuffle();
      _testData.add({
        'question': question,
        'correctAnswer': correctAnswer,
        'options': options,
        'answerToInfo': answerToInfo,
        'level': word.level,
        'isSpellingToMeaning': isSpellingToMeaning
      });
    }
    _saveProgress();
    setState(() {});
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;
    final currentQuestion = _testData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);
    if (correct) {
      _score++;
      _levelScores[currentQuestion['level']] = (_levelScores[currentQuestion['level']] ?? 0) + 1;
    }
    setState(() {
      _isChecked = true;
      _userSelectedAnswer = selectedAnswer;
    });
    _saveProgress();
  }

  void _nextQuestion() {
    if (_currentIndex < _testData.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _userSelectedAnswer = null;
      });
      _saveProgress();
    } else {
      _clearProgress();
      _showResultDialog();
    }
  }

  void _saveProgress() {
    Hive.box('cache').put(_cacheKey, {
      'index': _currentIndex,
      'score': _score,
      'levelScores': _levelScores,
      'testData': _testData,
    });
  }

  void _clearProgress() {
    Hive.box('cache').delete(_cacheKey);
  }

  void _showResultDialog() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    String recommendedLevel = '500';
    if (_levelScores['900+']! >= 3 && _levelScores['700']! >= 4 && _levelScores['500']! >= 4) {
      recommendedLevel = '900+';
    } else if (_levelScores['700']! >= 3 && _levelScores['500']! >= 3) {
      recommendedLevel = '700';
    } else {
      recommendedLevel = '500';
    }
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Hive.box('cache').put('user_recommended_level', recommendedLevel);
    Hive.box('cache').put('level_test_completed_date', todayStr);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.bar_chart_rounded, color: primaryColor, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                "테스트 결과 📊",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: ThemeManager.textColor),
              ),
              const SizedBox(height: 16),
              Text(
                "총 점수: $_score / ${_testData.length}",
                style: TextStyle(fontSize: 18, color: ThemeManager.subTextColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              Text(
                "추천 레벨",
                style: TextStyle(color: ThemeManager.subTextColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "TOEIC $recommendedLevel",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryColor),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("확인", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    if (_testData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final current = _testData[_currentIndex];
    final options = current['options'] as List<String>;
    final answerToInfo = Map<String, String>.from(current['answerToInfo']);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "실력 진단 테스트 (${_currentIndex + 1}/${_testData.length})",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            _saveProgress();
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? primaryColor : (isDark ? Colors.white10 : Colors.grey[300]),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _testData.length - 1 ? "다음 문제" : "결과 확인",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
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
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  Text(
                    current['isSpellingToMeaning'] ? "뜻을 선택하세요" : "단어를 선택하세요",
                    style: TextStyle(color: ThemeManager.subTextColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    current['question'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: current['isSpellingToMeaning'] ? 32 : 26, fontWeight: FontWeight.w900, color: ThemeManager.textColor),
                  ),
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
                if (isCorrectOption) {
                  btnColor = Colors.green[400]!.withOpacity(0.15);
                  borderColor = Colors.green[400]!;
                  textColor = isDark ? Colors.green[300]! : Colors.green[700]!;
                } else if (isSelected) {
                  btnColor = Colors.red[400]!.withOpacity(0.15);
                  borderColor = Colors.red[400]!;
                  textColor = isDark ? Colors.red[300]! : Colors.red[700]!;
                } else {
                  textColor = ThemeManager.subTextColor.withOpacity(0.5);
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 75),
                  child: OutlinedButton(
                    onPressed: () => _checkAnswer(option),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: btnColor,
                      side: BorderSide(color: borderColor, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: Text(
                      _isChecked ? "$option\n(${answerToInfo[option]})" : option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCorrectOption && _isChecked ? FontWeight.w900 : FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
