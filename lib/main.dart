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
import 'scrap_page.dart'; // ★ 나만의 단어장 import 추가

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

  // ★★★ 여기가 핵심입니다! (에러 방지 쉴드 장착) ★★★
  try {
    await Hive.openBox<Word>('words');
  } catch (e) {
    print("⚠️ words DB 충돌 감지! 기존 데이터 삭제 후 초기화 진행...");
    await Hive.deleteBoxFromDisk('words');
    await Hive.openBox<Word>('words');
  }

  try {
    await Hive.openBox('cache');
  } catch (e) {
    await Hive.deleteBoxFromDisk('cache');
    await Hive.openBox('cache');
  }

  try {
    await Hive.openBox<Word>('wrong_answers');
  } catch (e) {
    await Hive.deleteBoxFromDisk('wrong_answers');
    await Hive.openBox<Word>('wrong_answers');
  }

  await StudyRecordService.init();
  await initializeDateFormatting();
  await DataLoader.loadData(); // 기존 데이터가 날아갔다면 여기서 다시 1940개를 채워줍니다.

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.psychology_alt_rounded,
                color: Colors.indigo,
                size: 50,
              ),
              SizedBox(height: 15),
              Text(
                "실력 진단 테스트 안내",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "내 실력에 딱 맞는 단어장을 추천해 드릴게요!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text("총 15개 문항 (레벨별 5문제)")),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(child: Text("예상 소요 시간: 약 3분")),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text("분석 결과에 따른 맞춤 레벨 배정")),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "다음에 할게요",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LevelTestPage(),
                        ),
                      );
                      _refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "시험 시작하기!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    bool isCompleted = cacheBox.get(
      "today_completed_$todayStr",
      defaultValue: false,
    );

    String? recommendedLevel = cacheBox.get('user_recommended_level');
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 750;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: isSmallScreen
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 15.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ★ 상단 헤더 영역 수정 (설정 아이콘 추가)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "안녕하세요! 👋",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "오늘도 열공해볼까요?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // ★ 학습 통계 및 설정 버튼 (상단 우측으로 이동)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings_rounded, // 설정 느낌의 아이콘으로 변경
                              color: Colors.blueGrey,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StatisticsPage(),
                                ),
                              );
                              _refresh();
                            },
                          ),
                        ),
                        const SizedBox(width: 12), // 캘린더 버튼과의 간격
                        // 캘린더 버튼
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.indigo,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CalendarPage(),
                                ),
                              );
                              _refresh();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Column(
                  children: [
                    // 오늘의 단어 배너
                    GestureDetector(
                      onTap: () async {
                        await _startTodaysQuiz();
                        _refresh();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [
                                    const Color(0xFF5B86E5),
                                    const Color(0xFF36D1DC),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isCompleted
                                  ? Colors.grey.withOpacity(0.3)
                                  : const Color(0xFF5B86E5).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isCompleted
                                        ? "훌륭합니다! 내일 다시 만나요.\n복습은 언제나 환영이에요."
                                        : "매일 10개씩 꾸준히!\n지금 바로 시작하세요.",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 실력 진단 / 맞춤 학습 배너
                    GestureDetector(
                      onTap: () async {
                        if (recommendedLevel != null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DaySelectionPage(
                                category: 'TOEIC',
                                level: recommendedLevel,
                              ),
                            ),
                          );
                          _refresh();
                        } else {
                          _showLevelTestGuide(context);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                recommendedLevel != null
                                    ? Icons.auto_awesome_rounded
                                    : Icons.psychology_alt_rounded,
                                color: Colors.indigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recommendedLevel != null
                                        ? "내 실력에 맞는 맞춤 학습"
                                        : "내 진짜 실력은 어느 정도일까?",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    recommendedLevel != null
                                        ? "💡 추천: TOEIC $recommendedLevel\n터치하여 단어장으로 이동!"
                                        : "딱 3분! 실력 진단 테스트 시작하기",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: recommendedLevel != null
                                          ? Colors.indigo[600]
                                          : Colors.grey[500],
                                      fontWeight: recommendedLevel != null
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey[400],
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                const Text(
                  "Study Category",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // ★ 완벽한 2x2 그리드 배열
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.30,
                  children: [
                    _buildMenuCard(
                      title: "TOEIC",
                      subtitle: "실전 대비",
                      icon: Icons.business_center_rounded,
                      color: Colors.blueAccent,
                      onTap: () async {
                        await _showLevelDialog('TOEIC', ['500', '700', '900+']);
                        _refresh();
                      },
                    ),
                    _buildMenuCard(
                      title: "OPIc",
                      subtitle: "오픽 단어 연습",
                      icon: Icons.record_voice_over_rounded,
                      color: Colors.orangeAccent,
                      onTap: () async {
                        await _showLevelDialog('OPIC', ['IM', 'IH', 'AL']);
                        _refresh();
                      },
                    ),
                    _buildMenuCard(
                      title: "오답노트",
                      subtitle: "틀린 문제 복습",
                      icon: Icons.note_alt_rounded,
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
                      title: "나만의 단어장",
                      subtitle: "저장한 단어 모아보기",
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScrapPage(),
                          ),
                        );
                        _refresh();
                      },
                    ),
                  ],
                ),
              ],
            ),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
    await Navigator.push(
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "$category 레벨 선택",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: levels.map((level) {
              return ListTile(
                title: Text(
                  level,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey[400],
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DaySelectionPage(category: category, level: level),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
