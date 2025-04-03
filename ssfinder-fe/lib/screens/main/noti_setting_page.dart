import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';

class NotificationListPage extends StatefulWidget {
  final KakaoLoginService kakaoLoginService;

  const NotificationListPage({Key? key, required this.kakaoLoginService})
    : super(key: key);

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  late final KakaoLoginService _kakaoLoginService;

  bool allNotificationsEnabled = true;
  // 알림 설정 상태 저장
  Map<String, bool> notificationSettings = {
    'TRANSFER': true, // 습득물 인계 알림
    'CHAT': true, // 채팅 알림
    'AI_MATCH': true, // AI 매칭 알림
    'ITEM_REMINDER': true, // 소지품 알림
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _kakaoLoginService = widget.kakaoLoginService;
    _loadNotificationSettings();
  }

  // 전체 알림 설정 상태 로드
  Future<void> _loadAllNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool allEnabled = true;

      // 모든 알림 설정이 켜져 있는지 확인
      for (var value in notificationSettings.values) {
        if (!value) {
          allEnabled = false;
          break;
        }
      }

      setState(() {
        allNotificationsEnabled = allEnabled;
      });

      // 전체 알림 설정 저장
      await prefs.setBool('notifications_enabled', allEnabled);
    } catch (e) {
      print('전체 알림 설정 로드 중 오류: $e');
    }
  }

  // 알림 설정 불러오기
  Future<void> _loadNotificationSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 로컬 설정 먼저 로드 (빠른 UI 업데이트를 위해)
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        notificationSettings['TRANSFER'] =
            prefs.getBool('notification_TRANSFER') ?? true;
        notificationSettings['CHAT'] =
            prefs.getBool('notification_CHAT') ?? true;
        notificationSettings['AI_MATCH'] =
            prefs.getBool('notification_AI_MATCH') ?? true;
        notificationSettings['ITEM_REMINDER'] =
            prefs.getBool('notification_ITEM_REMINDER') ?? true;
      });

      // 서버에서 현재 설정 가져오기
      final authToken = await _kakaoLoginService.getAccessToken();

      if (authToken == null) {
        print('인증 토큰이 없습니다. 로그인이 필요합니다.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/notifications/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data != null && data is List) {
          // 서버에서 받은 알림 설정으로 업데이트
          Map<String, bool> serverSettings = {};

          for (var item in data) {
            if (item['notification_type'] != null && item['enabled'] != null) {
              serverSettings[item['notification_type']] = item['enabled'];
            }
          }

          // 서버 설정으로 로컬 상태 업데이트
          setState(() {
            for (var type in notificationSettings.keys) {
              if (serverSettings.containsKey(type)) {
                notificationSettings[type] = serverSettings[type]!;
                // 로컬 저장소에도 저장
                prefs.setBool('notification_$type', serverSettings[type]!);
              }
            }
          });
        }
      }

      // 전체 알림 설정 상태 계산 및 업데이트
      bool allEnabled = notificationSettings.values.every((enabled) => enabled);
      setState(() {
        allNotificationsEnabled = allEnabled;
      });

      // 전체 알림 상태 저장
      await prefs.setBool('notifications_enabled', allEnabled);
    } catch (e) {
      // 에러 처리
      print('알림 설정 불러오기 오류: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 전체 알림 설정 저장
  Future<void> _saveAllNotificationSettings(bool value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 먼저 UI 업데이트
    setState(() {
      allNotificationsEnabled = value;
      // 모든 개별 알림 설정을 같은 값으로 설정
      for (var key in notificationSettings.keys) {
        notificationSettings[key] = value;
      }
    });

    try {
      // FCM 토큰 가져오기
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // 인증 토큰 가져오기
      final authToken = await _kakaoLoginService.getAccessToken();

      if (authToken == null) {
        print('인증 토큰이 없습니다. 로그인이 필요합니다.');
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인 상태를 확인해주세요.')),
        );
        // 설정을 원래대로 되돌림
        setState(() {
          allNotificationsEnabled = !value;
          for (var key in notificationSettings.keys) {
            notificationSettings[key] = !value;
          }
        });
        return;
      }

      bool allSuccess = true;

      // 각 알림 유형별로 설정 저장
      for (String key in notificationSettings.keys) {
        try {
          final response = await http.patch(
            Uri.parse(
              '${dotenv.env['BACKEND_URL']}/api/notifications/settings',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: json.encode({
              'notification_type': key,
              'enabled': value,
              'fcm_token': fcmToken,
            }),
          );

          if (response.statusCode != 204 && response.statusCode != 200) {
            print('$key 알림 설정 저장 실패: 상태 코드 ${response.statusCode}');
            allSuccess = false;
          }
        } catch (e) {
          print('$key 알림 설정 중 예외 발생: $e');
          allSuccess = false;
        }
      }

      if (allSuccess) {
        // 서버 저장 성공 시 로컬에도 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', value);

        // 개별 알림 설정도 전체 설정과 동일하게 설정
        for (var key in notificationSettings.keys) {
          await prefs.setBool('notification_$key', value);
        }

        // scaffoldMessenger.showSnackBar(
        //   const SnackBar(content: Text('모든 알림 설정이 변경되었습니다.')),
        // );
      } else {
        // 일부 실패 시 안내
        // scaffoldMessenger.showSnackBar(
        //   const SnackBar(content: Text('일부 알림 설정 변경에 실패했습니다. 다시 시도해 주세요.')),
        // );
      }
    } catch (e) {
      print('전체 알림 설정 중 예외 발생: $e');
      // 예외 발생 시 UI 롤백 및 오류 메시지
      setState(() {
        allNotificationsEnabled = !value;
        for (var key in notificationSettings.keys) {
          notificationSettings[key] = !value;
        }
      });
      // scaffoldMessenger.showSnackBar(
      //   SnackBar(content: Text('알림 설정 중 오류 발생: $e')),
      // );
    }
  }

  // 알림 설정 저장하기
  Future<void> _saveNotificationSetting(String key, bool value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // FCM 토큰 가져오기
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM 토큰: $fcmToken');

      // KakaoLoginService에서 인증 토큰 가져오기
      final authToken = await _kakaoLoginService.getAccessToken();

      if (authToken == null) {
        print('인증 토큰이 없습니다. 로그인이 필요합니다.');
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인 상태를 확인해주세요.')),
        );
        // 설정을 원래대로 되돌림
        setState(() {
          notificationSettings[key] = !value;
        });
        return;
      }

      print(
        '알림 설정 요청 시작($key): PATCH ${dotenv.env['BACKEND_URL']}/api/notifications/settings',
      );
      print(
        '요청 본문: ${json.encode({'notification_type': key, 'enabled': value, 'fcm_token': fcmToken})}',
      );

      final response = await http.patch(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/notifications/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'notification_type': key,
          'enabled': value,
          'fcm_token': fcmToken,
        }),
      );

      print('$key 응답 상태 코드: ${response.statusCode}');
      print('$key 응답 본문: ${response.body}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('$key 알림 설정 저장 성공');
        // 서버 저장 성공 시 로컬에도 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_$key', value);

        // 전체 알림 설정 상태 업데이트
        bool allEnabled = true;
        for (var enabled in notificationSettings.values) {
          if (!enabled) {
            allEnabled = false;
            break;
          }
        }

        setState(() {
          allNotificationsEnabled = allEnabled;
        });

        await prefs.setBool('notifications_enabled', allEnabled);

        // scaffoldMessenger.showSnackBar(
        //   SnackBar(content: Text('$key 알림 설정이 변경되었습니다.')),
        // );
      } else {
        print('$key 알림 설정 저장 실패: 상태 코드 ${response.statusCode}');
        // 실패 시 UI 롤백 및 오류 메시지
        setState(() {
          notificationSettings[key] = !value;
        });
        // scaffoldMessenger.showSnackBar(
        //   SnackBar(content: Text('$key 알림 설정 변경에 실패했습니다. 다시 시도해 주세요.')),
        // );
      }
    } catch (e) {
      print('알림 설정 중 예외 발생: $e');
      // 예외 발생 시 UI 롤백 및 오류 메시지
      setState(() {
        notificationSettings[key] = !value;
      });
      // scaffoldMessenger.showSnackBar(
      //   SnackBar(content: Text('알림 설정 중 오류 발생: $e')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '알림 설정',
        onBackPressed: () => Navigator.of(context).pop(),
        onClosePressed:
            () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  const SizedBox(height: 12),
                  _buildNotificationCategory('알림 설정'),

                  // 전체 알림 설정 추가
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: Colors.grey[700],
                      ),
                      title: const Text(
                        '전체 알림',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '모든 알림을 한번에 설정합니다',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Switch(
                        value: allNotificationsEnabled,
                        onChanged: (value) async {
                          await _saveAllNotificationSettings(value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF6750A4),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  _buildNotificationCategory('개별 알림 설정'),
                  _buildNotificationItem(
                    '습득물 인계 알림',
                    '습득물 인계 마감일이 1일 전, 당일일 경우 알림을 받습니다',
                    'TRANSFER',
                  ),
                  // 나머지 기존 항목들...
                  _buildNotificationItem(
                    '채팅 알림',
                    '새로운 채팅 메시지가 도착하면 알림을 받습니다',
                    'CHAT',
                  ),
                  _buildNotificationItem(
                    'AI 매칭 알림',
                    'AI 매칭 결과가 나오면 알림을 받습니다',
                    'AI_MATCH',
                  ),
                  _buildNotificationItem(
                    '소지품 리마인더',
                    '소지품 리마인더 알림을 받습니다',
                    'ITEM_REMINDER',
                  ),
                ],
              ),
    );
  }

  // 알림 카테고리 제목 위젯
  Widget _buildNotificationCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // 알림 항목 위젯
  Widget _buildNotificationItem(
    String title,
    String subtitle,
    String settingKey,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: notificationSettings[settingKey] ?? false,
          onChanged: (bool value) async {
            // 스위치 상태 변경
            setState(() {
              notificationSettings[settingKey] = value;
            });

            // 로딩 표시
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(
            //     content: Text('알림 설정 변경 중...'),
            //     duration: Duration(seconds: 1),
            //   ),
            // );

            // 설정 저장
            await _saveNotificationSetting(settingKey, value);
          },
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF6750A4),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[300],
        ),
      ),
    );
  }
}
