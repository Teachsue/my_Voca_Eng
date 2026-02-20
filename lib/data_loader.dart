import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'word_model.dart';

class DataLoader {
  // ★ 중요: 단어 데이터를 수정할 때마다 이 숫자를 1씩 올려주세요! (예: 1 -> 2 -> 3)
  static const int DATA_VERSION = 1;

  static Future<void> loadData() async {
    final wordBox = Hive.box<Word>('words');
    final cacheBox = Hive.box('cache'); // 버전 정보를 저장할 박스

    // 저장된 버전 확인 (없으면 0)
    int savedVersion = cacheBox.get('data_version', defaultValue: 0);

    // 1. 데이터가 아예 없거나(초기 설치), 버전이 올라갔으면(업데이트) 데이터를 다시 로드함
    if (wordBox.isEmpty || savedVersion < DATA_VERSION) {
      print("데이터 업데이트 필요 (구버전: $savedVersion -> 신버전: $DATA_VERSION)");

      // 기존 데이터 싹 비우기 (중복 방지)
      await wordBox.clear();
      print("기존 데이터 삭제 완료.");

      // 2. 단어 파일 읽기
      await _loadFromFile(wordBox, 'assets/json/word_data.json');

      // 3. 퀴즈 파일 읽기
      await _loadFromFile(wordBox, 'assets/json/quiz_data.json');

      // 4. 최신 버전 정보 저장
      await cacheBox.put('data_version', DATA_VERSION);
      print("모든 데이터 로딩 및 버전 업데이트 완료! 총 ${wordBox.length}개");
    } else {
      print("최신 데이터가 이미 있습니다. (버전: $savedVersion). 로딩 건너뜀.");
    }
  }

  // 내부 함수
  static Future<void> _loadFromFile(Box<Word> box, String filePath) async {
    try {
      final String jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      for (var item in jsonList) {
        final word = Word(
          category: item['category'] ?? 'Etc',
          level: item['level'] ?? 'Basic',
          spelling: item['spelling'] ?? '',
          meaning: item['meaning'] ?? '',
          type: item['type'] ?? 'Word',
          correctAnswer: item['correctAnswer'],
          options: item['options'] != null
              ? List<String>.from(item['options'])
              : null,
          explanation: item['explanation'],
          nextReviewDate: DateTime.now(),
        );
        await box.add(word);
      }
      print("-> $filePath 로딩 성공 (${jsonList.length}개)");
    } catch (e) {
      print("-> $filePath 로딩 실패: $e");
    }
  }
}
