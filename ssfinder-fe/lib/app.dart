import 'package:flutter/material.dart';
import 'screens/home_page.dart'; // 경로는 실제 프로젝트에 맞게 조정하세요

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF3D3D3D);

    return MaterialApp(
      title: 'Sumsum Finder',
      theme: ThemeData(
        fontFamily: 'GmarketSans',

        // 모든 텍스트에 기본 폰트 크기 12 적용
        textTheme: TextTheme(
          // 모든 텍스트 스타일에 fontSize: 12 적용
          displayLarge: TextStyle(fontSize: 12, color: textColor),
          displayMedium: TextStyle(fontSize: 12, color: textColor),
          displaySmall: TextStyle(fontSize: 12, color: textColor),
          headlineLarge: TextStyle(fontSize: 12, color: textColor),
          headlineMedium: TextStyle(fontSize: 12, color: textColor),
          headlineSmall: TextStyle(fontSize: 12, color: textColor),
          titleLarge: TextStyle(fontSize: 12, color: textColor),
          titleMedium: TextStyle(fontSize: 14, color: textColor),
          titleSmall: TextStyle(fontSize: 12, color: textColor),
          bodyLarge: TextStyle(fontSize: 12, color: textColor),
          bodyMedium: TextStyle(fontSize: 12, color: textColor),
          bodySmall: TextStyle(fontSize: 12, color: textColor),
          labelLarge: TextStyle(fontSize: 12, color: textColor),
          labelMedium: TextStyle(fontSize: 12, color: textColor),
          labelSmall: TextStyle(fontSize: 10, color: textColor),
        ),

        // 앱바 텍스트에도 적용
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 12,
            color: textColor,
          ),
        ),

        // 기타 설정
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const HomePage(),
    );
  }
}
