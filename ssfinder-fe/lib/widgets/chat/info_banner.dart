import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/services/kakao_login_service.dart';

class InfoBannerWidget extends StatefulWidget {
  final String otherUserNickname;
  final String myNickname;
  final int chatRoomId; // 채팅방 ID

  const InfoBannerWidget({
    Key? key,
    required this.otherUserNickname,
    required this.myNickname,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  State<InfoBannerWidget> createState() => _InfoBannerWidgetState();
}

class _InfoBannerWidgetState extends State<InfoBannerWidget> {
  bool isLoading = true;
  bool isVerified = false;
  String verifiedStatus = "";
  String errorMessage = "";

  // 채팅방 상세 정보 저장을 위한 변수
  int? lostUserId; // 내 ID (분실자)
  int? foundUserId; // 상대방 ID (습득자)
  int? foundItemId; // 습득물 ID

  @override
  void initState() {
    super.initState();
    _loadChatRoomDetail();
  }

  // 채팅방 상세 정보를 먼저 로드
  Future<void> _loadChatRoomDetail() async {
    try {
      // 토큰 가져오기
      final token = await KakaoLoginService().getAccessToken();
      if (token == null) {
        setState(() {
          errorMessage = "인증 정보를 가져올 수 없습니다.";
          isLoading = false;
        });
        return;
      }

      // 내 ID 가져오기 (분실자 ID)
      lostUserId = await KakaoLoginService().getUserId();
      if (lostUserId == null) {
        setState(() {
          errorMessage = "사용자 정보를 가져올 수 없습니다.";
          isLoading = false;
        });
        return;
      }

      // 서버의 baseUrl 설정
      final baseUrl = const String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'https://api.sumsum.com',
      ); // 실제 서버 URL로 변경 필요

      // 채팅방 상세 정보 요청
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat-rooms/${widget.chatRoomId}/detail'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // UTF-8 디코딩 처리
        final jsonData = json.decode(utf8.decode(response.bodyBytes));

        if (jsonData['success'] == true && jsonData['data'] != null) {
          // 채팅방 상세 정보에서 필요한 값 추출
          foundUserId = jsonData['data']['opponent_id'];
          foundItemId = jsonData['data']['found_item']['id'];

          // 값을 성공적으로 가져왔다면 경로 중첩 확인 API 호출
          if (foundUserId != null && foundItemId != null) {
            await _checkOverlap();
          } else {
            setState(() {
              errorMessage = "필요한 정보를 가져올 수 없습니다.";
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = jsonData['error'] ?? "채팅방 정보를 가져올 수 없습니다.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "채팅방 정보 요청 실패: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "채팅방 정보 로드 중 오류: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _checkOverlap() async {
    try {
      if (lostUserId == null || foundUserId == null || foundItemId == null) {
        setState(() {
          errorMessage = "필요한 정보가 누락되었습니다.";
          isLoading = false;
        });
        return;
      }

      // 서버의 baseUrl 설정
      final baseUrl = const String.fromEnvironment(
        'BASE_URL',
        defaultValue: 'https://api.sumsum.com',
      ); // 실제 서버 URL로 변경 필요

      final response = await http.post(
        Uri.parse('$baseUrl/api/routes/overlap'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lost_user_id': lostUserId,
          'found_user_id': foundUserId,
          'found_item_id': foundItemId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          setState(() {
            verifiedStatus = jsonResponse['data']['verified_status'] ?? "";
            isVerified = verifiedStatus == "VERIFIED";
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = jsonResponse['message'] ?? "요청 처리 중 오류가 발생했습니다.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "서버 연결에 실패했습니다. 상태 코드: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "연결 오류: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF5FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF507BBF)),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDF0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/chat/shield_icon.svg',
              width: 24,
              height: 24,
              color: const Color(0xFFE74C3C),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "위치 정보 확인 중 오류가 발생했습니다.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'GmarketSans',
                  color: const Color(0xFF555555),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/chat/shield_icon.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'GmarketSans'),
                    children: [
                      TextSpan(
                        text: widget.otherUserNickname,
                        style: const TextStyle(color: Color(0xFF507BBF)),
                      ),
                      const TextSpan(
                        text: '님의 습득 위치와',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'GmarketSans'),
                    children: [
                      TextSpan(
                        text: '${widget.myNickname}(나)',
                        style: const TextStyle(color: Color(0xFF507BBF)),
                      ),
                      TextSpan(
                        text:
                            isVerified
                                ? '의 분실 위치가 일치합니다.'
                                : '의 분실 위치가 일치하지 않습니다.',
                        style: const TextStyle(color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
                if (!isVerified && verifiedStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getStatusMessage(verifiedStatus),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'GmarketSans',
                      color: const Color(0xFF777777),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case "NO_FINDER_LOCATION":
        return "습득자는 해당 장소를 지나지 않았습니다.";
      case "NO_LOSER_LOCATION":
        return "분실자는 해당 장소를 지나지 않았습니다.";
      case "TIME_MISMATCH":
        return "장소는 일치하지만 시간 조건이 충족되지 않았습니다.";
      default:
        return "";
    }
  }
}
