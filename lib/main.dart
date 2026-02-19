import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'word_model.dart';
import 'data_loader.dart';
import 'quiz_page.dart';
import 'study_page.dart';
import 'calendar_page.dart';
import 'study_record_service.dart';
import 'wrong_answer_page.dart';
import 'todays_word_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(WordAdapter());
  }

  await Hive.openBox<Word>('words');
  await Hive.openBox('cache');
  await Hive.openBox<Word>('wrong_answers');

  await StudyRecordService.init();
  await initializeDateFormatting();
  await DataLoader.loadData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '포켓보카',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isCompleted = cacheBox.get(
      "today_completed_$todayStr",
      defaultValue: false,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "안녕하세요! 👋",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "오늘도 열공해볼까요?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Colors.indigo,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () async {
                  await _startTodaysQuiz();
                  _refresh();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted ? "오늘의 학습 완료! ✅" : "오늘의 영단어 🔥",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isCompleted
                                  ? "훌륭합니다! 내일 다시 만나요.\n복습은 언제나 환영이에요."
                                  : "매일 10개씩 꾸준히!\n지금 바로 시작하세요.",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Study Category",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildMenuCard(
                      title: "TOEIC",
                      subtitle: "실전 대비",
                      icon: Icons.business_center,
                      color: Colors.blueAccent,
                      onTap: () async {
                        await _showLevelDialog('TOEIC', ['500', '700', '900+']);
                        _refresh();
                      },
                    ),
                    _buildMenuCard(
                      title: "OPIc",
                      subtitle: "말하기 연습",
                      icon: Icons.record_voice_over,
                      color: Colors.orangeAccent,
                      onTap: () async {
                        await _showLevelDialog('OPIC', ['IM', 'IH', 'AL']);
                        _refresh();
                      },
                    ),
                    _buildMenuCard(
                      title: "오답노트",
                      subtitle: "틀린 문제 복습",
                      icon: Icons.note_alt_outlined,
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WrongAnswerPage(),
                          ),
                        );
                        _refresh();
                      },
                    ),
                    _buildMenuCard(
                      title: "학습 통계",
                      subtitle: "준비중...",
                      icon: Icons.bar_chart_rounded,
                      color: Colors.purpleAccent,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("멋진 통계 기능을 준비하고 있어요! 🚧")),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTodaysQuiz() async {
    final box = Hive.box<Word>('words');
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String todayKey = "today_list_$todayStr";
    List<Word> todaysWords = [];

    if (cacheBox.containsKey(todayKey)) {
      List<String> savedSpellings = List<String>.from(cacheBox.get(todayKey));
      final allWords = box.values.toList();
      for (String spelling in savedSpellings) {
        try {
          final word = allWords.firstWhere((w) => w.spelling == spelling);
          todaysWords.add(word);
        } catch (e) {}
      }
    }

    if (todaysWords.isEmpty) {
      final allWords = box.values.where((w) => w.type == 'Word').toList();
      if (allWords.isEmpty) return;
      todaysWords = (allWords..shuffle()).take(10).toList();
      cacheBox.put(todayKey, todaysWords.map((w) => w.spelling).toList());
    }

    bool isCompleted = cacheBox.get(
      "today_completed_$todayStr",
      defaultValue: false,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TodaysWordListPage(words: todaysWords, isCompleted: isCompleted),
      ),
    );
  }

  Future<void> _showLevelDialog(String category, List<String> levels) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("$category 레벨 선택"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: levels.map((level) {
              return ListTile(
                title: Text(
                  level,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showModeSelectionDialog(category, level);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showModeSelectionDialog(String category, String level) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text("$category $level"),
          content: const Text("어떤 학습을 하시겠습니까?"),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudyPage(category: category, level: level),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text("단어장"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                // ★ [로직 수정] 퀴즈 버튼 클릭 시 바로 캐시 체크
                _checkSavedQuizAndStart(category, level);
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text("퀴즈"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ★ 가장 중요한 로직: 캐시 키를 quiz_match_ 로 통일
  void _checkSavedQuizAndStart(String category, String level) {
    final cacheBox = Hive.box('cache');
    // quiz_page.dart에서 사용하는 키와 동일하게 맞춤
    final String cacheKey = "quiz_match_${category}_${level}";

    if (cacheBox.containsKey(cacheKey)) {
      // 기록이 있으면 문제 수 선택창을 건너뛰고 바로 QuizPage로 이동
      // QuizPage 내부에서 "이어서 푸시겠습니까?" 팝업을 띄우게 됨
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            category: category,
            level: level,
            questionCount: 0, // 이어서 풀 때는 0 전달
          ),
        ),
      );
    } else {
      // 기록이 없으면 문제 수 선택창 노출
      _showQuestionCountDialog(category, level);
    }
  }

  void _showQuestionCountDialog(String category, String level) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("문제 수 선택"),
          children: [10, 20, 30].map((count) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(
                      category: category,
                      level: level,
                      questionCount: count,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("$count문제", style: const TextStyle(fontSize: 16)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
