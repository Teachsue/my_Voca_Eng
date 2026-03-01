import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';

class LevelTestPage extends StatefulWidget {
  const LevelTestPage({super.key});

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage> {
  List<Map<String, dynamic>> _testData = [];
  int _currentIndex = 0;
  int _score = 0;
  Map<String, int> _levelScores = {'500': 0, '700': 0, '900+': 0};
  bool _isChecked = false;
  String? _userSelectedAnswer;
  bool _isCorrect = false;
  final String _cacheKey = "level_test_progress";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProgressAndInitialize();
    });
  }

  void _checkProgressAndInitialize() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);
    if (savedData != null) {
      int savedIndex = savedData['index'] ?? 0;
      if (savedIndex > 0) {
        _showResumeDialog(savedData);
      } else {
        _clearProgress();
        _generateLevelTestData();
      }
    } else {
      _generateLevelTestData();
    }
  }

  void _showResumeDialog(dynamic savedData) {
    showDialog(
      context: context,
      barrierDismissible: true, // 빈 공간 클릭 허용
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
            const Text("테스트 이어 풀기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text(
              "진행 중이던 기록이 있습니다.\n이어서 푸시겠습니까?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
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
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text("새로 풀기", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
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
                      backgroundColor: Colors.indigo,
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
      ),
    ).then((value) {
      // 팝업이 닫혔을 때 (이어풀기/새로풀기 선택 안 함) 메인으로 이동
      if (_testData.isEmpty && _currentIndex == 0) {
        Navigator.pop(context);
      }
    });
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
        List<Word> selectedDistractors = distractors.take(3).toList();
        answerToInfo[correctAnswer] = word.spelling;
        for (var d in selectedDistractors) {
          answerToInfo[d.meaning] = d.spelling;
        }
      } else {
        question = word.meaning;
        correctAnswer = word.spelling;
        List<Word> distractors = allWords.where((w) => w.spelling != correctAnswer).toList();
        distractors.shuffle();
        List<Word> selectedDistractors = distractors.take(3).toList();
        answerToInfo[correctAnswer] = word.meaning;
        for (var d in selectedDistractors) {
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
        'isSpellingToMeaning': isSpellingToMeaning,
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
      String level = currentQuestion['level'];
      _levelScores[level] = (_levelScores[level] ?? 0) + 1;
    }
    setState(() {
      _isChecked = true;
      _userSelectedAnswer = selectedAnswer;
      _isCorrect = correct;
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
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.indigo, size: 40),
            ),
            const SizedBox(height: 24),
            const Text("테스트 결과 📊", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
            const SizedBox(height: 16),
            Text("총 점수: $_score / ${_testData.length}", style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            const Text("사용자님께 추천하는 레벨은", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 8),
            Text("TOEIC $recommendedLevel", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.indigo)),
            const Text("입니다!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_testData.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currentQuestion = _testData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final Map<dynamic, dynamic> rawMap = currentQuestion['answerToInfo'] ?? {};
    final Map<String, String> answerToInfo = rawMap.map((k, v) => MapEntry(k.toString(), v.toString()));
    final bool isSpellingToMeaning = currentQuestion['isSpellingToMeaning'] ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("실력 진단 테스트 (${_currentIndex + 1}/${_testData.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
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
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? Colors.indigo : Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _testData.length - 1 ? "다음 문제" : "결과 확인",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Text(isSpellingToMeaning ? "뜻을 선택하세요" : "단어를 선택하세요", style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Text(
                    currentQuestion['question'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isSpellingToMeaning ? 36 : 28, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ...options.map((option) {
              bool isCorrectOption = option == currentQuestion['correctAnswer'];
              bool isSelected = option == _userSelectedAnswer;
              Color btnColor = Colors.white;
              Color borderCol = Colors.grey[200]!;
              Color textColor = Colors.black87;
              if (_isChecked) {
                if (isCorrectOption) {
                  btnColor = Colors.green[50]!;
                  borderCol = Colors.green;
                  textColor = Colors.green[900]!;
                } else if (isSelected) {
                  btnColor = Colors.red[50]!;
                  borderCol = Colors.red;
                  textColor = Colors.red[900]!;
                } else {
                  textColor = Colors.grey[400]!;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: OutlinedButton(
                    onPressed: () => _checkAnswer(option),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: btnColor,
                      side: BorderSide(color: borderCol, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      _isChecked ? "$option\n(${answerToInfo[option]})" : option,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: isCorrectOption && _isChecked ? FontWeight.bold : FontWeight.w500, color: textColor),
                    ),
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
