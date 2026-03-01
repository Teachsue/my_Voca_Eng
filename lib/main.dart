import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'word_model.dart';
import 'data_loader.dart';
import 'calendar_page.dart';
import 'study_record_service.dart';
import 'wrong_answer_page.dart';
import 'todays_word_list_page.dart';
import 'level_test_page.dart';
import 'day_selection_page.dart';
import 'statistics_page.dart';
import 'scrap_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(WordAdapter());
  }

  bool shouldReset = false;
  try {
    await Hive.openBox<Word>('words');
    await Hive.openBox('cache');
    await Hive.openBox<Word>('wrong_answers');
  } catch (e) {
    print("⚠️ DB 충돌 감지: $e. 전체 초기화 모드로 전환합니다.");
    shouldReset = true;
  }

  if (shouldReset) {
    await Hive.close();
    await Hive.deleteBoxFromDisk('words');
    await Hive.deleteBoxFromDisk('cache');
    await Hive.deleteBoxFromDisk('wrong_answers');
    await Hive.openBox<Word>('words');
    await Hive.openBox('cache');
    await Hive.openBox<Word>('wrong_answers');
  }

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
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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

  void _showLevelTestGuide(BuildContext context) {
    showDialog(
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
                child: const Icon(Icons.psychology_alt_rounded, color: Colors.indigo, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("실력 진단 테스트", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
              const SizedBox(height: 20),
              _buildCriteriaItem(Icons.format_list_numbered_rounded, "총 15개 문항 구성", "레벨별(500/700/900) 5문제씩 출제"),
              _buildCriteriaItem(Icons.auto_graph_rounded, "맞춤 레벨 추천", "정답률 분석을 통한 최적의 난이도 배정"),
              _buildCriteriaItem(Icons.timer_outlined, "약 3분 소요", "빠르고 정확하게 실력을 확인하세요"),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("다음에 할게요", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelTestPage()));
                        _refresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("시작하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildCriteriaItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    String? recommendedLevel = cacheBox.get('user_recommended_level');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // 살짝 더 화사한 배경색
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildMainBanner(isCompleted),
              const SizedBox(height: 16),
              _buildLevelBanner(recommendedLevel),
              const SizedBox(height: 40),
              const Text(
                "TOEIC 학습하기",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              _buildLevelSelectionRow(),
              const SizedBox(height: 40),
              const Text(
                "나의 학습 도구",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              _buildUtilityRow(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('M월 d일 (E)', 'ko_KR').format(DateTime.now()),
              style: TextStyle(fontSize: 15, color: Colors.indigo[400], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              "TOEIC 정복! 🔥",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -1.2),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(
              icon: Icons.settings_rounded,
              color: Colors.blueGrey,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsPage()));
                _refresh();
              },
            ),
            const SizedBox(width: 12),
            _buildHeaderIconButton(
              icon: Icons.calendar_month_rounded,
              color: Colors.indigo,
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
                _refresh();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMainBanner(bool isCompleted) {
    return GestureDetector(
      onTap: () async {
        await _startTodaysQuiz();
        _refresh();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted 
                ? [Colors.teal.shade300, Colors.teal.shade500] 
                : [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: (isCompleted ? Colors.teal : const Color(0xFF6A11CB)).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? "학습 완료! ✨" : "오늘의 단어 학습",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCompleted 
                        ? "훌륭합니다! 꾸준함이 정답입니다.\n내일 새로운 단어로 만나요." 
                        : "매일 엄선된 10개 단어,\n지금 바로 암기를 시작하세요!",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(isCompleted ? Icons.check_circle_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBanner(String? recommendedLevel) {
    return GestureDetector(
      onTap: () async {
        if (recommendedLevel != null) {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: recommendedLevel)));
          _refresh();
        } else {
          _showLevelTestGuide(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.indigo.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle),
              child: Icon(Icons.stars_rounded, color: Colors.amber[700], size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendedLevel != null ? "맞춤 추천 레벨: TOEIC $recommendedLevel" : "실력 진단 테스트",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    recommendedLevel != null ? "지금 바로 내 수준에 맞게 시작하세요!" : "3분 만에 정확한 내 실력 확인하기",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelectionRow() {
    return Row(
      children: [
        _buildLevelMiniCard("500", "입문", const Color(0xFF4FACFE), const Color(0xFF00F2FE)),
        const SizedBox(width: 12),
        _buildLevelMiniCard("700", "중급", const Color(0xFF43E97B), const Color(0xFF38F9D7)),
        const SizedBox(width: 12),
        _buildLevelMiniCard("900+", "실전", const Color(0xFFFA709A), const Color(0xFFFEE140)),
      ],
    );
  }

  Widget _buildLevelMiniCard(String level, String desc, Color c1, Color c2) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: level)));
          _refresh();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: c1.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              Text(level, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityRow() {
    return Row(
      children: [
        _buildUtilityCard("오답노트", Icons.edit_note_rounded, Colors.orange, () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage()));
          _refresh();
        }),
        const SizedBox(width: 16),
        _buildUtilityCard("중요 단어", Icons.star_rounded, Colors.amber, () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScrapPage()));
          _refresh();
        }),
      ],
    );
  }

  Widget _buildUtilityCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
      final Map<String, Word> wordLookup = {for (var w in box.values) w.spelling: w};
      for (String spelling in savedSpellings) {
        final word = wordLookup[spelling];
        if (word != null) todaysWords.add(word);
      }
    }

    if (todaysWords.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      List<Word> reviewWords = box.values.where((w) => w.type == 'Word' && (w.reviewStep ?? 0) > 0 && !w.nextReviewDate.isAfter(today)).toList();
      List<Word> newWords = box.values.where((w) => w.type == 'Word' && (w.reviewStep ?? 0) == 0).toList();
      reviewWords.shuffle();
      newWords.shuffle();
      todaysWords.addAll(reviewWords.take(10));
      if (todaysWords.length < 10) todaysWords.addAll(newWords.take(10 - todaysWords.length));
      cacheBox.put(todayKey, todaysWords.map((w) => w.spelling).toList());
    }

    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => TodaysWordListPage(words: todaysWords, isCompleted: isCompleted)));
  }
}
