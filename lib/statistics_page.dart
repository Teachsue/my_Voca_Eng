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
  int _learnedWordsCount = 0;

  bool _isTodayCompleted = false;
  String _recommendedLevel = "미응시";

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    final wordBox = Hive.box<Word>('words');

    final Map<String, Word> uniqueMap = {};
    for (var w in wordBox.values.where((w) => w.type == 'Word')) {
      uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
    }
    _totalWordsCount = uniqueMap.length;

    if (Hive.isBoxOpen('wrong_answers')) {
      final wrongBox = Hive.box<Word>('wrong_answers');
      _wrongAnswersCount = wrongBox.length;
    }

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

    List<String> learnedWords = List<String>.from(
      cacheBox.get('learned_words', defaultValue: []),
    );
    _learnedWordsCount = learnedWords.length;

    setState(() {});
  }

  void _resetLevelTest() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "실력 진단 초기화",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "기존 레벨 테스트 결과가 삭제되며\n메인 화면에서 다시 응시할 수 있습니다.\n진행하시겠습니까?",
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final cacheBox = Hive.box('cache');
                cacheBox.delete('user_recommended_level');
                cacheBox.delete('level_test_progress');

                setState(() {
                  _recommendedLevel = "미응시";
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("레벨 테스트가 초기화되었습니다. 다시 도전해보세요! ✨"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "초기화",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetAllRecords() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                "전체 기록 초기화",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: const Text(
            "학습한 단어장, 오답 노트, 오늘의 퀴즈 완료 현황, 레벨 테스트 등 모든 개인 학습 데이터가 영구적으로 삭제됩니다.\n\n정말 처음부터 다시 시작하시겠습니까?",
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "취소",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (Hive.isBoxOpen('wrong_answers')) {
                  await Hive.box<Word>('wrong_answers').clear();
                }

                await Hive.box('cache').clear();

                try {
                  if (Hive.isBoxOpen('study_records')) {
                    await Hive.box('study_records').clear();
                  } else {
                    final recordBox = await Hive.openBox('study_records');
                    await recordBox.clear();
                  }
                } catch (e) {
                  print("캘린더 데이터 초기화 실패: $e");
                }

                setState(() {
                  _wrongAnswersCount = 0;
                  _learnedWordsCount = 0;
                  _isTodayCompleted = false;
                  _recommendedLevel = "미응시";
                });

                if (!mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("모든 학습 기록 및 캘린더가 깔끔하게 초기화되었습니다! 🧹"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "전체 초기화",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double progressRatio = _totalWordsCount > 0
        ? (_learnedWordsCount / _totalWordsCount)
        : 0.0;
    String percentString = (progressRatio * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "학습 통계 및 설정 📊",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "나의 학습 현황",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 상단 2분할 카드
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "추천 레벨",
                      value: _recommendedLevel == "미응시"
                          ? "평가 필요"
                          : "TOEIC $_recommendedLevel",
                      icon: Icons.psychology_alt_rounded,
                      color: Colors.indigo,
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 진도율 및 오답노트 카드 (UI 개선 적용)
            _buildProgressCard(
              title: "전체 학습 진도율",
              subtitle: "학습한 단어: $_learnedWordsCount / 총 $_totalWordsCount단어",
              valueText: "$percentString%",
              icon: Icons.trending_up_rounded,
              color: Colors.blueAccent,
              progressValue: progressRatio,
            ),
            const SizedBox(height: 16),

            _buildProgressCard(
              title: "복습이 필요한 단어",
              subtitle: "오답 노트에 쌓인 단어를 틈틈이 복습하세요!",
              valueText: "$_wrongAnswersCount개",
              icon: Icons.note_alt_rounded,
              color: Colors.redAccent,
              progressValue: _totalWordsCount > 0
                  ? (_wrongAnswersCount / _totalWordsCount)
                  : 0.0,
            ),

            const SizedBox(height: 40),

            // 데이터 관리 영역 (설정 메뉴 스타일로 개선)
            const Text(
              "데이터 관리",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                children: [
                  _buildSettingsTile(
                    title: "레벨 테스트 초기화",
                    subtitle: "다시 실력을 진단받고 싶을 때 사용하세요",
                    icon: Icons.refresh_rounded,
                    iconColor: Colors.blueGrey,
                    onTap: _recommendedLevel != "미응시" ? _resetLevelTest : null,
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 20,
                    endIndent: 20,
                  ),
                  _buildSettingsTile(
                    title: "모든 학습 기록 초기화",
                    subtitle: "데이터를 완전히 지우고 처음부터 시작합니다",
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: _resetAllRecords,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            Center(
              child: Text(
                "꾸준함이 실력을 만듭니다!\n오늘도 파이팅하세요 🔥",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 상단 작은 네모 카드
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 변경됨: 진도율 / 오답노트 전용 세련된 프로그레스 카드
  Widget _buildProgressCard({
    required String title,
    required String subtitle,
    required String valueText,
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ★ 추가됨: 데이터 관리 버튼들을 위한 리스트 타일 위젯
  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color textColor = Colors.black87,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onTap == null ? Colors.grey : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onTap == null ? Colors.transparent : Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
