import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'quiz_page.dart';
import 'seasonal_background.dart';
import 'theme_manager.dart';

class WrongAnswerPage extends StatefulWidget {
  const WrongAnswerPage({super.key});

  @override
  State<WrongAnswerPage> createState() => _WrongAnswerPageState();
}

class _WrongAnswerPageState extends State<WrongAnswerPage> {
  late Box<Word> _wrongBox;

  @override
  void initState() {
    super.initState();
    _wrongBox = Hive.box<Word>('wrong_answers');
  }

  void _deleteWord(String key) {
    _wrongBox.delete(key);
    setState(() {});
  }

  void _showDeleteAllDialog() {
    if (_wrongBox.isEmpty) return;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 24),
            Text("오답노트 비우기", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: ThemeManager.textColor)),
            const SizedBox(height: 12),
            Text("저장된 모든 오답을 삭제할까요?\n삭제된 데이터는 복구할 수 없습니다.", textAlign: TextAlign.center, style: TextStyle(color: ThemeManager.subTextColor, fontSize: 14, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("취소", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _wrongBox.clear();
                      if (mounted) { setState(() {}); Navigator.pop(context); }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text("삭제", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wrongWords = _wrongBox.values.toList().reversed.toList();
    final textColor = ThemeManager.textColor;
    final isDark = ThemeManager.isDarkMode;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("오답노트 📝", style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (wrongWords.isNotEmpty)
              IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: _showDeleteAllDialog),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: wrongWords.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => QuizPage(dayWords: wrongWords, isWrongAnswerQuiz: true)));
                },
                backgroundColor: isDark ? Theme.of(context).colorScheme.primary : const Color(0xFF1E293B),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text("오답 퀴즈", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
        body: wrongWords.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded, size: 60, color: Colors.green[300]),
                    ),
                    const SizedBox(height: 24),
                    Text("틀린 문제가 없어요!\n완벽합니다! 👍", textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: ThemeManager.subTextColor, fontWeight: FontWeight.bold, height: 1.5)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: wrongWords.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final word = wrongWords[index];
                  Color levelColor = word.level.contains('900') ? Colors.purple : (word.level.contains('700') ? Colors.indigo : Colors.teal);

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(word.spelling, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: textColor)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: levelColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(word.level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? levelColor.withOpacity(0.8) : levelColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(word.meaning, style: TextStyle(fontSize: 15, color: ThemeManager.subTextColor, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white24 : Colors.grey[300], size: 20),
                          onPressed: () => _deleteWord(word.spelling),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
