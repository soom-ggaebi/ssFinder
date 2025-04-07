import 'package:flutter/material.dart';
import './main/main_page.dart';
import 'lost/lost_page.dart';
import 'found/found_page.dart';
import 'package:sumsumfinder/screens/chat/chat_list_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;
  String? _jwt;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadJwt();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _loadJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage();

    try {
      // FlutterSecureStorage에서 토큰 가져오기 시도
      final token = await secureStorage.read(key: 'access_token');
      if (token != null) {
        if (mounted) {
          setState(() {
            _jwt = token;
          });
        }
        print('JWT 토큰 로드됨: ${token.substring(0, 10)}...'); // 토큰 일부만 출력
      } else {
        // SharedPreferences에서 시도 (이전 구현과의 호환성)
        final sharedToken = prefs.getString('jwt_token');
        if (mounted) {
          setState(() {
            _jwt = sharedToken;
          });
        }
        print(
          'SharedPreferences에서 JWT 토큰 로드됨: ${sharedToken?.substring(0, 10) ?? "null"}...',
        );
      }
    } catch (e) {
      print('JWT 토큰 로드 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 페이지 리스트는 build 안에서만 정의
    final List<Widget> pages = [
      MainPage(),
      LostPage(),
      FoundPage(),
      _jwt != null
          ? ChatListPage(jwt: _jwt!)
          : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text("JWT 토큰 로딩 중..."),
                ElevatedButton(onPressed: _loadJwt, child: const Text("다시 시도")),
              ],
            ),
          ),
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
