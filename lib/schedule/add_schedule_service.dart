import 'dart:convert';
import 'package:http/http.dart' as http;

class ScheduleService {
  static const String baseUrl = 'https://your-server-api.com'; // 서버 URL 변경 필요

  static Future<void> addSchedule(Map<String, dynamic> schedule) async {
    final url = Uri.parse('$baseUrl/schedules');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(schedule),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('일정이 성공적으로 저장되었습니다.');
    } else {
      throw Exception('서버 요청 실패: ${response.statusCode}');
    }
  }
}
