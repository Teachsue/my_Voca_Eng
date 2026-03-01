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
    _isTodayCompleted = cacheBox.get("today_completed_$todayStr", defaultValue: false);
    _recommendedLevel = cacheBox.get('user_recommended_level', defaultValue: "미응시");

    List<String> learnedWords = List<String>.from(cacheBox.get('learned_words', defaultValue: []));
    _learnedWordsCount = learnedWords.length;

    setState(() {});
  }

  void _resetLevelTest() {
    _showConfirmDialog(
      title: "진단 결과 초기화",
      content: "레벨 테스트 기록을 삭제할까요?\n메인 화면에서 다시 응시할 수 있습니다.",
      onConfirm: () {
        final cacheBox = Hive.box('cache');
        cacheBox.delete('user_recommended_level');
        cacheBox.delete('level_test_progress');
        setState(() => _recommendedLevel = "미응시");
      },
    );
  }

  void _resetAllRecords() {
    _showConfirmDialog(
      title: "전체 기록 초기화",
      content: "모든 학습 데이터가 영구 삭제됩니다.\n정말 처음부터 다시 시작하시겠습니까?",
      isDestructive: true,
      onConfirm: () async {
        if (Hive.isBoxOpen('wrong_answers')) await Hive.box<Word>('wrong_answers').clear();
        await Hive.box('cache').clear();
        final wordBox = Hive.box<Word>('words');
        for (var word in wordBox.values) {
          if (word.isScrap) {
            word.isScrap = false;
            word.save();
          }
        }
        _loadStatistics();
      },
    );
  }

  void _showConfirmDialog({required String title, required String content, required VoidCallback onConfirm, bool isDestructive = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : Colors.indigo).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                color: isDestructive ? Colors.redAccent : Colors.indigo,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text("취소", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? Colors.redAccent : Colors.indigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("확인", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    double progressRatio = _totalWordsCount > 0 ? (_learnedWordsCount / _totalWordsCount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("학습 통계 및 설정", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("나의 학습 진도"),
                _buildMainDashboard(progressRatio),
                const SizedBox(height: 25),
                _buildSectionHeader("학습 요약"),
                Row(
                  children: [
                    Expanded(child: _buildInfoCard("추천 레벨", _recommendedLevel == "미응시" ? "미응시" : "TOEIC $_recommendedLevel", Icons.stars_rounded, Colors.indigo)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildInfoCard("오늘 목표", _isTodayCompleted ? "달성" : "진행중", Icons.local_fire_department_rounded, _isTodayCompleted ? Colors.orange : Colors.grey[400]!)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildWideInfoCard("복습 필요한 단어", "$_wrongAnswersCount개", Icons.assignment_late_rounded, Colors.redAccent),
                const SizedBox(height: 30),
                _buildSectionHeader("시스템 설정"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile("레벨 테스트 초기화", Icons.refresh_rounded, Colors.blueGrey, _recommendedLevel != "미응시" ? _resetLevelTest : null),
                      Divider(height: 1, color: Colors.grey[100]),
                      _buildSettingsTile("모든 학습 기록 초기화", Icons.delete_forever_rounded, Colors.redAccent, _resetAllRecords),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // 하단에 기분 좋은 여백 남김
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildMainDashboard(double ratio) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("전체 진도율", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
              Text("${(ratio * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.indigo.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text("$_learnedWordsCount / $_totalWordsCount 단어 학습 완료", style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWideInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, Color color, VoidCallback? onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: onTap == null ? Colors.grey[200] : color, size: 24),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onTap == null ? Colors.grey[300] : Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
    );
  }
}
