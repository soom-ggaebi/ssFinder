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

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 페이지 리스트
    final List<Widget> pages = [
      MainPage(),
      LostPage(),
      FoundPage(),
      ChatListPage(), // jwt 파라미터 제거
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
