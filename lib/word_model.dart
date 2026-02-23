import 'package:hive/hive.dart';

part 'word_model.g.dart';

@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  final String category;

  @HiveField(1)
  final String level;

  @HiveField(2)
  final String spelling;

  @HiveField(3)
  final String meaning;

  @HiveField(4)
  final String type; // 'Word' or 'Quiz'

  @HiveField(5)
  final String? correctAnswer;

  @HiveField(6)
  final List<String>? options;

  @HiveField(7)
  final String? explanation;

  @HiveField(8)
  final DateTime nextReviewDate;

  // ★ 추가: 북마크 여부 (기본값은 false)
  @HiveField(9)
  bool isScrap;

  Word({
    required this.category,
    required this.level,
    required this.spelling,
    required this.meaning,
    this.type = 'Word',
    this.correctAnswer,
    this.options,
    this.explanation,
    required this.nextReviewDate,
    this.isScrap = false, // 기본값 설정
  });
}
