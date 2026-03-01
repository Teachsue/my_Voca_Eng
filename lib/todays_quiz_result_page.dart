import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'study_record_service.dart';
import 'theme_manager.dart';
import 'seasonal_background.dart';

class TodaysQuizResultPage extends StatelessWidget {
  final List<Map<String, dynamic>> wrongAnswers;
  final int totalCount;
  final bool isTodaysQuiz;

  const TodaysQuizResultPage({
    super.key,
    required this.wrongAnswers,
    required this.totalCount,
    this.isTodaysQuiz = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isPerfect = wrongAnswers.isEmpty;
    int score = totalCount - wrongAnswers.length;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = ThemeManager.textColor;
    final isDark = ThemeManager.isDarkMode;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: isPerfect
              ? _buildPerfectView(context, primaryColor, textColor, isDark)
              : _buildWrongAnswerView(context, score, primaryColor, textColor, isDark),
        ),
      ),
    );
  }

  Widget _buildPerfectView(BuildContext context, Color color, Color textColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: color,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              "참 잘했어요! 🎉",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTodaysQuiz
                  ? "오늘의 목표를 완벽히 달성했습니다.\n꾸준함이 실력을 만듭니다."
                  : "모든 문제를 맞히셨습니다.\n정말 대단해요!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: ThemeManager.subTextColor, height: 1.6, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () async {
                  if (isTodaysQuiz) {
                    final cacheBox = Hive.box('cache');
                    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    cacheBox.put("today_completed_$todayStr", true);
                    await StudyRecordService.markTodayAsDone();
                  }
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: isDark ? BorderSide(color: color.withOpacity(0.5), width: 1.5) : BorderSide.none,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "완료 (메인으로)", 
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? color : Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswerView(BuildContext context, int score, Color color, Color textColor, bool isDark) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Text(
                isTodaysQuiz ? "조금 더 힘내볼까요? 💪" : "퀴즈 결과",
                style: TextStyle(color: ThemeManager.subTextColor, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$score",
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color),
                  ),
                  Text(
                    " / $totalCount",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white10 : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "오답을 확인하고 재도전해 보세요.",
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: wrongAnswers.length,
            itemBuilder: (context, index) {
              final item = wrongAnswers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['spelling'] ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("내가 고른 답", style: TextStyle(fontSize: 11, color: ThemeManager.subTextColor, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                item['userAnswer'] ?? '',
                                style: const TextStyle(color: Colors.redAccent, decoration: TextDecoration.lineThrough, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("올바른 정답", style: TextStyle(fontSize: 11, color: ThemeManager.subTextColor, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                item['correctAnswer'] ?? '',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF334155) : color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isDark ? BorderSide(color: color.withOpacity(0.5), width: 1.5) : BorderSide.none,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "다시 시도하기", 
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? color : Colors.white)
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    "메인으로 돌아가기", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.6))
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
