import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 위해 필요
import 'word_model.dart';
import 'study_record_service.dart';
import 'todays_quiz_result_page.dart';

class TodaysQuizPage extends StatefulWidget {
  final List<Word> words;

  const TodaysQuizPage({super.key, required this.words});

  @override
  State<TodaysQuizPage> createState() => _TodaysQuizPageState();
}

class _TodaysQuizPageState extends State<TodaysQuizPage> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _quizData = [];
  List<Map<String, dynamic>> _wrongAnswersList = []; // final 제거 (불러오기 위해)

  bool _isChecked = false;
  bool _isCorrect = false;
  String? _userSelectedAnswer;

  // ★ 저장소 키 생성을 위한 정보
  late String _cacheKey;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    // 1. 퀴즈 데이터 생성 (이 안에서 랜덤으로 섞이게 수정할 것입니다)
    _generateQuiz();

    // 2. 고유 키 생성
    if (widget.words.isNotEmpty) {
      String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Word firstWord = widget.words.first;
      _cacheKey =
          "quiz_progress_${dateStr}_${firstWord.category}_${firstWord.level}";
    } else {
      _cacheKey = "quiz_progress_temp";
    }

    // 3. 저장된 진행 상황 불러오기
    _loadProgress();
  }

  // ★★★ [신규] 진행 상황 불러오기 ★★★
  void _loadProgress() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get(_cacheKey);

    if (savedData != null) {
      // 저장된 데이터가 있다면 복구
      setState(() {
        _currentIndex = savedData['index'] ?? 0;

        // 오답 리스트 복구 (Hive에서 가져온 List<dynamic>을 변환)
        List<dynamic> savedWrong = savedData['wrongAnswers'] ?? [];
        _wrongAnswersList = savedWrong
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });

      // 이미 다 푼 상태라면? (혹시 모를 에러 방지)
      if (_currentIndex >= _quizData.length) {
        _currentIndex = 0;
        _wrongAnswersList.clear();
      } else if (_currentIndex > 0) {
        // 이어풀기 안내 메시지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${_currentIndex + 1}번 문제부터 이어 풉니다! ▶️")),
          );
        });
      }
    }
  }

  // ★★★ [신규] 진행 상황 저장하기 ★★★
  void _saveProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.put(_cacheKey, {
      'index': _currentIndex, // 다음 풀 문제 번호
      'wrongAnswers': _wrongAnswersList, // 지금까지 틀린 목록
    });
  }

  // ★★★ [신규] 완료 시 데이터 삭제 ★★★
  void _clearProgress() {
    final cacheBox = Hive.box('cache');
    cacheBox.delete(_cacheKey);
  }

  void _generateQuiz() {
    final box = Hive.box<Word>('words');
    final allWordCandidates = box.values
        .where((w) => w.type == 'Word')
        .toList();

    String dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    int dateSeed = int.parse(dateStr);
    Random randomSeed = Random(dateSeed);

    List<Word> shuffledWords = List<Word>.from(widget.words);
    shuffledWords.shuffle(randomSeed);

    for (var targetWord in shuffledWords) {
      bool isSpellingToMeaning = randomSeed.nextBool();
      String question;
      String correctAnswer;
      Map<String, String> optionInfos = {};
      List<String> options = [];

      if (isSpellingToMeaning) {
        question = targetWord.spelling;
        correctAnswer = targetWord.meaning;

        List<String> distractors = allWordCandidates
            .where((w) => w.meaning != correctAnswer)
            .map((w) => w.meaning)
            .toSet() // 중복 제거
            .toList();

        distractors.shuffle(randomSeed);
        options = distractors.take(3).toList();
        options.add(correctAnswer);
        options.shuffle(randomSeed);

        for (String opt in options) {
          if (opt == correctAnswer) {
            optionInfos[opt] = targetWord.spelling;
          } else {
            try {
              final matchingWord = allWordCandidates.firstWhere(
                (w) => w.meaning == opt,
              );
              optionInfos[opt] = matchingWord.spelling;
            } catch (e) {
              optionInfos[opt] = "";
            }
          }
        }
      } else {
        question = targetWord.meaning;
        correctAnswer = targetWord.spelling;

        List<String> distractors = allWordCandidates
            .where((w) => w.spelling != correctAnswer)
            .map((w) => w.spelling)
            .toSet() // 중복 제거
            .toList();

        distractors.shuffle(randomSeed);
        options = distractors.take(3).toList();
        options.add(correctAnswer);
        options.shuffle(randomSeed);

        for (String opt in options) {
          if (opt == correctAnswer) {
            optionInfos[opt] = targetWord.meaning;
          } else {
            try {
              final matchingWord = allWordCandidates.firstWhere(
                (w) => w.spelling == opt,
              );
              optionInfos[opt] = matchingWord.meaning;
            } catch (e) {
              optionInfos[opt] = "";
            }
          }
        }
      }

      _quizData.add({
        'question': question,
        'correctAnswer': correctAnswer,
        'options': options,
        'word': targetWord,
        'optionInfos': optionInfos,
        'isSpellingToMeaning': isSpellingToMeaning,
      });
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isChecked) return;

    final currentQuestion = _quizData[_currentIndex];
    bool correct = (selectedAnswer == currentQuestion['correctAnswer']);

    // ★ 에빙하우스 알고리즘 반영: 단어 데이터 업데이트
    final word = currentQuestion['word'] as Word;
    word.updateReviewStep(correct);
    word.save(); // 변경사항 DB 저장

    // ★ [수정] 오답노트 저장 (copy 대신 직접 생성) ★★★
    if (!correct) {
      final wrongBox = Hive.box<Word>('wrong_answers');

      if (currentQuestion['word'] != null) {
        final originWord = currentQuestion['word'] as Word;

        // .copy() 대신 기존 속성을 그대로 가져와 새로운 Word 객체를 만듭니다.
        final newWord = Word(
          category: originWord.category,
          level: originWord.level,
          spelling: originWord.spelling,
          meaning: originWord.meaning,
          type: originWord.type,
          correctAnswer: originWord.correctAnswer,
          options: originWord.options,
          explanation: originWord.explanation,
          isScrap: originWord.isScrap,
          nextReviewDate: originWord.nextReviewDate, // 업데이트된 날짜 사용
          reviewStep: originWord.reviewStep, // 업데이트된 단계 사용
        );

        wrongBox.put(newWord.spelling, newWord);
        print("📝 오답노트 저장 완료 및 에빙하우스 적용: ${newWord.spelling}");
      }
    }

    setState(() {
      _isChecked = true;
      _userSelectedAnswer = selectedAnswer;
      _isCorrect = correct;
    });

    if (!correct) {
      final String userInfo = currentQuestion['optionInfos'][selectedAnswer] ?? "";
      final String correctInfo = currentQuestion['optionInfos'][currentQuestion['correctAnswer']] ?? "";

      _wrongAnswersList.add({
        'spelling': (currentQuestion['word'] as Word).spelling,
        'userAnswer': selectedAnswer,
        'userAnswerInfo': userInfo,
        'correctAnswer': currentQuestion['correctAnswer'],
        'correctAnswerInfo': correctInfo,
      });
    }
  }

  void _nextQuestion() async {
    if (_currentIndex < _quizData.length - 1) {
      setState(() {
        _currentIndex++;
        _isChecked = false;
        _userSelectedAnswer = null;
      });
      _saveProgress(); // 이어풀기 저장
    } else {
      // ★ 중요: 여기서 '오늘 완료' 도장을 찍거나 StudyRecordService를 호출하면 안 됩니다!
      // 오직 진행 중이던 임시 데이터만 삭제하고 결과 페이지로 넘어갑니다.

      _clearProgress(); // 진행 중 데이터(index 등)만 삭제

      if (!mounted) return;

      // 퀴즈 페이지가 끝나면 스스로를 지우고(Replacement) 결과창을 띄웁니다.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodaysQuizResultPage(
            wrongAnswers: _wrongAnswersList,
            totalCount: widget.words.length,
            isTodaysQuiz: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = _quizData[_currentIndex];
    final options = currentQuestion['options'] as List<String>;
    final optionInfos = currentQuestion['optionInfos'] as Map<String, String>;
    final bool isSpellingToMeaning =
        currentQuestion['isSpellingToMeaning'] ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "오늘의 퀴즈 (${_currentIndex + 1}/${_quizData.length})",
        ), // 타이틀 수정
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _saveProgress();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("진행 상황이 저장되었습니다!")));
            Navigator.pop(context);
          },
        ),
      ),

      // ★ 1. 하단 버튼을 bottomNavigationBar 영역으로 이동하여 시스템 바와 분리
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // 하단 여백 충분히 확보
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecked ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked ? Colors.indigo : Colors.grey[300],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: Text(
                _isChecked
                    ? ((_currentIndex < _quizData.length - 1)
                          ? "다음 문제"
                          : "결과 보기")
                    : "정답을 선택하세요",
                style: TextStyle(
                  fontSize: 18,
                  color: _isChecked ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),

      // ★ 2. body는 SafeArea와 스크롤뷰로 감싸 콘텐츠가 버튼 뒤로 숨지 않게 함
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 문제 표시 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSpellingToMeaning ? "이 단어의 뜻은?" : "이 뜻을 가진 단어는?",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentQuestion['question'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSpellingToMeaning ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 선택지 버튼 리스트
              ...options.map((option) {
                Color btnColor = Colors.white;
                Color textColor = Colors.black;
                Color borderColor = Colors.grey.withOpacity(0.2);

                String buttonText = option;

                if (_isChecked) {
                  String info = optionInfos[option] ?? "";
                  if (info.isNotEmpty) {
                    buttonText += "\n($info)";
                  }

                  if (option == currentQuestion['correctAnswer']) {
                    btnColor = Colors.green[100]!;
                    textColor = Colors.green[900]!;
                    borderColor = Colors.green;
                  } else if (option == _userSelectedAnswer) {
                    btnColor = Colors.red[100]!;
                    textColor = Colors.red[900]!;
                    borderColor = Colors.red;
                  } else {
                    textColor = Colors.grey;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 75,
                    child: ElevatedButton(
                      onPressed: () => _checkAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: _isChecked
                                ? borderColor
                                : Colors.grey.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        buttonText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
