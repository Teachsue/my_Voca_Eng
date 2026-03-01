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
import 'scrap_page.dart'; 
import 'theme_manager.dart';
import 'settings_page.dart';
import 'seasonal_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(WordAdapter());
  await Hive.openBox<Word>('words');
  await Hive.openBox('cache');
  await Hive.openBox<Word>('wrong_answers');
  await StudyRecordService.init();
  await initializeDateFormatting();
  await DataLoader.loadData(); 
  await ThemeManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Season>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, season, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeManager.isDarkModeNotifier,
          builder: (context, isDark, _) {
            return MaterialApp(
              title: '포켓보카',
              debugShowCheckedModeBanner: false,
              theme: ThemeManager.getThemeData(),
              home: const HomePage(),
            );
          },
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _refresh() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    String? recommendedLevel = cacheBox.get('user_recommended_level');
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = ThemeManager.textColor;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, textColor, primaryColor),
                const SizedBox(height: 32),
                _buildMainBanner(context, isCompleted),
                const SizedBox(height: 16),
                _buildLevelBanner(context, recommendedLevel, primaryColor),
                const SizedBox(height: 40),
                Text("TOEIC 난이도별 학습", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                _buildLevelGrid(context),
                const SizedBox(height: 36),
                Text("나의 학습 도구", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                _buildUtilityRow(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ★ 포켓보카 정식 브랜드 로고 디자인 (미니멀 대비 스타일)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "포켓",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800, // ★ 단단한 볼드
                      color: textColor,
                      letterSpacing: -1.2,
                    ),
                  ),
                  TextSpan(
                    text: "보카",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w200, // ★ 아주 가볍고 얇은 스타일
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
              style: TextStyle(fontSize: 10, color: ThemeManager.subTextColor, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(
              icon: Icons.calendar_month_rounded,
              color: primaryColor,
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage())); _refresh(); },
            ),
            const SizedBox(width: 10),
            _buildHeaderIconButton(
              icon: Icons.settings_rounded,
              color: textColor.withOpacity(0.7),
              onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())); _refresh(); },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = ThemeManager.isDarkMode;
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(icon: Icon(icon, color: color, size: 22), onPressed: onTap, padding: EdgeInsets.zero),
    );
  }

  Widget _buildMainBanner(BuildContext context, bool isCompleted) {
    final bannerGradient = ThemeManager.bannerGradient;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () async { await _startTodaysQuiz(); _refresh(); },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted ? [const Color(0xFF4B5563), const Color(0xFF1F2937)] : bannerGradient,
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: (isCompleted ? Colors.black12 : bannerGradient[0].withOpacity(0.3)), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCompleted ? "학습 완료! ✅" : "오늘의 단어 학습", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(isCompleted ? "멋진 성취입니다. 내일 또 만나요!" : "매일 10개 단어로 만드는 기적", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBanner(BuildContext context, String? recommendedLevel, Color pointColor) {
    final bool hasResult = recommendedLevel != null;
    final isDark = ThemeManager.isDarkMode;
    return GestureDetector(
      onTap: () async {
        if (hasResult) await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: recommendedLevel)));
        else _showLevelTestGuide(context);
        _refresh();
      },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : (hasResult ? const Color(0xFFF0F7FF) : Colors.white.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(hasResult ? Icons.workspace_premium_rounded : Icons.psychology_alt_rounded, color: hasResult ? const Color(0xFF5B86E5) : pointColor, size: 26),
            const SizedBox(width: 12),
            Expanded(child: Text(hasResult ? "추천 레벨: TOEIC $recommendedLevel" : "나의 단어 실력 진단하기", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569)))),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3,
      children: [
        _buildLevelCard(context, "500", "입문", Colors.teal),
        _buildLevelCard(context, "700", "중급", Colors.indigo),
        _buildLevelCard(context, "900+", "실전", Colors.purple),
      ],
    );
  }

  Widget _buildLevelCard(BuildContext context, String level, String desc, Color color) {
    final isDark = ThemeManager.isDarkMode;
    return GestureDetector(
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => DaySelectionPage(category: 'TOEIC', level: level))); _refresh(); },
      child: Container(
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(level, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? color.withOpacity(0.8) : color, letterSpacing: -0.5)),
            Text(desc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600], fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCategoryCard(context, "오답노트", "틀린 단어", Icons.edit_document, const Color(0xFFF59E0B), () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const WrongAnswerPage())); _refresh(); })),
        const SizedBox(width: 12),
        Expanded(child: _buildCategoryCard(context, "중요단어", "스크랩", Icons.star_rounded, const Color(0xFFFACC15), () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScrapPage())); _refresh(); })),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = ThemeManager.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ThemeManager.textColor)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showLevelTestGuide(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.psychology_alt_rounded, color: primaryColor, size: 40)),
              const SizedBox(height: 24),
              Text("실력 진단 테스트", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: ThemeManager.textColor)),
              const SizedBox(height: 20),
              _buildCriteriaItem(context, Icons.format_list_numbered_rounded, "총 15개 문항 구성", "레벨별(500/700/900) 5문제씩 출제"),
              _buildCriteriaItem(context, Icons.auto_graph_rounded, "맞춤 레벨 추천", "정답률 분석을 통한 최적의 난이도 배정"),
              _buildCriteriaItem(context, Icons.timer_outlined, "약 3분 소요", "빠르고 정확하게 실력을 확인하세요"),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("다음에 할게요", style: TextStyle(color: ThemeManager.subTextColor, fontSize: 16, fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () async { Navigator.pop(dialogContext); await Navigator.push(context, MaterialPageRoute(builder: (context) => const LevelTestPage())); _refresh(); }, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text("시작하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCriteriaItem(BuildContext context, IconData icon, String title, String desc) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryColor.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThemeManager.textColor)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 13, color: ThemeManager.subTextColor)),
              ],
            ),
          ),
        ],
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
      reviewWords.shuffle(); newWords.shuffle();
      todaysWords.addAll(reviewWords.take(10));
      if (todaysWords.length < 10) todaysWords.addAll(newWords.take(10 - todaysWords.length));
      cacheBox.put(todayKey, todaysWords.map((w) => w.spelling).toList());
    }
    bool isCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => TodaysWordListPage(words: todaysWords, isCompleted: isCompleted)));
  }
}
