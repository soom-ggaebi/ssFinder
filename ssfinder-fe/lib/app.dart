import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:sumsumfinder/screens/splash_screen.dart'; // 스플래시 스크린 import 추가

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
      home: const SplashScreen(), // HomePage 대신 SplashScreen을 초기 화면으로 설정
    );
  }
}
