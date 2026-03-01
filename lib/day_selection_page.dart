import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'study_page.dart';
import 'quiz_page.dart';
import 'theme_manager.dart';
import 'seasonal_background.dart';

class DaySelectionPage extends StatefulWidget {
  final String category;
  final String level;

  const DaySelectionPage({
    super.key,
    required this.category,
    required this.level,
  });

  @override
  State<DaySelectionPage> createState() => _DaySelectionPageState();
}

class _DaySelectionPageState extends State<DaySelectionPage> {
  List<List<Word>> _dayChunks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void _loadWords() {
    final box = Hive.box<Word>('words');
    final allWords = box.values
        .where((w) =>
            w.type == 'Word' &&
            w.category == widget.category &&
            w.level == widget.level)
        .toList();

    _dayChunks = [];
    for (var i = 0; i < allWords.length; i += 20) {
      _dayChunks.add(allWords.sublist(i, min(i + 20, allWords.length)));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _checkSavedQuizAndStart() {
    final cacheBox = Hive.box('cache');
    final savedData = cacheBox.get("quiz_progress_all_${widget.category}_${widget.level}");

    if (savedData != null) {
      _showResumeDialog(savedData);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            dayWords: _dayChunks.expand((x) => x).toList(),
            category: widget.category,
            level: widget.level,
          ),
        ),
      );
    }
  }

  void _showResumeDialog(dynamic savedData) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text("퀴즈 이어 풀기", style: TextStyle(fontWeight: FontWeight.bold, color: ThemeManager.textColor)),
        content: Text("이전에 풀던 기록이 있습니다. 이어서 푸시겠습니까?", style: TextStyle(color: ThemeManager.subTextColor)),
        actions: [
          TextButton(
            onPressed: () {
              Hive.box('cache').delete("quiz_progress_all_${widget.category}_${widget.level}");
              Navigator.pop(context);
              _checkSavedQuizAndStart();
            },
            child: Text("새로 풀기", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPage(
                    dayWords: _dayChunks.expand((x) => x).toList(),
                    category: widget.category,
                    level: widget.level,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text("이어서 풀기"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeManager.textColor;
    final isDark = ThemeManager.isDarkMode;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("${widget.category} ${widget.level}", style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContinueBanner(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text(
                      "학습 리스트",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _dayChunks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _dayChunks.length) return _buildTotalQuizCard(context);
                        return _buildDayCard(context, index);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContinueBanner(BuildContext context) {
    final cacheBox = Hive.box('cache');
    final int lastStudiedDay = cacheBox.get('last_studied_day_${widget.category}_${widget.level}', defaultValue: 1);
    final List<Color> bannerGradient = ThemeManager.bannerGradient;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyPage(
                category: widget.category,
                level: widget.level,
                allDayChunks: _dayChunks,
                initialDayIndex: lastStudiedDay - 1,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: bannerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAY $lastStudiedDay 이어하기",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "멈췄던 부분부터 학습을 시작하세요",
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int index) {
    final int dayNumber = index + 1;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cacheBox = Hive.box('cache');
    final int lastDay = cacheBox.get('last_studied_day_${widget.category}_${widget.level}', defaultValue: 1);
    final bool isCurrent = lastDay == dayNumber;
    final isDark = ThemeManager.isDarkMode;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudyPage(
              category: widget.category,
              level: widget.level,
              allDayChunks: _dayChunks,
              initialDayIndex: index,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: isCurrent ? Border.all(color: primaryColor.withOpacity(0.5), width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$dayNumber",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: isCurrent ? (isDark ? primaryColor : primaryColor) : ThemeManager.textColor,
              ),
            ),
            Text(
              "DAY",
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: isCurrent ? primaryColor.withOpacity(0.7) : ThemeManager.subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalQuizCard(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;
    return GestureDetector(
      onTap: _checkSavedQuizAndStart,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_alt_rounded, color: primaryColor, size: 24),
            const SizedBox(height: 4),
            Text(
              "전체 퀴즈",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
