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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Column(
            children: [
              Icon(Icons.psychology_alt_rounded, color: Colors.indigo, size: 50),
              SizedBox(height: 15),
              Text("실력 진단 테스트 안내", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("내 실력에 딱 맞는 단어장을 추천해 드릴게요!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 20),
              Row(children: [Icon(Icons.check_circle_outline, size: 18, color: Colors.grey), SizedBox(width: 10), Expanded(child: Text("총 15개 문항 (레벨별 5문제)"))]),
              SizedBox(height: 8),
              Row(children: [Icon(Icons.timer_outlined, size: 18, color: Colors.grey), SizedBox(width: 10), Expanded(child: Text("예상 소요 시간: 약 3분"))]),
              SizedBox(height: 8),
              Row(children: [Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.grey), SizedBox(width: 10), Expanded(child: Text("분석 결과에 따른 맞춤 레벨 배정"))]),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("다음에 할게요", style: TextStyle(color: Colors.grey)),
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
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("시험 시작하기!", style: TextStyle(fontWeight: FontWeight.bold)),
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
    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    String? recommendedLevel = cacheBox.get('user_recommended_level');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 25),
                      _buildMainBanner(isCompleted),
                      const SizedBox(height: 12),
                      _buildLevelBanner(recommendedLevel),
                      const SizedBox(height: 30),
                      const Text("Study Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      _buildCategoryGrid(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            Text("안녕하세요! 👋", style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text("오늘도 열공해볼까요?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(icon: Icon(icon, color: color), onPressed: onTap),
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
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted ? [Colors.grey.shade400, Colors.grey.shade500] : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: (isCompleted ? Colors.grey : const Color(0xFF5B86E5)).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCompleted ? "오늘의 학습 완료! ✅" : "오늘의 영단어 🔥", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(isCompleted ? "훌륭합니다! 내일 다시 만나요.\n복습은 언제나 환영이에요." : "매일 10개씩 꾸준히!\n지금 바로 시작하세요.", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
              child: Icon(recommendedLevel != null ? Icons.auto_awesome_rounded : Icons.psychology_alt_rounded, color: Colors.indigo, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recommendedLevel != null ? "내 실력에 맞는 맞춤 학습" : "내 진짜 실력은 어느 정도일까?", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(recommendedLevel != null ? "💡 추천: TOEIC $recommendedLevel (이동하기)" : "딱 3분! 실력 진단 테스트 시작하기", style: TextStyle(fontSize: 13, color: recommendedLevel != null ? Colors.indigo : Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.25,
      children: [
        _buildMenuCard(title: "TOEIC", subtitle: "실전 대비", icon: Icons.business_center_rounded, color: Colors.blueAccent, onTap: () async { await _showLevelDialog('TOEIC', ['500', '700', '900+']); _refresh(); }),
        _buildMenuCard(title: "OPIc", subtitle: "오픽 단어 연습", icon: Icons.record_voice_over_rounded, color: Colors.orangeAccent, onTap: () async { await _showLevelDialog('OPIC', ['IM', 'IH', 'AL']); _refresh(); }),
        _buildMenuCard(title: "오답노트", subtitle: "틀린 문제 복습", icon: Icons.note_alt_rounded, color: Colors.green, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage())); _refresh(); }),
        _buildMenuCard(title: "나만의 단어장", subtitle: "저장한 단어 모아보기", icon: Icons.star_rounded, color: Colors.amber, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScrapPage())); _refresh(); }),
      ],
    );
  }

  Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, color: color, size: 26)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
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

  Future<void> _showLevelDialog(String category, List<String> levels) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("$category 레벨 선택", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: levels.map((level) {
              return ListTile(
                title: Text(level, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: category, level: level)));
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
