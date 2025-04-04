import 'package:intl/intl.dart';

class TimeFormatter {
  // 현재 시간을 'HH:mm' 형식으로 반환
  static String getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // 주어진 시간의 상대적 시간 포맷팅
  static String getFormattedDate(String sendAt) {
    try {
      final dateTime = DateTime.parse(sendAt);
      final now = DateTime.now();
      // 현재 시간 로그 추가
      print('현재 시간: $now');
      print('알림 시간: $dateTime');

      final difference = now.difference(dateTime); // 현재 시간과의 차이
      print('시간 차이: ${difference.inMinutes} 분');

      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return DateFormat('yyyy.MM.dd').format(dateTime);
      }
    } catch (e) {
      print('날짜 포맷팅 오류: $e');
      return sendAt; // 오류 발생 시 원본 반환
    }
  }

  // 주어진 시간의 정확한 시간 포맷팅 (HH:mm)
  static String formatMessageTime(String sendAt) {
    try {
      final dateTime = DateTime.parse(sendAt);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      print('시간 포맷팅 오류: $e');
      return sendAt;
    }
  }

  // 날짜 그룹화를 위한 메서드
  static DateTime getDateWithoutTime(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  // 날짜 헤더 포맷팅
  static String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '오늘';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '어제';
    } else {
      return DateFormat('M월 d일').format(date);
    }
  }

  // 날짜별로 그룹화
  static Map<DateTime, List<dynamic>> groupByDate(List<dynamic> items) {
    final groupedItems = <DateTime, List<dynamic>>{};

    for (var item in items) {
      final sendAt = DateTime.parse(item['send_at']);
      final dateWithoutTime = getDateWithoutTime(sendAt);

      if (!groupedItems.containsKey(dateWithoutTime)) {
        groupedItems[dateWithoutTime] = [];
      }
      groupedItems[dateWithoutTime]!.add(item);
    }

    // 날짜 역순 정렬
    return Map.fromEntries(
      groupedItems.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }
}
