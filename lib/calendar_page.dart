import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'study_record_service.dart';
import 'theme_manager.dart';
import 'seasonal_background.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalStudiedDays = StudyRecordService.getStudiedDays().length;
    final isTodayDone = StudyRecordService.isStudied(DateTime.now());
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = ThemeManager.textColor;
    final subTextColor = ThemeManager.subTextColor;
    final isDark = ThemeManager.isDarkMode;

    return SeasonalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("공부 기록 📅", style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  daysOfWeekHeight: 30,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    headerMargin: const EdgeInsets.only(bottom: 15),
                    leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                    rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) => StudyRecordService.isStudied(day) ? ['Studied'] : [],
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.E('ko_KR').format(day);
                      Color color = textColor.withOpacity(0.7);
                      if (day.weekday == DateTime.sunday) color = Colors.redAccent;
                      if (day.weekday == DateTime.saturday) color = Colors.blueAccent;
                      return Center(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)));
                    },
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      return Center(
                        child: ScaleTransition(
                          scale: CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      Color? color;
                      if (day.weekday == DateTime.sunday) color = Colors.redAccent.withOpacity(0.8);
                      if (day.weekday == DateTime.saturday) color = Colors.blueAccent.withOpacity(0.8);
                      if (color != null) {
                        return Center(child: Text('${day.day}', style: TextStyle(color: color)));
                      }
                      return null;
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 0,
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(color: primaryColor.withOpacity(0.15), shape: BoxShape.circle),
                    todayTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    defaultTextStyle: TextStyle(color: textColor),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent), // 기본 주말 색상
                    holidayTextStyle: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Text("지금까지", style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("총 $totalStudiedDays일 공부했어요!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              isTodayDone ? _buildSuccessBanner(primaryColor, textColor, isDark) : _buildPendingBanner(textColor, subTextColor, isDark),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(Color color, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Text("오늘도 목표 달성 완료! ✨", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildPendingBanner(Color textColor, Color subTextColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6), 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.orangeAccent, size: 26),
          const SizedBox(width: 12),
          Text("오늘의 퀴즈를 풀고\n별을 획득하세요!", textAlign: TextAlign.center, style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
