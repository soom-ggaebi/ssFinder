import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';
import 'package:sumsumfinder/widgets/map_widget.dart';
import 'package:sumsumfinder/widgets/found/items_popup.dart';
import 'package:sumsumfinder/services/auth_service.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/screens/chat/chat_room_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoundItemDetailSumsumfinder extends StatefulWidget {
  final int id;

  const FoundItemDetailSumsumfinder({Key? key, required this.id})
    : super(key: key);

  @override
  _FoundItemDetailSumsumfinderState createState() =>
      _FoundItemDetailSumsumfinderState();
}

class _FoundItemDetailSumsumfinderState
    extends State<FoundItemDetailSumsumfinder> {
  FoundItemModel? _foundItem;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFoundItem();
  }

  Future<void> _loadFoundItem() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await FoundItemsApiService().getFoundItemDetail(
        foundId: widget.id,
      );
      setState(() {
        _foundItem = FoundItemModel.fromJson(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로드 중 에러 발생: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 색상 매핑 함수
  Color getBackgroundColor(String colorName) {
    final List<Map<String, dynamic>> colorMapping = [
      {'label': '검정색', 'color': Colors.black},
      {'label': '회색', 'color': const Color(0xFFCCCCCC)},
      {'label': '베이지', 'color': const Color(0xFFE6C9A8)},
      {'label': '갈색', 'color': const Color(0xFFA67B5B)},
      {'label': '빨간색', 'color': const Color(0xFFCE464B)},
      {'label': '주황색', 'color': const Color(0xFFFFAD60)},
      {'label': '노란색', 'color': const Color(0xFFFFDD65)},
      {'label': '초록색', 'color': const Color(0xFF7FD17F)},
      {'label': '하늘색', 'color': const Color(0xFF80CCFF)},
      {'label': '파란색', 'color': const Color(0xFF5975FF)},
      {'label': '남색', 'color': const Color(0xFF2B298D)},
      {'label': '보라색', 'color': const Color(0xFFB771DF)},
      {'label': '분홍색', 'color': const Color(0xFFFF9FC0)},
    ];

    for (final mapping in colorMapping) {
      if (colorName == mapping['label']) {
        return mapping['color'] as Color;
      }
    }
    return Colors.blue[100]!;
  }

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(1, 3).join(" ");
    }
    return location;
  }

  String extractLocation2(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(0, 3).join(" ");
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_foundItem == null) {
      return const Scaffold(body: Center(child: Text('데이터가 없습니다')));
    }

    final item = _foundItem!;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {'id': item.id, 'status': item.status});
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '습득 상세 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            FutureBuilder<String?>(
              future: AuthService.getUserId(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final currentUserId = userSnapshot.data;
                final isMyPost =
                    currentUserId != null &&
                    item.userId.toString() == currentUserId;
                if (isMyPost) {
                  return IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Color(0xFF3D3D3D),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder:
                            (context) => MainOptionsPopup(
                              item: item,
                              onUpdated: _loadFoundItem,
                            ),
                      );
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 영역
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image:
                          item.image != null
                              ? DecorationImage(
                                image: NetworkImage(item.image!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        item.image == null
                            ? const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '숨숨파인더',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (item.status != "STORED")
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ),
                    
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: getBackgroundColor(item.color),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: Text(
                            item.color,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (item.minorCategory == null)
                              ? "${item.majorCategory}"
                              : "${item.majorCategory} > ${item.minorCategory}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              extractLocation(item.location),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              item.createdAt.substring(0, 10),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<String?>(
                    future: AuthService.getUserId(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                          width: 140,
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final isMyPost =
                          userSnapshot.hasData &&
                          userSnapshot.data != null &&
                          item.userId.toString() == userSnapshot.data;

                      if (!isMyPost) {
                        return ElevatedButton(
                          onPressed: () async {
                            final KakaoLoginService loginService =
                                KakaoLoginService();
                            final token = await loginService.getAccessToken();

                            if (token == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('로그인이 필요합니다')),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            try {
                              final response = await http.post(
                                Uri.parse(
                                  '${EnvironmentConfig.baseUrl}/api/chat-rooms/${item.id}',
                                ),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                              );

                              Navigator.pop(context);

                              if (response.statusCode == 200) {
                                final responseData = jsonDecode(response.body);
                                if (responseData['success'] == true) {
                                  final chatRoomId =
                                      responseData['data']['chat_room_id'];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatPage(
                                            roomId: chatRoomId,
                                            otherUserName: item.userName ?? '습득자',
                                            myName: '나',
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        responseData['error']['message'] ??
                                            '채팅방 생성 실패',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                final errorData = jsonDecode(response.body);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorData['error']['message'] ?? '서버 오류',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('채팅방 생성 중 오류 발생: $e')),
                              );
                            }
                          },
                          child: const Text(
                            '채팅하기',
                            style: TextStyle(fontSize: 14),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상세 설명
              Text(item.detail, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              // 습득일자 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  '습득 일자',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(item.foundAt, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 8),
              // 습득 장소 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        '습득 장소',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MapWidget(
                                    latitude: item.latitude,
                                    longitude: item.longitude,
                                  ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              extractLocation2(item.location),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 지도 영역
              Container(
                height: 200,
                width: double.infinity,
                child: MapWidget(
                  latitude: item.latitude,
                  longitude: item.longitude,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
