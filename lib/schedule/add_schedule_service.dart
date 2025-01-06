import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_schedule_page.dart';

Future<List<Map<String, dynamic>>> fetchProjects() async {
  final querySnapshot =
      await FirebaseFirestore.instance.collection('projects').get();
  return querySnapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();
}

class ScheduleService {
  static final CollectionReference schedulesCollection =
      FirebaseFirestore.instance.collection('schedules');

  // Firestore에서 프로젝트 가져오기
  static Future<List<Project>> fetchProjects() async {
  final querySnapshot =
      await FirebaseFirestore.instance.collection('projects').get();

  return querySnapshot.docs.map((doc) {
    return Project.fromFirebase(doc.id, doc.data());
  }).toList();
}


  // Firestore에 새 일정 추가
  static Future<void> addSchedule(Map<String, dynamic> schedule) async {
    await schedulesCollection.add(schedule);
  }

  // Firestore에서 일정 가져오기
  static Stream<QuerySnapshot> getSchedules() {
    return schedulesCollection.snapshots();
  }
}
