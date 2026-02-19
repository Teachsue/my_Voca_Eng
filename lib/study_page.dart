import 'package:flutter/material.dart';
import 'word_model.dart';
import 'quiz_page.dart';

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

  @override
  void initState() {
    super.initState();
    _currentDayIndex = widget.initialDayIndex;
    _pageController = PageController(initialPage: _currentDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★ 기기의 하단 안전 여백(갤럭시 내브바, 아이폰 홈바 등)의 높이를 가져옵니다.
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "${widget.category} ${widget.level} - DAY ${_currentDayIndex + 1}",
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentDayIndex = index;
          });
        },
        itemCount: widget.allDayChunks.length,
        itemBuilder: (context, dayIndex) {
          final dayWords = widget.allDayChunks[dayIndex];
          final int dayNumber = dayIndex + 1;

          return Column(
            children: [
              // 단어장 리스트 영역
              Expanded(
                child: dayWords.isEmpty
                    ? const Center(child: Text("등록된 단어가 없습니다."))
                    : ListView.separated(
                        key: ValueKey("list_$dayIndex"),
                        padding: const EdgeInsets.all(20),
                        itemCount: dayWords.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final word = dayWords[index];
                          int wordNumber = index + 1;

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 35,
                                  height: 35,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "$wordNumber",
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word.spelling,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        word.meaning,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[700],
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

              // ★ 하단 고정 시험 버튼 (갤럭시 내비게이션 바 완벽 대응)
              Container(
                // 기본 패딩 15에 기기별 하단 내비게이션 바 높이(bottomPadding)를 더해줍니다.
                padding: EdgeInsets.fromLTRB(20, 15, 20, 15 + bottomPadding),
                decoration: BoxDecoration(
                  color: Colors.white, // 배경색이 내비게이션 바 뒤로도 예쁘게 확장됩니다.
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 60, // 버튼 자체의 시원한 높이 유지
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(
                            category: widget.category,
                            level: widget.level,
                            questionCount: 0,
                            dayNumber: dayNumber,
                            dayWords: dayWords,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_document, size: 24),
                    label: Text(
                      "DAY $dayNumber 시험 보기",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
