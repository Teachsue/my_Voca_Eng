import 'package:hive/hive.dart';

part 'word_model.g.dart';

@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  String level;

  @HiveField(2)
  String spelling;

  @HiveField(3)
  String meaning;

  @HiveField(4)
  String type; // 'Word' or 'Quiz'

  @HiveField(5)
  String? correctAnswer;

  @HiveField(6)
  List<String>? options;

  @HiveField(7)
  String? explanation;

  @HiveField(8)
  DateTime nextReviewDate;

  @HiveField(9)
  bool isScrap;

  // ★ 수정: 널 허용(int?)으로 변경하여 구버전 데이터 로드 시 캐스팅 에러 방지
  @HiveField(10)
  int? reviewStep;

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
    this.isScrap = false,
    this.reviewStep = 0,
  });

  // 단계 접근 시 null이면 0 반환
  int get currentStep => reviewStep ?? 0;

  void updateReviewStep(bool isCorrect) {
    int nextStep = currentStep;
    if (isCorrect) {
      nextStep++;
    } else {
      nextStep = 0;
    }
    reviewStep = nextStep;

    int daysToAdd = 0;
    switch (nextStep) {
      case 0: daysToAdd = 0; break;
      case 1: daysToAdd = 1; break;
      case 2: daysToAdd = 2; break;
      case 3: daysToAdd = 4; break;
      case 4: daysToAdd = 7; break;
      case 5: daysToAdd = 15; break;
      case 6: daysToAdd = 30; break;
      default: daysToAdd = 30; break;
    }

    final now = DateTime.now();
    nextReviewDate = DateTime(now.year, now.month, now.day).add(Duration(days: daysToAdd));
  }
}
