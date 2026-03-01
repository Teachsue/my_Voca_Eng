import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum Season { spring, summer, autumn, winter, auto }

class ThemeManager {
  static const String _themeKey = 'user_selected_season';
  static const String _darkKey = 'is_dark_mode';
  
  static final ValueNotifier<Season> themeNotifier = ValueNotifier(Season.auto);
  static final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

  static Future<void> init() async {
    final cacheBox = Hive.box('cache');
    final String? savedSeason = cacheBox.get(_themeKey);
    if (savedSeason != null) {
      themeNotifier.value = Season.values.firstWhere((e) => e.toString() == savedSeason, orElse: () => Season.auto);
    }
    isDarkModeNotifier.value = cacheBox.get(_darkKey, defaultValue: false);
  }

  static Season get selectedSeason => themeNotifier.value;
  static bool get isDarkMode => isDarkModeNotifier.value;

  static Future<void> updateSeason(Season season) async {
    final cacheBox = Hive.box('cache');
    await cacheBox.put(_themeKey, season.toString());
    themeNotifier.value = season; 
  }

  static Future<void> toggleDarkMode(bool isDark) async {
    final cacheBox = Hive.box('cache');
    await cacheBox.put(_darkKey, isDark);
    isDarkModeNotifier.value = isDark;
  }

  static Season get systemSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  static Season get effectiveSeason => selectedSeason == Season.auto ? systemSeason : selectedSeason;

  // ★ 다크모드에서 더 부드럽게 보이는 포인트 컬러
  static Color get pointColor {
    if (isDarkMode) {
      switch (effectiveSeason) {
        case Season.spring: return const Color(0xFFFF85A1);
        case Season.summer: return const Color(0xFF4FC3F7);
        case Season.autumn: return const Color(0xFFFFB74D);
        case Season.winter: return const Color(0xFFAABDC1);
        default: return const Color(0xFF9FA8DA);
      }
    }
    switch (effectiveSeason) {
      case Season.spring: return const Color(0xFFFF6B81);
      case Season.summer: return const Color(0xFF0077B6);
      case Season.autumn: return const Color(0xFFBC6C25);
      case Season.winter: return const Color(0xFF607D8B);
      default: return const Color(0xFF5B86E5);
    }
  }

  // ★ 다크모드 대비 최적화 텍스트 컬러
  static Color get textColor => isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
  static Color get subTextColor => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static List<Color> get bannerGradient {
    if (isDarkMode) return [const Color(0xFF334155), const Color(0xFF1E293B)];
    switch (effectiveSeason) {
      case Season.spring: return [const Color(0xFFFFB7C5), const Color(0xFFF08080)];
      case Season.summer: return [const Color(0xFF4FC3F7), const Color(0xFF1976D2)];
      case Season.autumn: return [const Color(0xFFFBC02D), const Color(0xFFE64A19)];
      case Season.winter: return [const Color(0xFF90A4AE), const Color(0xFF455A64)];
      default: return [const Color(0xFF5B86E5), const Color(0xFF36D1DC)];
    }
  }

  static List<Color> get bgGradient {
    if (isDarkMode) return [const Color(0xFF0F172A), const Color(0xFF020617)]; // 더 깊고 차분한 다크 네이비
    switch (effectiveSeason) {
      case Season.spring: return [const Color(0xFFFFF0F5), const Color(0xFFFFFFFF)];
      case Season.summer: return [const Color(0xFFE0F7FA), const Color(0xFFFFFFFF)];
      case Season.autumn: return [const Color(0xFFFFF3E0), const Color(0xFFFFFFFF)];
      case Season.winter: return [const Color(0xFFF1F4F8), const Color(0xFFFFFFFF)];
      default: return [const Color(0xFFF8FAFC), const Color(0xFFFFFFFF)];
    }
  }

  static IconData get seasonIconData {
    switch (effectiveSeason) {
      case Season.spring: return Icons.local_florist_rounded;
      case Season.summer: return Icons.wb_sunny_rounded;
      case Season.autumn: return Icons.eco_rounded;
      case Season.winter: return Icons.ac_unit_rounded;
      default: return Icons.auto_awesome_rounded;
    }
  }

  static String get seasonIcon {
    switch (effectiveSeason) {
      case Season.spring: return "🌸";
      case Season.summer: return "🌊";
      case Season.autumn: return "🍂";
      case Season.winter: return "❄️";
      default: return "✨";
    }
  }

  static ThemeData getThemeData() {
    final primary = pointColor;
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        brightness: brightness,
        surface: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      ),
      scaffoldBackgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.transparent,
      cardColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
