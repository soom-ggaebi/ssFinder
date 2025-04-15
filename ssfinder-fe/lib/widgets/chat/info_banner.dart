import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 로그 출력 유틸리티 함수
  void _log(String message) {
    print('📍 [InfoBanner] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('InfoBannerWidget 초기화 - 채팅방 ID: ${widget.chatRoomId}');
    _loadChatRoomDetail();
  }

  // 여러 소스에서 사용자 ID를 확인하는 향상된 메서드
  Future<int?> _getUserIdFromMultipleSources() async {
    _log('여러 소스에서 사용자 ID 조회 시도');

    try {
      // 1. KakaoLoginService를 통해 가져오기 시도
      final userId = await KakaoLoginService().getUserId();
      if (userId != null) {
        _log('✅ KakaoLoginService에서 사용자 ID 획득: $userId');
        return userId;
      }

      // 2. SharedPreferences에서 직접 확인
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('_userIdKey');
      if (userIdStr != null) {
        final userIdInt = int.tryParse(userIdStr);
        if (userIdInt != null) {
          _log('✅ SharedPreferences에서 사용자 ID 획득: $userIdInt');
          return userIdInt;
        }
      }

      // 3. 유저 프로필 API 직접 호출
      _log('다른 방법으로 사용자 ID를 찾을 수 없어 프로필 API 직접 호출');
      final token = await KakaoLoginService().getAccessToken();
      if (token == null) {
        _log('🚫 토큰이 없어 사용자 프로필을 조회할 수 없음');
        return null;
      }

      final baseUrl = EnvironmentConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['success'] == true && responseData['data'] != null) {
          final userIdFromApi = responseData['data']['id'];
          int? userIdInt;

          if (userIdFromApi is int) {
            userIdInt = userIdFromApi;
          } else if (userIdFromApi is String) {
            userIdInt = int.tryParse(userIdFromApi);
          }

          if (userIdInt != null) {
            _log('✅ API에서 사용자 ID 획득: $userIdInt');
            // 획득한 ID를 SharedPreferences에 저장
            await prefs.setString('_userIdKey', userIdInt.toString());
            return userIdInt;
          }
        }
      }

      _log('🚫 모든 방법으로 사용자 ID 조회 실패');
      return null;
    } catch (e) {
      _log('❌ 사용자 ID 조회 중 오류: $e');
      return null;
    }
  }

  // 채팅방 상세 정보를 먼저 로드
  Future<void> _loadChatRoomDetail() async {
    _log('채팅방 상세 정보 로드 시작');
    try {
      // 토큰 가져오기
      final token = await KakaoLoginService().getAccessToken();
      if (token == null) {
        _log('🚫 토큰을 가져올 수 없음');
        setState(() {
          errorMessage = "인증 정보를 가져올 수 없습니다.";
          isLoading = false;
        });
        return;
      }
      _log('✅ 토큰 획득 성공');

      // 내 ID 가져오기 (분실자 ID) - 향상된 메서드 사용
      lostUserId = await _getUserIdFromMultipleSources();
      if (lostUserId == null) {
        _log('🚫 사용자 ID를 가져올 수 없음');
        setState(() {
          errorMessage = "사용자 정보를 가져올 수 없습니다.";
          isLoading = false;
        });
        return;
      }
      _log('✅ 사용자 ID 획득 성공: $lostUserId');

      // 서버의 baseUrl을 EnvironmentConfig에서 가져오기
      final baseUrl = EnvironmentConfig.baseUrl;
      _log(
        '📡 API 요청 URL: $baseUrl/api/chat-rooms/${widget.chatRoomId}/detail',
      );

      // 채팅방 상세 정보 요청
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat-rooms/${widget.chatRoomId}/detail'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      _log('📊 API 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8 디코딩 처리
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        _log('📄 응답 데이터 success: ${jsonData['success']}');

        if (jsonData['success'] == true && jsonData['data'] != null) {
          // 채팅방 상세 정보에서 필요한 값 추출
          foundUserId = jsonData['data']['opponent_id'];
          foundItemId = jsonData['data']['found_item']['id'];

          _log('👤 상대방 ID: $foundUserId');
          _log('📦 습득물 ID: $foundItemId');

          // 값을 성공적으로 가져왔다면 경로 중첩 확인 API 호출
          if (foundUserId != null && foundItemId != null) {
            _log('✅ 필요한 데이터 모두 획득, 경로 중첩 확인 API 호출');
            await _checkOverlap();
          } else {
            _log('🚫 필요한 데이터 누락');
            setState(() {
              errorMessage = "필요한 정보를 가져올 수 없습니다.";
              isLoading = false;
            });
          }
        } else {
          _log('🚫 API 응답 오류: ${jsonData['error']}');
          setState(() {
            errorMessage = jsonData['error'] ?? "채팅방 정보를 가져올 수 없습니다.";
            isLoading = false;
          });
        }
      } else {
        _log('🚫 API 요청 실패');
        setState(() {
          errorMessage = "채팅방 정보 요청 실패: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      _log('❌ 예외 발생: $e');
      setState(() {
        errorMessage = "채팅방 정보 로드 중 오류: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _checkOverlap() async {
    _log('경로 중첩 확인 API 호출 시작');
    try {
      if (lostUserId == null || foundUserId == null || foundItemId == null) {
        _log('🚫 필요한 정보 누락');
        setState(() {
          errorMessage = "필요한 정보가 누락되었습니다.";
          isLoading = false;
        });
        return;
      }

      final baseUrl = EnvironmentConfig.baseUrl;
      final token = await KakaoLoginService().getAccessToken();
      if (token == null) {
        _log('🚫 토큰을 가져올 수 없음');
        setState(() {
          errorMessage = "인증 정보를 가져올 수 없습니다.";
          isLoading = false;
        });
        return;
      }
      _log('✅ 토큰 획득 성공');

      _log('📡 API 요청 URL: $baseUrl/api/users/routes/overlap');
      _log('📤 요청 데이터: lost_user_id=$lostUserId, found_user_id=$foundUserId, found_item_id=$foundItemId');

      // 최초 API 호출
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/routes/overlap'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lost_user_id': lostUserId,
          'found_user_id': foundUserId,
          'found_item_id': foundItemId,
        }),
      );

      _log('📊 API 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        _log('📄 최초 응답 데이터 success: ${jsonResponse['success']}');

        // 만약 응답에 포함된 found_user_id가 내 lostUserId와 동일하다면 (즉, 내 ID와 같으면)
        if (jsonResponse['success'] == true &&
            jsonResponse['data'] != null &&
            jsonResponse['data']['found_user_id'] == lostUserId) {
          _log('⚠️ found_user_id가 내 사용자 ID와 동일합니다. lostUserId와 foundUserId를 교환 후 재요청합니다.');

          // lostUserId와 foundUserId를 서로 바꾼 값을 사용하여 재요청
          final swappedResponse = await http.post(
            Uri.parse('$baseUrl/api/users/routes/overlap'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'lost_user_id': foundUserId, // 교환
              'found_user_id': lostUserId,  // 교환
              'found_item_id': foundItemId,
            }),
          );

          _log('📊 재요청 응답 상태 코드: ${swappedResponse.statusCode}');
          if (swappedResponse.statusCode == 200) {
            final swappedJsonResponse = jsonDecode(utf8.decode(swappedResponse.bodyBytes));
            _log('📄 재요청 응답 데이터 success: ${swappedJsonResponse['success']}');

            if (swappedJsonResponse['success'] == true && swappedJsonResponse['data'] != null) {
              final status = swappedJsonResponse['data']['verified_status'] ?? "";
              _log('📋 재요청 검증 상태: $status');
              setState(() {
                verifiedStatus = status;
                isVerified = verifiedStatus == "VERIFIED";
                isLoading = false;
              });
              _log('✅ 경로 일치 여부 (재요청 결과): $isVerified');
              return;
            } else {
              _log('🚫 재요청 API 응답 오류: ${swappedJsonResponse['message']}');
              setState(() {
                errorMessage = swappedJsonResponse['message'] ?? "재요청 처리 중 오류가 발생했습니다.";
                isLoading = false;
              });
              return;
            }
          } else {
            _log('🚫 재요청 API 실패');
            setState(() {
              errorMessage = "재요청 API 실패: ${swappedResponse.statusCode}";
              isLoading = false;
            });
            return;
          }
        } else if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final status = jsonResponse['data']['verified_status'] ?? "";
          _log('📋 최초 검증 상태: $status');
          setState(() {
            verifiedStatus = status;
            isVerified = verifiedStatus == "VERIFIED";
            isLoading = false;
          });
          _log('✅ 경로 일치 여부: $isVerified');
        } else {
          _log('🚫 최초 API 응답 오류: ${jsonResponse['message']}');
          setState(() {
            errorMessage = jsonResponse['message'] ?? "요청 처리 중 오류가 발생했습니다.";
            isLoading = false;
          });
        }
      } else {
        _log('🚫 API 요청 실패');
        setState(() {
          errorMessage = "서버 연결에 실패했습니다. 상태 코드: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      _log('❌ 예외 발생: $e');
      setState(() {
        errorMessage = "연결 오류: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      _log('로딩 중 UI 표시');
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
      _log('오류 UI 표시: $errorMessage');
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

    _log('정상 UI 표시 - 검증 상태: $verifiedStatus, 일치 여부: $isVerified');
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
