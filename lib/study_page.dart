import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'quiz_page.dart';
import 'seasonal_background.dart';
import 'theme_manager.dart';

class StudyPage extends StatefulWidget {
  final String category;
  final String level;
  final List<List<Word>> allDayChunks;
  final int initialDayIndex;

  const StudyPage({
    super.key,
    required this.category,
    required this.level,
    required this.allDayChunks,
    required this.initialDayIndex,
  });

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late PageController _pageController;
  late int _currentDayIndex;
  late List<List<Word>> _shuffledDayChunks;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = widget.initialDayIndex;
    _pageController = PageController(initialPage: _currentDayIndex);
    _shuffledDayChunks = [];
    for (var chunk in widget.allDayChunks) {
      List<Word> shuffledChunk = List<Word>.from(chunk);
      shuffledChunk.shuffle();
      _shuffledDayChunks.add(shuffledChunk);
    }
    _saveLastStudiedDay(_currentDayIndex + 1);
  }

  void _saveLastStudiedDay(int dayNumber) {
    final cacheBox = Hive.box('cache');
    final key = "last_studied_day_${widget.category}_${widget.level}";
    cacheBox.put(key, dayNumber);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = ThemeManager.textColor;
    final subTextColor = ThemeManager.subTextColor;
    final isDark = ThemeManager.isDarkMode;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("${widget.category} ${widget.level} - DAY ${_currentDayIndex + 1}", style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor), onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(icon: Icon(Icons.home_rounded, color: textColor), onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)),
            const SizedBox(width: 8),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() { _currentDayIndex = index; });
            _saveLastStudiedDay(_currentDayIndex + 1);
          },
          itemCount: _shuffledDayChunks.length,
          itemBuilder: (context, dayIndex) {
            final dayWords = _shuffledDayChunks[dayIndex];
            final int dayNumber = dayIndex + 1;

            return Column(
              children: [
                Expanded(
                  child: dayWords.isEmpty
                      ? Center(child: Text("등록된 단어가 없습니다.", style: TextStyle(color: subTextColor)))
                      : ListView.separated(
                          key: ValueKey("list_$dayIndex"),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: dayWords.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final word = dayWords[index];
                            return StatefulBuilder(
                              builder: (context, setStateItem) {
                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32, height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.15), shape: BoxShape.circle),
                                        child: Text("${index + 1}", style: TextStyle(color: isDark ? primaryColor.withOpacity(0.8) : primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(word.spelling, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                                            const SizedBox(height: 2),
                                            Text(word.meaning, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () { setStateItem(() { word.isScrap = !word.isScrap; word.save(); }); },
                                        icon: Icon(word.isScrap ? Icons.star_rounded : Icons.star_border_rounded, color: word.isScrap ? Colors.amber : (isDark ? Colors.white24 : Colors.grey[300]), size: 28),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white.withOpacity(0.9),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
                  ),
                  child: SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => QuizPage(category: widget.category, level: widget.level, dayNumber: dayNumber, dayWords: dayWords)));
                      },
                      icon: const Icon(Icons.edit_document, size: 22),
                      label: Text("DAY $dayNumber 퀴즈 풀기", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? primaryColor : const Color(0xFF1E293B), 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), 
                        elevation: 0
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
