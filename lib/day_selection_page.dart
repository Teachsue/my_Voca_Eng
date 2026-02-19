import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';
import 'study_page.dart';

class DaySelectionPage extends StatefulWidget {
  final String category;
  final String level;

  const DaySelectionPage({
    super.key,
    required this.category,
    required this.level,
  });

  @override
  State<DaySelectionPage> createState() => _DaySelectionPageState();
}

class _DaySelectionPageState extends State<DaySelectionPage> {
  final int _wordsPerDay = 20;
  List<List<Word>> _dayChunks = [];

  @override
  void initState() {
    super.initState();
    _loadAndChunkDays();
  }

  void _loadAndChunkDays() {
    final box = Hive.box<Word>('words');

    List<Word> filteredList = box.values.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Word';
    }).toList();

    final Map<String, Word> uniqueMap = {};
    for (var w in filteredList) {
      uniqueMap.putIfAbsent(w.spelling.trim().toLowerCase(), () => w);
    }

    List<Word> finalPool = uniqueMap.values.toList();
    finalPool.sort(
      (a, b) => a.spelling.toLowerCase().compareTo(b.spelling.toLowerCase()),
    );

    _dayChunks = [];
    for (var i = 0; i < finalPool.length; i += _wordsPerDay) {
      int end = (i + _wordsPerDay < finalPool.length)
          ? i + _wordsPerDay
          : finalPool.length;
      _dayChunks.add(finalPool.sublist(i, end));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_dayChunks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("${widget.category} ${widget.level}")),
        body: const Center(child: Text("학습할 단어가 없습니다.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${widget.category} ${widget.level} 학습하기"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.0,
        ),
        itemCount: _dayChunks.length,
        itemBuilder: (context, index) {
          final int dayNumber = index + 1;
          final int wordCount = _dayChunks[index].length;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyPage(
                    category: widget.category,
                    level: widget.level,
                    // ★ 변경: 전체 청크와 현재 클릭한 인덱스를 전달
                    allDayChunks: _dayChunks,
                    initialDayIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "DAY",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.indigo[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$dayNumber",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$wordCount 단어",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
