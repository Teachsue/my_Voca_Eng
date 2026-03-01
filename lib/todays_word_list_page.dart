import 'package:flutter/material.dart';
import 'word_model.dart';
import 'todays_quiz_page.dart';
import 'theme_manager.dart';
import 'seasonal_background.dart';

class TodaysWordListPage extends StatelessWidget {
  final List<Word> words;
  final bool isCompleted;

  const TodaysWordListPage({
    super.key,
    required this.words,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final List<Color> bannerGradient = ThemeManager.bannerGradient;
    final isDark = ThemeManager.isDarkMode;
    final textColor = ThemeManager.textColor;
    
    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            isCompleted ? "복습 리스트" : "오늘의 단어",
            style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCompleted 
                    ? [const Color(0xFF4B5563), const Color(0xFF1F2937)] 
                    : bannerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                          isCompleted ? "학습 완료! ✨" : "오늘의 도전 🧐",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCompleted ? "정말 고생하셨습니다." : "10개 단어를 완벽히 익혀보세요.",
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? primaryColor.withOpacity(0.8) : primaryColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word.spelling,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                word.meaning,
                                style: TextStyle(fontSize: 14, color: ThemeManager.subTextColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (isCompleted) Navigator.pop(context);
                else Navigator.push(context, MaterialPageRoute(builder: (context) => TodaysQuizPage(words: words)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? const Color(0xFF374151) : primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                isCompleted ? "확인 완료" : "다 외웠어요! 퀴즈 시작",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
