import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'word_model.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _totalWordsCount = 0;
  int _wrongAnswersCount = 0;
  int _learnedWordsCount = 0; // ★ 추가: 퀴즈에서 맞춘 단어 수

  bool _isTodayCompleted = false;
  String _recommendedLevel = "미응시";

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    // 1. 전체 단어 수
    final wordBox = Hive.box<Word>('words');

    // 중복 없는 실제 단어 수 계산
    final Map<String, Word> uniqueMap = {};
    for (var w in wordBox.values.where((w) => w.type == 'Word')) {
      uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
    }
    _totalWordsCount = uniqueMap.length;

    // 2. 오답 노트 단어 수
    if (Hive.isBoxOpen('wrong_answers')) {
      final wrongBox = Hive.box<Word>('wrong_answers');
      _wrongAnswersCount = wrongBox.length;
    }

    // 3. 오늘 학습 완료 여부 & 추천 레벨 & ★ 마스터한 단어 수
    final cacheBox = Hive.box('cache');
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _isTodayCompleted = cacheBox.get(
      "today_completed_$todayStr",
      defaultValue: false,
    );
    _recommendedLevel = cacheBox.get(
      'user_recommended_level',
      defaultValue: "미응시",
    );

    // ★ 추가: 퀴즈에서 정답을 맞춘 단어 리스트 가져오기
    List<String> learnedWords = List<String>.from(
      cacheBox.get('learned_words', defaultValue: []),
    );
    _learnedWordsCount = learnedWords.length;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 진도율 계산 (0으로 나누기 방지)
    double progressRatio = _totalWordsCount > 0
        ? (_learnedWordsCount / _totalWordsCount)
        : 0.0;
    String percentString = (progressRatio * 100).toStringAsFixed(
      1,
    ); // 소수점 첫째 자리까지

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "학습 통계 📊",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "나의 학습 현황",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // [1] 레벨 & 오늘의 학습 상태
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "추천 학습 레벨",
                    value: _recommendedLevel == "미응시"
                        ? "평가 필요"
                        : "TOEIC\n$_recommendedLevel",
                    icon: Icons.psychology_alt_rounded,
                    color: Colors.indigo,
                    isSmallText: _recommendedLevel == "미응시",
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    title: "오늘의 목표",
                    value: _isTodayCompleted ? "달성 완료" : "진행 중",
                    icon: _isTodayCompleted
                        ? Icons.check_circle_rounded
                        : Icons.directions_run_rounded,
                    color: _isTodayCompleted ? Colors.green : Colors.orange,
                    isSmallText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // ★ [2] 새로운 기능: 전체 학습 진도율 (마스터한 단어)
            _buildWideStatCard(
              title: "전체 학습 진도율 ($percentString%)",
              subtitle: "퀴즈에서 한 번 이상 정답을 맞춘 단어의 비율입니다. 꾸준히 게이지를 채워보세요!",
              value: "$_learnedWordsCount / $_totalWordsCount",
              icon: Icons.trending_up_rounded,
              color: Colors.blueAccent,
              progressValue: progressRatio,
            ),
            const SizedBox(height: 15),

            // [3] 취약점 분석 (오답 노트)
            _buildWideStatCard(
              title: "현재 복습이 필요한 단어",
              subtitle: "오답 노트에 쌓인 단어 수입니다. 틈틈이 복습해주세요!",
              value: "$_wrongAnswersCount개",
              icon: Icons.note_alt_rounded,
              color: Colors.redAccent,
              progressValue: _totalWordsCount > 0
                  ? (_wrongAnswersCount / _totalWordsCount)
                  : 0.0,
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "꾸준함이 실력을 만듭니다!\n오늘도 파이팅하세요 🔥",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 정사각형 형태의 통계 카드 위젯
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // 직사각형 형태의 넓은 통계 카드 위젯
  Widget _buildWideStatCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
