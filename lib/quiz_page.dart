import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'todays_quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  final String category;
  final String level;
  final int questionCount;

  const QuizPage({
    super.key,
    required this.category,
    required this.level,
    required this.questionCount,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Word> _quizList = [];
  int _currentIndex = 0;
  List<Map<String, dynamic>> _quizData = [];
  List<Map<String, dynamic>> _wrongAnswersList = [];

  bool _isChecked = false;
  bool _isCorrect = false;
  String? _userSelectedAnswer;
  late String _cacheKey;

  @override
  void initState() {
    super.initState();
    // 캐시 키 설정
    _cacheKey = "quiz_match_${widget.category}_${widget.level}";

    // 화면이 빌드된 후 초기화 로직 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }

  // 1. 초기화 로직: 캐시 확인 후 알림창 띄우기
  void _initializeQuiz() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      _showResumeDialog(savedData);
    } else {
      _loadNewQuizData();
    }
  }

  // 2. 이어서 풀기 의사를 묻는 알림창
  void _showResumeDialog(dynamic savedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("퀴즈 이어 풀기"),
        content: const Text("이전에 풀던 기록이 있습니다.\n이어서 푸시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              _clearProgress();
              Navigator.pop(context);
              _loadNewQuizData();
            },
            child: const Text("새로 풀기", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreFromCache(savedData);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("이어서 풀기", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. 캐시 데이터로부터 상태 복구
  void _restoreFromCache(dynamic savedData) {
    setState(() {
      _currentIndex = savedData['index'] ?? 0;
      _wrongAnswersList = (savedData['wrongAnswers'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _quizData = (savedData['quizData'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // 저장된 데이터로부터 Word 객체 리스트 추출
      _quizList = _quizData.map((d) => d['word'] as Word).toList();
    });
  }

  // 4. 새 퀴즈 데이터 생성 로드
  void _loadNewQuizData() {
    final box = Hive.box<Word>('words');
    List<Word> filteredList = box.values.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Word';
    }).toList();

    // 중복 제거
    final Map<String, Word> uniqueMap = {};
    for (var w in filteredList) {
      uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
    }

    List<Word> finalPool = uniqueMap.values.toList();
    finalPool.shuffle();
    _quizList = finalPool.take(widget.questionCount).toList();

    if (_quizList.isNotEmpty) {
      _generateQuizQuestions();
      _saveProgress();
    }
    if (mounted) setState(() {});
  }

  // 5. 퀴즈 문제 및 보기 구성 (의미-단어 매칭 포함)
  void _generateQuizQuestions() {
    final box = Hive.box<Word>('words');
    final allWords = box.values.where((w) => w.type == 'Word').toList();
    _quizData = [];

    for (var word in _quizList) {
      String correctAnswer = word.meaning;
      List<Word> distractorsPool = allWords
          .where(
            (w) => w.meaning != correctAnswer && w.spelling != word.spelling,
          )
          .toList();
      distractorsPool.shuffle();
      List<Word> selectedDistractors = distractorsPool.take(3).toList();

      // 보기와 해당 단어의 영문 스펠링을 매칭한 맵 생성
      Map<String, String> meaningToSpelling = {correctAnswer: word.spelling};
      for (var d in selectedDistractors) {
        meaningToSpelling[d.meaning] = d.spelling;
      }

      List<String> options = meaningToSpelling.keys.toList();
      options.shuffle();

      _quizData.add({
        'question': word.spelling,
        'correctAnswer': correctAnswer,
        'options': options,
        'meaningToSpelling': meaningToSpelling,
        'word': word,
      });
    }
  }

  // 6. 정답 체크 및 오답 저장
  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;

    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    if (!correct) {
      try {
        if (Hive.isBoxOpen('wrong_answers')) {
          final wrongBox = Hive.box<Word>('wrong_answers');
          final Word originWord = currentQuestion['word'];

          // Hive 객체 소유권 충돌 방지를 위해 새 객체로 복사하여 저장
          final wordToSave = Word(
            category: originWord.category,
            level: originWord.level,
            type: 'Word',
            spelling: originWord.spelling,
            meaning: originWord.meaning,
          );
          wrongBox.put(wordToSave.spelling, wordToSave);
        }
      } catch (e) {
        print("오답 저장 실패: $e");
      }
    }

    setState(() {
      _isChecked = true;
      _userSelectedAnswer = selectedAnswer;
      _isCorrect = correct;
    });

    if (!correct) {
      _wrongAnswersList.add({
        'spelling': currentQuestion['question'],
        'userAnswer': selectedAnswer,
        'correctAnswer': currentQuestion['correctAnswer'],
      });
    }
    _saveProgress();
  }

  // 7. 다음 문제로 이동
  void _nextQuestion() {
    if (_currentIndex < _quizData.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _userSelectedAnswer = null;
      });
      _saveProgress();
    } else {
      _clearProgress();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodaysQuizResultPage(
            wrongAnswers: _wrongAnswersList,
            totalCount: _quizData.length,
          ),
        ),
      );
    }
  }

  // 8. 진행 상황 저장 및 삭제
  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {
      'index': _currentIndex,
      'wrongAnswers': _wrongAnswersList,
      'quizData': _quizData,
    });
  }

  void _clearProgress() => Hive.box('cache').delete(_cacheKey);

  @override
  Widget build(BuildContext context) {
    if (_quizList.isEmpty)
      return const Scaffold(body: Center(child: Text("데이터가 부족합니다.")));
    if (_quizData.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentQuestion = _quizData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final Map<dynamic, dynamic> rawMap =
        currentQuestion['meaningToSpelling'] ?? {};
    final Map<String, String> meaningToSpelling = rawMap.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "${widget.category} ${widget.level} (${_currentIndex + 1}/${_quizList.length})",
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _saveProgress();
            Navigator.pop(context);
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked
                    ? (_isCorrect ? Colors.green : Colors.indigo)
                    : Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _isChecked
                    ? (_currentIndex < _quizData.length - 1 ? "다음 문제" : "결과 보기")
                    : "정답을 선택하세요",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
            // 문제 카드 (영어 단어 중앙 배치)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 5,
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
            // 선택지 리스트
            ...options.map((option) {
              bool isCorrectOption = option == currentQuestion['correctAnswer'];
              bool isSelected = option == _userSelectedAnswer;

              Color btnColor = Colors.white;
              Color borderCol = Colors.grey[300]!;
              Color textColor = Colors.black87;

              String originalSpelling = meaningToSpelling[option] ?? "";
              // 정답 확인 후에는 영어 단어를 아래에 표기
              String buttonText = _isChecked
                  ? "$option\n($originalSpelling)"
                  : option;

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
                  // SizedBox 대신 Container 사용 (높이 고정)
                  width: double.infinity,
                  height: 85, // ★ 높이를 85로 고정하여 UI 흔들림 방지
                  child: OutlinedButton(
                    onPressed: () => _checkCheckAnswer(option),
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
                      buttonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _isChecked ? 15 : 18,
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

  // 버튼 클릭 시 _checkAnswer 호출을 위한 래퍼 함수 (오타 방지)
  void _checkCheckAnswer(String option) {
    _checkAnswer(option);
  }
}
