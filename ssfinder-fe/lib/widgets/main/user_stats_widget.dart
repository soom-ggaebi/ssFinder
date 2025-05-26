import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/screens/lost/lost_page.dart';
import 'package:sumsumfinder/widgets/main/found/found_page.dart';
import 'package:sumsumfinder/services/lost_items_api_service.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';

class UserStatsWidget extends StatefulWidget {
  const UserStatsWidget({Key? key}) : super(key: key);

  @override
  UserStatsWidgetState createState() => UserStatsWidgetState();
}

class UserStatsWidgetState extends State<UserStatsWidget> {
  late Future<Map<String, dynamic>> _userStatsFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  void _fetchUserStats() {
    if (KakaoLoginService().isLoggedIn.value) {
      _userStatsFuture = _getUserItemCounts();
    } else {
      _userStatsFuture = Future.value({});
    }
  }

  Future<Map<String, dynamic>> _getUserItemCounts() async {
    return await LostItemsApiService().getUserItemCounts();
  }

  void refresh() {
    setState(() {
      _fetchUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalSpacing = screenHeight * 0.02;

    return ValueListenableBuilder<bool>(
      valueListenable: KakaoLoginService().isLoggedIn,
      builder: (context, isLoggedIn, child) {
        if (!isLoggedIn) {
          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LostPage()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F1FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppText('내가 등록한 분실물'),
                      SizedBox(height: 2.0),
                      AppText(
                        '??건',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF406299),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: verticalSpacing),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FoundPage()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F1FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppText('내가 등록한 습득물'),
                      SizedBox(height: 2.0),
                      AppText(
                        '??건',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF406299),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return FutureBuilder<Map<String, dynamic>>(
            future: _userStatsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('오류 발생: ${snapshot.error}'));
              }

              final data = snapshot.data;
              final lostCount = data?['data']?['lost_item_count'] ?? 0;
              final foundCount = data?['data']?['found_item_count'] ?? 0;

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LostPage(),
                        ),
                      ).then((_) => refresh());
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FF),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('내가 등록한 분실물'),
                          const SizedBox(height: 2.0),
                          AppText(
                            '$lostCount건',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF406299),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoundPage(),
                        ),
                      ).then((_) => refresh());
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1FF),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('내가 등록한 습득물'),
                          const SizedBox(height: 2.0),
                          AppText(
                            '$foundCount건',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF406299),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}
