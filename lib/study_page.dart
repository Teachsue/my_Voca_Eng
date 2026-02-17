import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';

class StudyPage extends StatefulWidget {
  final String category;
  final String level;

  const StudyPage({super.key, required this.category, required this.level});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  // 전체 데이터와 현재 페이지 데이터를 분리합니다.
  List<Word> _allWords = []; // 불러온 전체 단어
  List<Word> _currentWords = []; // 현재 페이지에 보여줄 단어

  int _currentPage = 1; // 현재 페이지 번호
  final int _itemsPerPage = 20; // 페이지당 단어 수

  // ★ 1. 스크롤 제어를 위한 컨트롤러 선언
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ★ 2. 화면이 종료될 때 컨트롤러 해제 (메모리 관리)
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    final box = Hive.box<Word>('words');

    // 1. 조건에 맞는 모든 단어를 가져옵니다.
    _allWords = box.values.where((word) {
      return word.category == widget.category &&
          word.level == widget.level &&
          word.type == 'Word';
    }).toList();

    // 2. 첫 페이지 데이터를 설정합니다.
    _updatePageData();
  }

  // 현재 페이지에 맞는 데이터를 잘라내는 함수
  void _updatePageData() {
    if (_allWords.isEmpty) {
      _currentWords = [];
      return;
    }

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = min(startIndex + _itemsPerPage, _allWords.length);

    setState(() {
      _currentWords = _allWords.sublist(startIndex, endIndex);
    });
  }

  // 페이지 변경 함수
  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
      _updatePageData();
    });

    // ★ 4. 페이지가 바뀌면 스크롤을 맨 위(0)로 즉시 이동
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_allWords.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("${widget.category} ${widget.level} 단어장"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. 상단 정보 (전체 개수 표시)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              "총 ${_allWords.length}개 단어 중 ${_currentWords.length}개 표시",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),

          // 2. 단어 리스트
          Expanded(
            child: _currentWords.isEmpty
                ? const Center(child: Text("등록된 단어가 없습니다."))
                : ListView.separated(
                    // ★ 3. 리스트뷰에 컨트롤러 연결
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _currentWords.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final word = _currentWords[index];
                      int globalIndex =
                          ((_currentPage - 1) * _itemsPerPage) + index + 1;

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
                            // 번호
                            Container(
                              width: 35,
                              height: 35,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$globalIndex",
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // 단어와 뜻
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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

          // 3. 하단 페이지네이션 컨트롤러
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이전 페이지 버튼
                ElevatedButton(
                  onPressed: _currentPage > 1
                      ? () => _changePage(_currentPage - 1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.chevron_left),
                ),

                // 페이지 번호 표시
                Text(
                  "$_currentPage / $totalPages",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 다음 페이지 버튼
                ElevatedButton(
                  onPressed: _currentPage < totalPages
                      ? () => _changePage(_currentPage + 1)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
