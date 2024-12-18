import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<Map<String, dynamic>>>(
  (ref) => ScheduleNotifier(),
);

class ScheduleNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ScheduleNotifier() : super([]); // 초기 상태 빈 리스트로 설정

  // 새 일정 저장
  void saveSchedule(Map<String, dynamic> schedule) {
    state = [...state, schedule]; // 기존 상태에 새 일정 추가
  }

  // 일정 반환
  List<Map<String, dynamic>> getSchedules() {
    return state;
  }
}