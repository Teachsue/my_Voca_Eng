# 📚 포켓보카 (Pocket Voca)

**나만의 맞춤형 영단어 학습 애플리케이션** 🚀
매일 꾸준하게, 내 실력에 딱 맞게 영단어를 정복해 보세요! 

플러터(Flutter)와 로컬 NoSQL 데이터베이스(Hive)를 활용하여 오프라인에서도 빠르고 쾌적하게 동작하도록 설계된 모바일 영단어장 앱입니다.

---

## ✨ 핵심 기능 (Key Features)

### 🎯 1. 실력 진단 테스트 및 맞춤 레벨 추천
* 15개의 진단 퀴즈를 통해 사용자의 현재 단어 수준을 파악합니다.
* 결과에 따라 TOEIC (500/700/900+) 알맞은 학습 레벨을 자동으로 추천해 줍니다.

### 🔥 2. 오늘의 영단어 (Daily Study)
* 매일 랜덤하게 10개의 단어를 추출하여 오늘의 학습 목표로 제공합니다.
* 학습을 완료하면 메인 화면의 배너 UI가 직관적으로 변경되어 성취감을 제공합니다.

### 🧩 3. 쾌적한 퀴즈 및 학습 환경
* 단어 카드 형태의 깔끔한 UI로 스와이프하며 단어를 학습합니다.
* **영어-한글 및 한글-영어 무작위 퀴즈** 시스템을 제공하여 학습 효과를 극대화하며, 틀린 문제는 자동으로 분류됩니다.

### 📝 4. 오답 노트 및 나만의 단어장 (북마크)
* **오답 노트:** 퀴즈에서 틀린 단어들은 오답 노트 DB에 자동 저장되어 집중적으로 복습할 수 있습니다.
* **나만의 단어장:** 학습 중 별표(⭐) 아이콘을 눌러 내가 외우고 싶은 단어만 따로 스크랩하여 모아볼 수 있습니다.

### 📊 5. 학습 통계 및 캘린더 연동
* 캘린더를 통해 매일매일의 출석 및 학습 완료 현황을 한눈에 파악합니다.
* 전체 단어 대비 학습 완료 단어(진도율)와 복습이 필요한 단어 수를 프로그레스 바(Progress Bar)로 시각화하여 보여줍니다.
* 레벨 테스트 초기화 및 전체 데이터 완전 초기화 기능을 통해 앱을 유연하게 관리할 수 있습니다.

---

## 🛠 기술 스택 (Tech Stack)

* **Framework:** Flutter (Dart)
* **Local Database:** Hive (초고속 경량 NoSQL 로컬 DB)
* **Architecture / State Management:** Stateful/Stateless Widgets, `ValueListenableBuilder` (Hive 실시간 상태 감시)
* **Packages:** `hive`, `hive_flutter`, `intl`, `build_runner`

---

## 📱 스크린샷 (Screenshots)

<p align="center">
  <img src="assets/screenshots/main.png" width="24%">
  <img src="assets/screenshots/level_test.png" width="24%">
  <img src="assets/screenshots/study.png" width="24%">
  <img src="assets/screenshots/todays_words.png" width="24%">
</p>
<p align="center">
  <img src="assets/screenshots/quiz.png" width="24%">
  <img src="assets/screenshots/scrap.png" width="24%">
  <img src="assets/screenshots/wrong_note.png" width="24%">
  <img src="assets/screenshots/statistics.png" width="24%">
</p>

## ⚙️ 설치 및 실행 방법 (Getting Started)

아래 명령어를 터미널에 순서대로 입력하여 프로젝트를 설치하고 실행할 수 있습니다.

```bash
# 1. 저장소를 클론합니다.
git clone [https://github.com/본인아이디/my_vocab_app.git](https://github.com/본인아이디/my_vocab_app.git)

# 2. 프로젝트 폴더로 이동하여 패키지를 설치합니다.
cd my_vocab_app
flutter pub get

# 3. Hive TypeAdapter 등 데이터 모델 자동 생성 코드를 빌드합니다.
dart run build_runner build --delete-conflicting-outputs

# 4. 앱을 실행합니다. (에뮬레이터 또는 실제 기기 연결 필요)
flutter run

💡 주요 개발 포인트 (Troubleshooting & Optimization)
모던하고 직관적인 UI/UX: 모서리가 둥근 카드형 디자인과 부드러운 그림자(BoxShadow), 그라데이션 배너를 활용하여 사용자 친화적인 레이아웃을 구성했습니다.

데이터 무결성 및 자체 복구(Self-healing) 적용: 안드로이드 자동 백업(Auto Backup) 기능으로 인한 구버전 DB 캐시 충돌 현상을 방지하기 위해, main.dart 초기화 과정에 try-catch 문을 도입하여 DB 충돌 시 데이터를 안전하게 재생성하는 방어 로직을 구축했습니다.

효율적인 상태 관리: 상태 관리의 복잡도를 낮추기 위해 Hive의 listenable()을 활용하여, 단어 스크랩 등의 데이터 변경이 즉각적으로 UI에 반영되도록 최적화했습니다.