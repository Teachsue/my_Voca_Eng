import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // 요일 포맷팅을 위해 추가
import 'study_record_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final AnimationController _animationController;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    setState(() {
      _isControllerInitialized = true;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 총 공부한 일수 계산
    final totalStudiedDays = StudyRecordService.getStudiedDays().length;
    final isTodayDone = StudyRecordService.isStudied(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "나의 공부 기록 📅",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,

              // 요일 부분이 잘리지 않도록 높이 넉넉하게 유지
              daysOfWeekHeight: 30,

              // ★ 변경 1: 기존의 daysOfWeekStyle은 지웠습니다! (전체 빨간색 방지)
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                headerMargin: EdgeInsets.only(bottom: 15),
              ),

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              eventLoader: (day) {
                if (StudyRecordService.isStudied(day)) {
                  return ['Studied'];
                }
                return [];
              },

              calendarBuilders: CalendarBuilders(
                // ★ 변경 2: 요일 헤더 커스텀 (토요일 파랑, 일요일 빨강 지정)
                dowBuilder: (context, day) {
                  if (day.weekday == DateTime.sunday) {
                    return const Center(
                      child: Text(
                        '일',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  } else if (day.weekday == DateTime.saturday) {
                    return const Center(
                      child: Text(
                        '토',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  // 평일 (월~금)
                  final text = DateFormat.E('ko_KR').format(day);
                  return Center(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                },

                markerBuilder: (context, date, events) {
                  if (!_isControllerInitialized || events.isEmpty) return null;

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.elasticOut,
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        ),
                        Text(
                          "${date.day}",
                          style: const TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },

                // ★ 변경 3: 실제 날짜 숫자들 커스텀 (숫자도 주말 색상 통일)
                defaultBuilder: (context, day, focusedDay) {
                  if (day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  } else if (day.weekday == DateTime.saturday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    );
                  }
                  return null;
                },
              ),

              calendarStyle: const CalendarStyle(
                markersMaxCount: 0,
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // [총 공부 일수 및 성취 배너 영역]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "지금까지",
                          style: TextStyle(color: Colors.indigo, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "총 $totalStudiedDays일 공부했어요!",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  isTodayDone ? _buildSuccessBanner() : _buildPendingBanner(),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 30),
          SizedBox(width: 15),
          Text(
            "오늘도 목표 달성 완료! ✨",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.orangeAccent,
            size: 28,
          ),
          SizedBox(width: 15),
          Text(
            "퀴즈를 풀고\n오늘의 별을 획득하세요!",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
