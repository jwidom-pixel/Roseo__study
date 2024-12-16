import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_schedule_service.dart';

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, AsyncValue<void>>((ref) {
  return ScheduleNotifier();
});

class ScheduleNotifier extends StateNotifier<AsyncValue<void>> {
  ScheduleNotifier() : super(const AsyncValue.data(null));

  Future<void> saveSchedule(Map<String, dynamic> schedule) async {
    state = const AsyncValue.loading();
    try {
      await ScheduleService.addSchedule(schedule);
      state = const AsyncValue.data(null); // 성공
    } catch (error, stackTrace) { // stackTrace 추가
      state = AsyncValue.error(error, stackTrace); // 두 번째 인자로 stackTrace 추가
    }
  }
}