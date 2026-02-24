import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'study_record_service.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: isPerfect
            ? _buildPerfectView(context)
            : _buildWrongAnswerView(context, score),
      ),
    );
  }

  // 1. 만점 화면 (완료 처리 가능)
  Widget _buildPerfectView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 100,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "만점이에요! 🎉",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTodaysQuiz
                  ? "오늘 학습 목표를 완벽하게 달성했어요!\n출석 도장이 찍혔습니다."
                  : "모든 문제를 맞히셨네요!\n정말 대단한 실력이에요.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
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
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  isTodaysQuiz ? "학습 완료 (메인으로)" : "확인 (메인으로)",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 오답 화면 (완료 처리 불가, 재도전 유도)
  Widget _buildWrongAnswerView(BuildContext context, int score) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                isTodaysQuiz ? "아쉬워요! 다시 도전해볼까요? 💪" : "퀴즈 결과",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$score",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    " / $totalCount",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isTodaysQuiz 
                    ? "만점을 받아야 학습이 완료됩니다!"
                    : "${wrongAnswers.length}개를 틀렸어요. 오답을 확인해보세요.",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: wrongAnswers.length,
            itemBuilder: (context, index) {
              final item = wrongAnswers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: Colors.red.shade400, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          item['spelling'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text("내가 쓴 답", style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(
                                  item['userAnswerInfo'] != null && item['userAnswerInfo'].isNotEmpty
                                      ? "${item['userAnswer']}\n(${item['userAnswerInfo']})"
                                      : "${item['userAnswer']}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400),
                          Expanded(
                            child: Column(
                              children: [
                                const Text("정답", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(
                                  item['correctAnswerInfo'] != null && item['correctAnswerInfo'].isNotEmpty
                                      ? "${item['correctAnswer']}\n(${item['correctAnswerInfo']})"
                                      : "${item['correctAnswer']}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
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

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // ★ 만점이 아닐 때는 완료 처리 없이 이전 화면(단어 리스트)으로 돌아가 재도전 유도
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isTodaysQuiz ? "틀린 단어 복습하고 재도전하기" : "확인",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
