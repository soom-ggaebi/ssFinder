import 'package:dio/dio.dart';
import 'dart:io';
import '../models/chat_message.dart';
import 'package:sumsumfinder/config/environment_config.dart';

class ChatService {
  final Dio _dio = Dio();
  final String baseUrl = EnvironmentConfig.baseUrl;

  // 이미지 업로드 메서드
  Future<ChatMessage?> uploadImage(
    File imageFile,
    int chatRoomId,
    int senderId,
    String token,
  ) async {
    try {
      // 현재 시간을 HH:MM 형식으로 가져오기
      final now = DateTime.now();
      final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      // FormData 생성
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      // 헤더 설정
      _dio.options.headers = {'Authorization': token};

      // API 요청
      Response response = await _dio.post(
        '$baseUrl/api/chat-rooms/$chatRoomId/upload',
        data: formData,
      );

      // 응답 확인 및 처리
      if (response.statusCode == 200 && response.data['success'] == true) {
        // 서버에서 반환된 이미지 URL 추출
        String content = response.data['data']['content'];
        // <> 괄호 제거 (필요한 경우)
        if (content.startsWith('<') && content.endsWith('>')) {
          content = content.substring(1, content.length - 1);
        }

        // 새 ChatMessage 객체 생성 및 반환
        return ChatMessage(
          text: '', // 이미지는 text가 비어있을 수 있음
          isSent: true,
          time: timeString,
          imageUrl: content,
          type: 'IMAGE',
        );
      } else {
        print('이미지 업로드 실패: ${response.data}');
        return null;
      }
    } catch (e) {
      print('이미지 업로드 중 오류 발생: $e');
      return null;
    }
  }
}
