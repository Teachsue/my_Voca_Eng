import 'dart:math';
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
  late List<List<Word>> _shuffledDayChunks;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = widget.initialDayIndex;
    _pageController = PageController(initialPage: _currentDayIndex);

    // ★ 랜덤 셔플 로직 유지
    _shuffledDayChunks = [];
    for (var chunk in widget.allDayChunks) {
      List<Word> shuffledChunk = List<Word>.from(chunk);
      shuffledChunk.shuffle();
      _shuffledDayChunks.add(shuffledChunk);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        itemCount: _shuffledDayChunks.length,
        itemBuilder: (context, dayIndex) {
          final dayWords = _shuffledDayChunks[dayIndex];
          final int dayNumber = dayIndex + 1;

          return Column(
            children: [
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

                          // ★ StatefulBuilder를 사용하여 아이콘 상태만 부분 갱신
                          return StatefulBuilder(
                            builder: (context, setStateItem) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
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
                                    // ★ 북마크(스크랩) 버튼 추가
                                    IconButton(
                                      onPressed: () {
                                        setStateItem(() {
                                          word.isScrap = !word.isScrap;
                                          word.save(); // DB 저장
                                        });
                                      },
                                      icon: Icon(
                                        word.isScrap
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: word.isScrap
                                            ? Colors.amber
                                            : Colors.grey[400],
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 15, 20, 15 + bottomPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  height: 60,
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
