import 'package:flutter/material.dart';
import './main_page/main_page.dart';
import './lost_page/lost_page.dart';
import './found_page/found_page.dart';
import 'package:sumsumfinder/screens/chat/chat_list_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // 각 탭에 해당하는 페이지 리스트
  final List<Widget> _pages = [
    MainPage(),
    LostPage(),
    FoundPage(),
    ChatListPage(),
  ];

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 인덱스에 해당하는 페이지
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
