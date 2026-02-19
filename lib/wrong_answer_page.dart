import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';

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

  // 낱개 삭제 함수
  void _deleteWord(String key) {
    _wrongBox.delete(key);
    setState(() {}); // 화면 갱신
  }

  // ★ 추가: 전체 삭제 확인 다이얼로그 함수
  void _showDeleteAllDialog() {
    if (_wrongBox.isEmpty) return; // 비어있으면 실행 안 함

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("오답노트 초기화"),
        content: const Text("저장된 모든 오답을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _wrongBox.clear(); // Hive 박스 전체 비우기
              if (mounted) {
                setState(() {}); // 화면 갱신
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("오답노트가 모두 비워졌습니다.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("전체 삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 박스에 있는 모든 단어를 가져옵니다.
    final wrongWords = _wrongBox.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("오답노트 📝"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // ★ 추가: AppBar 우측 액션 버튼
        actions: [
          if (wrongWords.isNotEmpty) // 오답이 있을 때만 휴지통 아이콘 표시
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: _showDeleteAllDialog,
              tooltip: "전체 삭제",
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: wrongWords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green[200],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "틀린 문제가 없어요!\n완벽합니다! 👍",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: wrongWords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final word = wrongWords[index];

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.spelling,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 5),
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
                      // 삭제 버튼 (휴지통)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _deleteWord(word.spelling);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("암기 완료! 오답노트에서 삭제했습니다."),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
