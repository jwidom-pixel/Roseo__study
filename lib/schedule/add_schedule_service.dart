import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  static final CollectionReference schedulesCollection =
      FirebaseFirestore.instance.collection('schedules');

  // Firestore에 새 일정 추가
  static Future<void> addSchedule(Map<String, dynamic> schedule) async {
    await schedulesCollection.add(schedule);
  }

  // Firestore에서 일정 가져오기
  static Stream<QuerySnapshot> getSchedules() {
    return schedulesCollection.snapshots();
  }
}
