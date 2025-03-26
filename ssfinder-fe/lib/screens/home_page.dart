import 'package:flutter/material.dart';
import './main/main_page.dart';
import 'lost/lost_page.dart';
import 'found/found_page.dart';
import 'package:sumsumfinder/screens/chat/chat_list_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
