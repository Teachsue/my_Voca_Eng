import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'word_model.dart';

class ScrapPage extends StatefulWidget {
  const ScrapPage({super.key});

  @override
  State<ScrapPage> createState() => _ScrapPageState();
}

class _ScrapPageState extends State<ScrapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("나만의 단어장 ⭐"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // Hive 데이터를 실시간으로 감시하여 화면을 업데이트합니다.
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Word>('words').listenable(),
        builder: (context, Box<Word> box, _) {
          // isScrap이 true인 단어만 골라내기
          final scrapWords = box.values.where((word) => word.isScrap).toList();

          if (scrapWords.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "아직 스크랩한 단어가 없어요.\n학습 중에 별표를 눌러 저장해보세요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: scrapWords.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final word = scrapWords[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          const SizedBox(height: 5),
                          Text(
                            "${word.category} • ${word.level}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo[200],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 스크랩 해제 버튼
                    IconButton(
                      onPressed: () {
                        // DB 업데이트 (즉시 반영됨)
                        word.isScrap = false;
                        word.save();
                      },
                      icon: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
