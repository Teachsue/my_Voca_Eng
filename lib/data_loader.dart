import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'word_model.dart';

class DataLoader {
  // ★ 에빙하우스 필드 추가로 인해 데이터 구조가 변경되었으므로 버전을 올립니다.
  static const int DATA_VERSION = 2;

  static Future<void> loadData() async {
    final wordBox = Hive.box<Word>('words');
    final cacheBox = Hive.box('cache'); 

    int savedVersion = cacheBox.get('data_version', defaultValue: 0);

    // 데이터가 비었거나 버전이 낮으면 로드 진행
    if (wordBox.isEmpty || savedVersion < DATA_VERSION) {
      print("데이터 초기화 및 로드 시작 (버전: $DATA_VERSION)");

      await wordBox.clear();

      // 파일들로부터 데이터를 읽어서 리스트로 준비
      Map<String, Word> allWordsMap = {};
      
      await _collectFromFile(allWordsMap, 'assets/json/word_data.json');
      await _collectFromFile(allWordsMap, 'assets/json/quiz_data.json');

      // ★ 핵심 최적화: 하나씩 add 하는 대신 putAll로 한꺼번에 저장
      if (allWordsMap.isNotEmpty) {
        await wordBox.putAll(allWordsMap);
      }

      await cacheBox.put('data_version', DATA_VERSION);
      print("데이터 로드 완료! 총 ${wordBox.length}개 저장됨.");
    } else {
      print("기존 데이터 사용 (버전: $savedVersion)");
    }
  }

  // 데이터를 맵에 수집하는 함수 (중복 제거 포함)
  static Future<void> _collectFromFile(Map<String, Word> map, String filePath) async {
    try {
      final String jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var item in jsonList) {
        String spelling = item['spelling'] ?? '';
        String type = item['type'] ?? 'Word';
        
        // 고유 키 생성 (spelling + type)
        String key = "${type}_$spelling";

        final word = Word(
          category: item['category'] ?? 'Etc',
          level: item['level'] ?? 'Basic',
          spelling: spelling,
          meaning: item['meaning'] ?? '',
          type: type,
          correctAnswer: item['correctAnswer'],
          options: item['options'] != null
              ? List<String>.from(item['options'])
              : null,
          explanation: item['explanation'],
          nextReviewDate: today,
          reviewStep: 0,
        );
        map[key] = word;
      }
      print("-> $filePath 데이터 수집 성공 (${jsonList.length}개)");
    } catch (e) {
      print("-> $filePath 데이터 수집 실패: $e");
    }
  }
}
