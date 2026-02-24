# 📚 포켓보카 (Pocket Voca)

**나만의 맞춤형 영단어 학습 애플리케이션** 🚀
매일 꾸준하게, 내 실력에 딱 맞게 영단어를 정복해 보세요! 

플러터(Flutter)와 로컬 NoSQL 데이터베이스(Hive)를 활용하여 오프라인에서도 빠르고 쾌적하게 동작하도록 설계된 모바일 영단어장 앱입니다.

---

## ✨ 핵심 기능 (Key Features)

### 🎯 1. 실력 진단 테스트 및 맞춤 레벨 추천
* 15개의 진단 퀴즈를 통해 사용자의 현재 단어 수준을 파악합니다.
* 결과에 따라 TOEIC (500/700/900+) 알맞은 학습 레벨을 자동으로 추천해 줍니다.

### 🧠 2. 스마트 학습 시스템 (에빙하우스 망각곡선)
* **에빙하우스 망각곡선(Spaced Repetition) 알고리즘**을 도입하여 과학적인 복습 주기를 자동으로 계산합니다.
* 학습 결과에 따라 단어별 복습 단계(1~6단계)를 관리하며, 맞힐수록 복습 주기가 늘어납니다 (1일 → 2일 → 4일 → 7일 → 15일 → 30일).
* 틀린 단어는 즉시 학습 단계가 초기화되어 완벽하게 외울 때까지 반복 노출됩니다.

### 🔥 3. 오늘의 영단어 (Daily Study)
* 매일 10개의 단어를 추출하여 학습 목표로 제공합니다.
* 알고리즘에 따라 **복습이 필요한 단어를 최우선으로 배치**하고, 남은 자리를 새로운 단어로 채워 학습 효율을 극대화합니다.
* 10문제를 모두 맞혀야만 학습 완료(출석 도장)가 되는 스파르타식 시스템으로 꼼꼼한 암기를 유도합니다.

### 🧩 4. 쾌적한 퀴즈 및 학습 환경
* 단어 카드 형태의 깔끔한 UI로 스와이프하며 단어를 학습합니다.
* **영어-한글 및 한글-영어 무작위 퀴즈** 시스템을 제공하여 학습 효과를 높이며, 오답은 자동으로 분석되어 결과창에 상세히 표시됩니다.

### 📝 5. 오답 노트 및 나만의 단어장 (북마크)
* **오답 노트:** 퀴즈에서 틀린 단어들은 오답 노트 DB에 자동 저장되며, 오답들로만 구성된 **'오답 퀴즈'**를 통해 집중 복습이 가능합니다.
* **나만의 단어장:** 학습 중 별표(⭐) 아이콘을 눌러 내가 외우고 싶은 단어만 따로 스크랩하여 모아볼 수 있습니다.

### 📊 6. 학습 통계 및 캘린더 연동
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
**에빙하우스 망각곡선 엔진:** 사용자별 학습 데이터를 기반으로 망각 시점을 예측하고 복습 단어를 우선 노출하는 스마트 알고리즘을 구현했습니다. (1, 2, 4, 7, 15, 30일 주기 적용)

**대용량 데이터 로딩 최적화 (Batch Insert):** 1,900여 개의 대량 데이터를 초기화할 때 발생하던 메인 스레드 멈춤 현상을 해결하기 위해, 하나씩 저장하던 방식에서 `putAll`을 활용한 일괄 저장 방식으로 로직을 획기적으로 개선했습니다.

**반응형 UI/UX 및 네비게이션:** 다양한 기기 해상도에 대응하기 위해 `SafeArea`와 `SingleChildScrollView`를 전면 적용했으며, 어디서든 홈으로 즉시 이동할 수 있는 홈 버튼과 학습 이어하기 배너를 통해 사용자 편의성을 극대화했습니다.

**데이터 무결성 및 자체 복구(Self-healing):** 안드로이드 자동 백업으로 인한 DB 충돌 시, 예외 처리를 통해 데이터를 안전하게 초기화하고 재생성하는 방어 로직을 구축했습니다.