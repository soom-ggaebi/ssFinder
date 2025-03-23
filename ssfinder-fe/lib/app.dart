import 'package:flutter/material.dart';
import 'screens/home_page.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sumsum Finder',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        scaffoldBackgroundColor: const Color(0xFFF9FBFD),
        // 앱바의 배경색을 0xFFF9FBFD로 통일 (텍스트와 아이콘은 대비색으로 설정)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FBFD),
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 하단 네비게이션 바의 배경색도 0xFFF9FBFD로 통일
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF9FBFD),
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: const HomePage(),
    );
  }
}
