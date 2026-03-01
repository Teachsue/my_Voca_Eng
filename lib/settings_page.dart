import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'theme_manager.dart';
import 'word_model.dart';
import 'seasonal_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _totalWordsCount = 0;
  int _learnedWordsCount = 0;
  int _wrongAnswersCount = 0;
  String _recommendedLevel = "미응시";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final wordBox = Hive.box<Word>('words');
    _totalWordsCount = wordBox.values.where((w) => w.type == 'Word').length;
    final cacheBox = Hive.box('cache');
    _learnedWordsCount = List<String>.from(cacheBox.get('learned_words', defaultValue: [])).length;
    _recommendedLevel = cacheBox.get('user_recommended_level', defaultValue: "미응시");
    _wrongAnswersCount = Hive.box<Word>('wrong_answers').length;
    if (mounted) setState(() {});
  }

  void _resetLevelTest() {
    _showConfirmDialog(
      title: "진단 결과 초기화",
      content: "레벨 테스트 기록을 삭제할까요?\n메인 화면에서 다시 응시할 수 있습니다.",
      onConfirm: () {
        final cacheBox = Hive.box('cache');
        cacheBox.delete('user_recommended_level');
        cacheBox.delete('level_test_progress');
        _loadData();
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
        _loadData();
      },
    );
  }

  void _showConfirmDialog({required String title, required String content, required VoidCallback onConfirm, bool isDestructive = false}) {
    final isDark = ThemeManager.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : Theme.of(context).colorScheme.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                color: isDestructive ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: ThemeManager.textColor)),
            const SizedBox(height: 12),
            Text(content, textAlign: TextAlign.center, style: TextStyle(color: ThemeManager.subTextColor, fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("취소", style: TextStyle(color: ThemeManager.subTextColor, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { onConfirm(); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? Colors.redAccent : Theme.of(context).colorScheme.primary,
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
    final currentSelected = ThemeManager.selectedSeason;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgGradient = ThemeManager.bgGradient;
    final isDark = ThemeManager.isDarkMode;
    double progress = _totalWordsCount > 0 ? (_learnedWordsCount / _totalWordsCount) : 0.0;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("설정 및 학습 리포트", style: TextStyle(fontWeight: FontWeight.w900, color: ThemeManager.textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: ThemeManager.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("나의 학습 현황"),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("전체 진도율", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThemeManager.subTextColor)),
                          Text("${(progress * 100).toStringAsFixed(1)}%", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: primaryColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(primaryColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildStatRow("학습한 단어", "$_learnedWordsCount / $_totalWordsCount"),
                      _buildStatRow("추천 레벨", "TOEIC $_recommendedLevel"),
                      _buildStatRow("오답 노트", "$_wrongAnswersCount 단어"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader("시스템 설정"),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: ThemeManager.isDarkMode,
                        onChanged: (val) async {
                          await ThemeManager.toggleDarkMode(val);
                          if (mounted) setState(() {});
                        },
                        title: Text("다크 모드", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ThemeManager.textColor)),
                        secondary: Icon(Icons.dark_mode_rounded, color: primaryColor),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader("계절 테마 설정"),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSeasonIcon("자동", Season.auto, Icons.auto_mode_rounded, currentSelected == Season.auto),
                      _buildSeasonIcon("봄", Season.spring, Icons.wb_sunny_outlined, currentSelected == Season.spring),
                      _buildSeasonIcon("여름", Season.summer, Icons.beach_access_rounded, currentSelected == Season.summer),
                      _buildSeasonIcon("가을", Season.autumn, Icons.eco_outlined, currentSelected == Season.autumn),
                      _buildSeasonIcon("겨울", Season.winter, Icons.ac_unit_rounded, currentSelected == Season.winter),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader("데이터 관리"),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _buildActionTile("진단 결과 초기화", Icons.refresh_rounded, Colors.blueGrey, _resetLevelTest),
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), indent: 24, endIndent: 24),
                      _buildActionTile("모든 기록 삭제", Icons.delete_forever_rounded, Colors.redAccent, _resetAllRecords),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ThemeManager.textColor)),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: ThemeManager.subTextColor, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: ThemeManager.textColor, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildSeasonIcon(String label, Season season, IconData icon, bool isSelected) {
    final isActual = (ThemeManager.effectiveSeason == season && ThemeManager.selectedSeason == Season.auto);
    final color = Theme.of(context).colorScheme.primary;
    final isDark = ThemeManager.isDarkMode;

    return GestureDetector(
      onTap: () async { await ThemeManager.updateSeason(season); if (mounted) setState(() {}); },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? color : (isActual ? color.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white)),
              shape: BoxShape.circle,
              border: isActual && !isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(
              icon, 
              color: isSelected ? Colors.white : (isActual ? color : (isDark ? Colors.white38 : Colors.grey[300])), 
              size: 22
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.bold, 
              color: isSelected || isActual ? color : ThemeManager.subTextColor
            )
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = ThemeManager.isDarkMode;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 15, 
          color: ThemeManager.textColor
        )
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white24 : Colors.grey[400]),
    );
  }
}
