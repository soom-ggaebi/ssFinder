import 'package:flutter/material.dart';
import 'screens/home_page.dart'; // 경로는 실제 프로젝트에 맞게 조정하세요

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF3D3D3D);
    const Color backgroundColor = Color(0xFFF9FBFD);

    return MaterialApp(
      title: 'Sumsum Finder',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        scaffoldBackgroundColor: backgroundColor,

        textTheme: TextTheme(
          labelMedium: TextStyle(
            fontSize: 14,
            color: textColor,
            fontFamily: 'GmarketSans',
          ),
        ),

        // 앱바
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          titleTextStyle: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 12,
            color: textColor,
          ),
        ),

        // 하단바
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: backgroundColor,
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
