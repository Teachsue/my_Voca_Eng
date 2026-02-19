import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'todays_quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  final String category;
  final String level;
  final int questionCount;
  final int? dayNumber;
  final List<Word>? dayWords;

  const QuizPage({
    super.key,
    required this.category,
    required this.level,
    required this.questionCount,
    this.dayNumber,
    this.dayWords,
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
    _cacheKey = widget.dayNumber != null
        ? "quiz_day_${widget.category}_${widget.level}_${widget.dayNumber}"
        : "quiz_match_${widget.category}_${widget.level}";

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
        // 기록이 없는 것과 동일하게 처리
        if (widget.dayNumber == null && widget.questionCount <= 0) {
          _showQuestionCountSelection();
        } else {
          int count = widget.questionCount > 0 ? widget.questionCount : 10;
          _loadNewQuizData(count);
        }
      }
    } else {
      if (widget.dayNumber == null && widget.questionCount <= 0) {
        _showQuestionCountSelection();
      } else {
        int count = widget.questionCount > 0 ? widget.questionCount : 10;
        _loadNewQuizData(count);
      }
    }
  }

  // ★ 변경: 뒤로가기 및 빈 공간 터치를 허용하고, 취소 시 화면을 빠져나가도록 구현
  void _showResumeDialog(dynamic savedData) {
    showDialog<bool>(
      context: context,
      barrierDismissible: true, // 바깥을 터치해서 닫을 수 있게 허용
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "퀴즈 이어 풀기",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("이전에 풀던 기록이 있습니다.\n이어서 푸시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              _clearProgress();
              Navigator.pop(dialogContext, true); // 정상적으로 선택했음을 true로 알림

              if (widget.dayNumber == null && widget.questionCount <= 0) {
                _showQuestionCountSelection();
              } else {
                int count = widget.questionCount > 0
                    ? widget.questionCount
                    : 10;
                _loadNewQuizData(count);
              }
            },
            child: const Text(
              "새로 풀기",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true); // 정상적으로 선택했음을 true로 알림
              _restoreFromCache(savedData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "이어서 풀기",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).then((handled) {
      // handled가 null이라는 것은 버튼을 누르지 않고 뒤로가기나 배경을 눌러서 팝업이 꺼졌다는 뜻
      if (handled == null) {
        Navigator.pop(context); // 텅 빈 퀴즈 페이지에 남지 않도록 이전 화면으로 완전히 돌아갑니다.
      }
    });
  }

  // ★ 변경: 문제 수 선택 팝업도 동일하게 뒤로가기 로직 적용
  void _showQuestionCountSelection() {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "문제 수 선택",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          children: [10, 20, 30].map((count) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, true);
                _loadNewQuizData(count);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
                child: Text(
                  "$count문제",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    ).then((handled) {
      // 배경 터치나 뒤로가기를 했을 경우 이전 화면으로 빠져나갑니다.
      if (handled == null) {
        Navigator.pop(context);
      }
    });
  }

  void _restoreFromCache(dynamic savedData) {
    final wordBox = Hive.box<Word>('words');
    final allWords = wordBox.values.toList();

    try {
      setState(() {
        _currentIndex = savedData['index'] ?? 0;
        _wrongAnswersList = (savedData['wrongAnswers'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _quizData = (savedData['quizData'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _quizList = [];
        for (var data in _quizData) {
          final word = allWords.firstWhere(
            (w) => w.spelling == data['question'] && w.type == 'Word',
            orElse: () =>
                allWords.firstWhere((w) => w.spelling == data['question']),
          );
          _quizList.add(word);
          data['word'] = word;
        }
      });
    } catch (e) {
      int count = widget.questionCount > 0 ? widget.questionCount : 10;
      _loadNewQuizData(count);
    }
  }

  void _loadNewQuizData(int count) {
    if (widget.dayWords != null && widget.dayWords!.isNotEmpty) {
      _quizList = List<Word>.from(widget.dayWords!);
      _quizList.shuffle();
    } else {
      final box = Hive.box<Word>('words');
      List<Word> filteredList = box.values.where((word) {
        return word.category == widget.category &&
            word.level == widget.level &&
            word.type == 'Word';
      }).toList();

      if (filteredList.isEmpty) {
        filteredList = box.values.where((word) {
          return word.category == widget.category && word.level == widget.level;
        }).toList();
      }

      final Map<String, Word> uniqueMap = {};
      for (var w in filteredList) {
        uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
      }

      List<Word> finalPool = uniqueMap.values.toList();
      finalPool.shuffle();

      int targetCount = count > 0 ? count : 10;
      _quizList = finalPool.take(min(targetCount, finalPool.length)).toList();
    }

    if (_quizList.isNotEmpty) {
      _generateQuizQuestions();
      _saveProgress();
    }

    if (mounted) setState(() {});
  }

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

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;

    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    if (correct) {
      try {
        final cacheBox = Hive.box('cache');
        List<String> learnedWords = List<String>.from(
          cacheBox.get('learned_words', defaultValue: []),
        );
        String spelling = currentQuestion['question'];

        if (!learnedWords.contains(spelling)) {
          learnedWords.add(spelling);
          cacheBox.put('learned_words', learnedWords);
        }
      } catch (e) {}
    } else {
      try {
        if (Hive.isBoxOpen('wrong_answers')) {
          final wrongBox = Hive.box<Word>('wrong_answers');
          final Word originWord = currentQuestion['word'];

          final wordToSave = Word(
            category: originWord.category,
            level: originWord.level,
            type: 'Word',
            spelling: originWord.spelling,
            meaning: originWord.meaning,
          );
          wrongBox.put(wordToSave.spelling, wordToSave);
        }
      } catch (e) {}
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
    if (_quizList.isEmpty && _quizData.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        // 팝업이 뜰 때나 데이터 로딩 중 빈 화면 방지용 프로그레스
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    if (_quizData.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    final currentQuestion = _quizData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final Map<dynamic, dynamic> rawMap =
        currentQuestion['meaningToSpelling'] ?? {};
    final Map<String, String> meaningToSpelling = rawMap.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );

    String appBarTitle = widget.dayNumber != null
        ? "${widget.category} ${widget.level} - DAY ${widget.dayNumber} (${_currentIndex + 1}/${_quizList.length})"
        : "${widget.category} ${widget.level} (${_currentIndex + 1}/${_quizList.length})";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(fontSize: 16)),
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
            ...options.map((option) {
              bool isCorrectOption = option == currentQuestion['correctAnswer'];
              bool isSelected = option == _userSelectedAnswer;

              Color btnColor = Colors.white;
              Color borderCol = Colors.grey[300]!;
              Color textColor = Colors.black87;

              String originalSpelling = meaningToSpelling[option] ?? "";
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
                  width: double.infinity,
                  height: 85,
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
                      buttonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
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
