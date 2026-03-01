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
  final bool isWrongAnswerQuiz;

  const QuizPage({
    super.key,
    this.category = "오답노트",
    this.level = "",
    this.questionCount = 0,
    this.dayNumber,
    this.dayWords,
    this.isWrongAnswerQuiz = false,
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
    if (widget.isWrongAnswerQuiz) {
      _cacheKey = "quiz_wrong_answers";
    } else {
      _cacheKey = widget.dayNumber != null
          ? "quiz_day_${widget.category}_${widget.level}_${widget.dayNumber}"
          : "quiz_match_${widget.category}_${widget.level}";
    }

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
        _initializeQuiz();
      }
    } else {
      _initializeQuiz();
    }
  }

  void _initializeQuiz() {
    if (widget.isWrongAnswerQuiz) {
      _loadNewQuizData(0);
    } else if (widget.dayNumber == null && widget.questionCount <= 0) {
      _showQuestionCountSelection();
    } else {
      int count = widget.questionCount > 0 ? widget.questionCount : 10;
      _loadNewQuizData(count);
    }
  }

  void _showResumeDialog(dynamic savedData) {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
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
            const Text("퀴즈 이어 풀기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text(
              "이전에 풀던 기록이 있습니다.\n이어서 푸시겠습니까?",
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
                      Navigator.pop(context, true);
                      _initializeQuiz();
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
                      Navigator.pop(context, true);
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
    ).then((handled) {
      if (handled == null) Navigator.pop(context);
    });
  }

  void _showQuestionCountSelection() {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
                child: const Icon(Icons.format_list_numbered_rounded, color: Colors.indigo, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("문제 수 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
              const SizedBox(height: 12),
              const Text("풀고 싶은 문제의 개수를 선택해 주세요.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 24),
              ...[10, 20, 30].map((count) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                        _loadNewQuizData(count);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("$count문제", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    ).then((handled) {
      if (handled == null) Navigator.pop(context);
    });
  }

  void _restoreFromCache(dynamic savedData) {
    final wordBox = Hive.box<Word>('words');
    final allWords = wordBox.values.toList();
    final wrongBox = Hive.box<Word>('wrong_answers');
    final allWrongWords = wrongBox.values.toList();

    try {
      setState(() {
        _currentIndex = savedData['index'] ?? 0;
        _wrongAnswersList = (savedData['wrongAnswers'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _quizData = (savedData['quizData'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _quizList = [];
        for (var data in _quizData) {
          Word? word;
          try {
            word = allWords.firstWhere((w) => w.spelling == data['question'] && w.type == 'Word');
          } catch (e) {
            try {
              word = allWords.firstWhere((w) => w.spelling == data['question']);
            } catch (e) {
              word = allWrongWords.firstWhere((w) => w.spelling == data['question']);
            }
          }
          _quizList.add(word);
          data['word'] = word;
        }
      });
    } catch (e) {
      _initializeQuiz();
    }
  }

  void _loadNewQuizData(int count) {
    if (widget.dayWords != null && widget.dayWords!.isNotEmpty) {
      _quizList = List<Word>.from(widget.dayWords!);
      _quizList.shuffle();
    } else {
      final box = Hive.box<Word>('words');
      List<Word> filteredList = box.values.where((word) => word.category == widget.category && word.level == widget.level && word.type == 'Word').toList();
      if (filteredList.isEmpty) filteredList = box.values.where((word) => word.category == widget.category && word.level == widget.level).toList();
      final Map<String, Word> uniqueMap = {};
      for (var w in filteredList) uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
      List<Word> finalPool = uniqueMap.values.toList();
      finalPool.shuffle();
      int targetCount = count > 0 ? count : (widget.isWrongAnswerQuiz ? finalPool.length : 10);
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
    final random = Random();

    for (var word in _quizList) {
      bool isSpellingToMeaning = random.nextBool();
      String question;
      String correctAnswer;
      Map<String, String> answerToInfo = {};

      if (isSpellingToMeaning) {
        question = word.spelling;
        correctAnswer = word.meaning;
        List<Word> distractorsPool = allWords.where((w) => w.meaning != correctAnswer && w.spelling != word.spelling).toList();
        distractorsPool.shuffle();
        List<Word> selectedDistractors = distractorsPool.take(3).toList();
        answerToInfo[correctAnswer] = word.spelling;
        for (var d in selectedDistractors) answerToInfo[d.meaning] = d.spelling;
      } else {
        question = word.meaning;
        correctAnswer = word.spelling;
        List<Word> distractorsPool = allWords.where((w) => w.spelling != correctAnswer && w.meaning != word.meaning).toList();
        distractorsPool.shuffle();
        List<Word> selectedDistractors = distractorsPool.take(3).toList();
        answerToInfo[correctAnswer] = word.meaning;
        for (var d in selectedDistractors) answerToInfo[d.spelling] = d.meaning;
      }
      List<String> options = answerToInfo.keys.toList();
      options.shuffle();
      _quizData.add({'question': question, 'correctAnswer': correctAnswer, 'options': options, 'answerToInfo': answerToInfo, 'word': word, 'isSpellingToMeaning': isSpellingToMeaning});
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;
    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);
    if (correct) {
      try {
        final cacheBox = Hive.box('cache');
        List<String> learnedWords = List<String>.from(cacheBox.get('learned_words', defaultValue: []));
        String spelling = (currentQuestion['word'] as Word).spelling;
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
          final wordToSave = Word(category: originWord.category, level: originWord.level, type: 'Word', spelling: originWord.spelling, meaning: originWord.meaning, nextReviewDate: DateTime.now());
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
      final String userInfo = currentQuestion['answerToInfo'][selectedAnswer] ?? "";
      final String correctInfo = currentQuestion['answerToInfo'][currentQuestion['correctAnswer']] ?? "";
      _wrongAnswersList.add({'spelling': (currentQuestion['word'] as Word).spelling, 'userAnswer': selectedAnswer, 'userAnswerInfo': userInfo, 'correctAnswer': currentQuestion['correctAnswer'], 'correctAnswerInfo': correctInfo});
    }
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

  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {'index': _currentIndex, 'wrongAnswers': _wrongAnswersList, 'quizData': _quizData});
  }

  void _clearProgress() => Hive.box('cache').delete(_cacheKey);

  @override
  Widget build(BuildContext context) {
    if (_quizList.isEmpty && _quizData.isEmpty) return Scaffold(backgroundColor: const Color(0xFFF5F7FA), appBar: AppBar(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0), body: const Center(child: CircularProgressIndicator(color: Colors.indigo)));
    if (_quizData.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo)));

    final currentQuestion = _quizData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final Map<dynamic, dynamic> rawMap = currentQuestion['answerToInfo'] ?? {};
    final Map<String, String> answerToInfo = rawMap.map((k, v) => MapEntry(k.toString(), v.toString()));
    final bool isSpellingToMeaning = currentQuestion['isSpellingToMeaning'] ?? true;

    String appBarTitle = widget.isWrongAnswerQuiz
        ? "오답노트 퀴즈 (${_currentIndex + 1}/${_quizData.length})"
        : (widget.dayNumber != null ? "${widget.category} ${widget.level} - DAY ${widget.dayNumber} (${_currentIndex + 1}/${_quizData.length})" : "${widget.category} ${widget.level} (${_currentIndex + 1}/${_quizData.length})");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text(appBarTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () { _saveProgress(); Navigator.pop(context); })),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? (_isCorrect ? Colors.green : Colors.indigo) : Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(_isChecked ? (_currentIndex < _quizData.length - 1 ? "다음 문제" : "결과 보기") : "정답을 선택하세요", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, spreadRadius: 5)]),
                child: Column(
                  children: [
                    Text(isSpellingToMeaning ? "뜻을 선택하세요" : "단어를 선택하세요", style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 15),
                    Text(currentQuestion['question'], textAlign: TextAlign.center, style: TextStyle(fontSize: isSpellingToMeaning ? 36 : 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              ...options.map((option) {
                bool isCorrectOption = option == currentQuestion['correctAnswer'];
                bool isSelected = option == _userSelectedAnswer;
                Color btnColor = Colors.white;
                Color borderCol = Colors.grey[300]!;
                Color textColor = Colors.black87;
                String info = answerToInfo[option] ?? "";
                String buttonText = _isChecked ? "$option\n($info)" : option;
                if (_isChecked) {
                  if (isCorrectOption) { btnColor = Colors.green[50]!; borderCol = Colors.green; textColor = Colors.green[900]!; }
                  else if (isSelected) { btnColor = Colors.red[50]!; borderCol = Colors.red; textColor = Colors.red[900]!; }
                  else { textColor = Colors.grey[400]!; }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 75),
                    child: OutlinedButton(
                      onPressed: () => _checkAnswer(option),
                      style: OutlinedButton.styleFrom(backgroundColor: btnColor, side: BorderSide(color: borderCol, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10)),
                      child: Text(buttonText, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: isCorrectOption && _isChecked ? FontWeight.bold : FontWeight.w500, color: textColor)),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
