import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  // 각 레벨별 정답 개수 체크용
  Map<String, int> _levelScores = {'500': 0, '700': 0, '900+': 0};

  bool _isChecked = false;
  String? _userSelectedAnswer;
  bool _isCorrect = false;

  // 레벨 테스트 전용 캐시 키
  final String _cacheKey = "level_test_progress";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProgressAndInitialize();
    });
  }

  // 1. 진입 시 진행 기록 확인
  void _checkProgressAndInitialize() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      int savedIndex = savedData['index'] ?? 0;

      // ★ 한 문제라도 푼 기록이 있을 때(index > 0)만 팝업 노출
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

  // 2. 이어풀기 알림창
  void _showResumeDialog(dynamic savedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "테스트 이어 풀기",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("이전에 진행 중이던 실력 진단 기록이 있습니다.\n이어서 푸시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              _clearProgress();
              Navigator.pop(context);
              _generateLevelTestData(); // 새로 풀기
            },
            child: const Text("새로 풀기", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreFromCache(savedData); // 이어풀기
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("이어서 풀기", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. 캐시 데이터 복구
  void _restoreFromCache(dynamic savedData) {
    setState(() {
      _currentIndex = savedData['index'] ?? 0;
      _score = savedData['score'] ?? 0;

      // Map 데이터 안전하게 복원
      final Map<dynamic, dynamic> rawScores =
          savedData['levelScores'] ?? {'500': 0, '700': 0, '900+': 0};
      _levelScores = rawScores.map((k, v) => MapEntry(k.toString(), v as int));

      _testData = (savedData['testData'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  // 4. 레벨 테스트용 데이터 생성
  void _generateLevelTestData() {
    final box = Hive.box<Word>('words');
    final allWords = box.values.where((w) => w.type == 'Word').toList();

    List<Word> testPool = [];
    final levels = ['500', '700', '900+'];

    for (var level in levels) {
      final levelWords = allWords.where((w) => w.level == level).toList();
      levelWords.shuffle();
      // 각 레벨당 5문제씩, 총 15문제
      testPool.addAll(levelWords.take(5));
    }

    _testData = [];
    for (var word in testPool) {
      String correctAnswer = word.meaning;

      List<Word> distractors = allWords
          .where((w) => w.meaning != correctAnswer)
          .toList();
      distractors.shuffle();
      List<Word> selectedDistractors = distractors.take(3).toList();

      Map<String, String> meaningToSpelling = {correctAnswer: word.spelling};
      for (var d in selectedDistractors) {
        meaningToSpelling[d.meaning] = d.spelling;
      }

      List<String> options = meaningToSpelling.keys.toList();
      options.shuffle();

      _testData.add({
        'question': word.spelling,
        'correctAnswer': correctAnswer,
        'options': options,
        'meaningToSpelling': meaningToSpelling,
        'level': word.level,
      });
    }

    _saveProgress(); // 데이터 생성 직후 저장
    setState(() {});
  }

  // 5. 정답 체크 및 레벨별 점수 기록
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

    _saveProgress(); // 체크 후 진행상황 저장
  }

  // 6. 다음 문제 또는 결과 화면 이동
  void _nextQuestion() {
    if (_currentIndex < _testData.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _userSelectedAnswer = null;
      });
      _saveProgress(); // 다음 문제로 넘어가면 상태 저장
    } else {
      _clearProgress(); // 테스트를 끝까지 완료했으므로 캐시 삭제
      _showResultDialog();
    }
  }

  // 진행 상태 저장 로직
  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {
      'index': _currentIndex,
      'score': _score,
      'levelScores': _levelScores,
      'testData': _testData,
    });
  }

  // 진행 상태 삭제 로직
  void _clearProgress() {
    Hive.box('cache').delete(_cacheKey);
  }

  // 7. 레벨 테스트 결과 분석 및 팝업
  void _showResultDialog() {
    String recommendedLevel = '500';
    if (_levelScores['900+']! >= 3) {
      recommendedLevel = '900+';
    } else if (_levelScores['700']! >= 3) {
      recommendedLevel = '700';
    }

    // 결과 저장 (main.dart 홈 화면 갱신용)
    Hive.box('cache').put('user_recommended_level', recommendedLevel);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "테스트 결과 📊",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "총 점수: $_score / ${_testData.length}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 15),
            const Text("분석 결과, 사용자님께 추천하는 레벨은", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              recommendedLevel,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Text("입니다!", style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 홈으로 이동
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "확인",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_testData.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentQuestion = _testData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final Map<dynamic, dynamic> rawMap =
        currentQuestion['meaningToSpelling'] ?? {};
    final Map<String, String> meaningToSpelling = rawMap.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("실력 진단 테스트 (${_currentIndex + 1}/${_testData.length})"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // ★ 뒤로가기 버튼 활성화 및 저장 로직 추가
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            _saveProgress(); // 나가기 전에 무조건 한 번 저장
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _testData.length - 1 ? "다음 문제" : "결과 확인",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                currentQuestion['question'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ...options.map((option) {
              bool isCorrectOption = option == currentQuestion['correctAnswer'];
              bool isSelected = option == _userSelectedAnswer;

              Color btnColor = Colors.white;
              Color borderCol = Colors.grey[300]!;
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
                  textColor = Colors.grey;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Container(
                  width: double.infinity,
                  height: 85, // 박스 높이 고정
                  child: OutlinedButton(
                    onPressed: () => _checkAnswer(option),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: btnColor,
                      side: BorderSide(color: borderCol, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                    ),
                    child: Text(
                      _isChecked
                          ? "$option\n(${meaningToSpelling[option]})"
                          : option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17, // 글자 크기 고정
                        fontWeight: isCorrectOption && _isChecked
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: textColor,
                      ),
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
