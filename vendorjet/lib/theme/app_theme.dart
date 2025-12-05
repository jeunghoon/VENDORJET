import 'package:flutter/material.dart';

// 앱 전반에 사용할 파스텔톤 색상 정의 (주황, 파랑, 흰색)
// - 기본 Primary: 파스텔 주황
// - Secondary: 파스텔 하늘색
// - 배경/표면: 흰색 기반
class AppTheme {
  // 파스텔톤 주황/파랑 팔레트
  static const Color pastelOrange = Color(0xFFF08A4A); // 부드러운 주황을 조금 낮춘 톤
  static const Color pastelBlue = Color(0xFF5AA9E6); // 파스텔 하늘색
  static const Color lightBackground = Colors.white; // 흰색 배경

  // 라이트 테마 색 구성표
  static final ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: pastelOrange,
    onPrimary: Colors.white,
    secondary: pastelBlue,
    onSecondary: Colors.white,
    error: const Color(0xFFB00020),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF1F2937),
  );

  // 다크 테마 색 구성표 (선택): 대비를 조금 낮춘 파스텔 톤 유지
  static final ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFFF8F63),
    onPrimary: const Color(0xFF281A14),
    secondary: const Color(0xFF7EC3F0),
    onSecondary: const Color(0xFF0D2433),
    error: const Color(0xFFCF6679),
    onError: Colors.black,
    surface: const Color(0xFF111827),
    onSurface: Colors.white,
  );

  // Material3 기반 라이트/다크 테마
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: lightScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.surface,
        foregroundColor: lightScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: lightScheme.primary,
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: lightScheme.surface,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: lightScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: darkScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScheme.surface,
        foregroundColor: darkScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: darkScheme.primary,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: darkScheme.surface,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: darkScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
