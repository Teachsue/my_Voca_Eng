import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'quiz_page.dart';

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
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 24),
            const Text("오답노트 초기화", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 12),
            const Text(
              "저장된 모든 오답을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
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
                    onPressed: () async {
                      await _wrongBox.clear();
                      if (mounted) {
                        setState(() {});
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("오답노트가 초기화되었습니다. ✨"), behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("전체 삭제", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("오답노트 📝", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (wrongWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: _showDeleteAllDialog,
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: wrongWords.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => QuizPage(dayWords: wrongWords, isWrongAnswerQuiz: true)));
              },
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text("오답 퀴즈 시작", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    child: Icon(Icons.check_circle_rounded, size: 80, color: Colors.green[300]),
                  ),
                  const SizedBox(height: 24),
                  const Text("틀린 문제가 없어요!\n완벽합니다! 👍", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600, height: 1.5)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              itemCount: wrongWords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final word = wrongWords[index];
                
                // 등급에 따른 색상 정의
                Color levelColor;
                String levelLabel = word.level;
                
                if (word.level.contains('900')) {
                  levelColor = Colors.purple;
                  levelLabel = "TOEIC $levelLabel";
                } else if (word.level.contains('700')) {
                  levelColor = Colors.indigo;
                  levelLabel = "TOEIC $levelLabel";
                } else if (word.level.contains('500')) {
                  levelColor = Colors.teal;
                  levelLabel = "TOEIC $levelLabel";
                } else {
                  levelColor = Colors.orange;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 순서 번호 영역 (통일된 디자인)
                          Container(
                            width: 60,
                            color: Colors.indigo.withOpacity(0.03),
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 콘텐츠 영역
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          word.spelling,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      // 등급 배지
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: levelColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          levelLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: levelColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    word.meaning,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 삭제 버튼
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _deleteWord(word.spelling);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("오답노트에서 삭제했습니다."),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.grey[300],
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
