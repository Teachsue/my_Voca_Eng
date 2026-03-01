import 'package:flutter/material.dart';
import 'theme_manager.dart';

class SeasonalBackground extends StatelessWidget {
  final Widget child;

  const SeasonalBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = ThemeManager.bgGradient;
    final icon = ThemeManager.seasonIconData;
    final primaryColor = ThemeManager.pointColor;
    final bool isDark = ThemeManager.isDarkMode;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        // ★ clipBehavior를 하드엣지로 변경하여 화면 밖 노란색 경고선 방지
        clipBehavior: Clip.hardEdge, 
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Icon(
              icon,
              size: 300,
              color: isDark 
                  ? Colors.white.withOpacity(0.03) 
                  : primaryColor.withOpacity(0.07),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
