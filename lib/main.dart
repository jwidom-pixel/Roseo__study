import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roseo_study/schedule/add_schedule.dart';
import 'schedule/schedule_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roseo_study/project/projects.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ScheduleNotifier() : super([]) {
    _fetchSchedules();
  }

  // Firestore에서 일정 실시간 가져오기
  void _fetchSchedules() {
    FirebaseFirestore.instance
        .collection('schedules')
        .snapshots()
        .listen((snapshot) {
      final schedules = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
      state = schedules; // 상태 업데이트
    });
  }
}

final Map<int, Map<int, List<Map<String, dynamic>>>> projectDates = {
  2024: {
    12: [
      {'day': 1, 'title': '프로젝트 A', 'color': Colors.purple},
      {'day': 5, 'title': '프로젝트 B', 'color': Colors.orange},
      {'day': 15, 'title': '프로젝트 C', 'color': Colors.red},
    ],
    11: [
      {'day': 10, 'title': '프로젝트 D', 'color': Colors.blue},
      {'day': 20, 'title': '프로젝트 E', 'color': Colors.green},
    ],
  },
};

//일자 표시용 밸류
int getStartWeekday(int year, int month) {
  return DateTime(year, month, 2).weekday; // 1일의 요일 (일요일=2)
}

int getTotalDays(int year, int month) {
  return DateTime(year, month + 1, 0).day; // 해당 월의 총 일 수
}
//

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //테마 지정
      theme: ThemeData(
        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 65, 65, 65),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        // 버튼 테마 설정
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 65, 65, 65), // 버튼 텍스트 색상
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // 텍스트 색상
            backgroundColor: Color.fromARGB(255, 65, 65, 65), // 버튼 배경색
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 65, 65, 65), // 버튼 텍스트 색상
          ),
        ),
      ),
      //
      debugShowCheckedModeBanner: false,
      home: CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;
  bool isExpanded = false; // 드래그 상태 확인 변수

  @override
  void initState() {
    super.initState();
    fetchCurrentDateFromServer();
  }

  Future<void> fetchCurrentDateFromServer() async {
    try {
      final response = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Seoul'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentDateTime = DateTime.parse(data['datetime']);

        setState(() {
          currentMonth = currentDateTime.month;
          currentYear = currentDateTime.year;
        });
      } else {
        print('Failed to load current date from server.');
      }
    } catch (error) {
      print('Error fetching current date: $error');
    }
  }

  void goToNextMonth() {
    setState(() {
      if (currentYear == 2099 && currentMonth == 12) return;
      currentMonth = (currentMonth % 12) + 1;
      if (currentMonth == 1) currentYear++;
    });
  }

  void goToPreviousMonth() {
    setState(() {
      if (currentMonth == 1) {
        if (currentYear == 2023) return;
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = [
      {'title': '11~12월 커미션', 'daysLeft': 3, 'color': Color(0xFF9747FF)},
      {
        'title': '신세계 백화점 연말 전시 포스터/리플렛',
        'daysLeft': 17,
        'color': Color(0xFFFF776A)
      },
      {
        'title': '신세계 백화점 연초 아트월',
        'daysLeft': 40,
        'color': Color.fromARGB(255, 255, 81, 87)
      },
      {
        'title': '팟캐스트',
        'daysLeft': 83,
        'color': Color.fromARGB(255, 255, 164, 6)
      },
      {'title': '24절기 병풍 프로젝트', 'daysLeft': 320, 'color': Color(0xFFCCA0FF)},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              '$currentMonth월',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '$currentYear년',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.black),
            onPressed: goToPreviousMonth,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.black),
            onPressed: goToNextMonth,
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 5) {
            setState(() {
              isExpanded = true;
            });
          } else if (details.delta.dy < -5) {
            setState(() {
              isExpanded = false;
            });
          }
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height:
                  isExpanded ? MediaQuery.of(context).size.height * 0.27 : 90,
              //펼쳐졌을 때 높이 : 접혔을 때 높이
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20), // 모서리 둥글기 추가
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5), // 섀도우 색상
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, -2), // 섀도우 방향
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 스프레드 연산자를 사용하여 위젯 리스트 추가
                  ...List.generate(projects.length, (index) {
                    final reverseIndex = projects.length - index - 1; // 역순 인덱스
                    final project = projects[reverseIndex];
                    final stackSpacing = 3.0; // 스택에서 칩 간의 간격
                    final topOffset = isExpanded
                        ? reverseIndex * 40.0
                        : reverseIndex * stackSpacing;

                    return AnimatedPositioned(
                      duration: Duration(milliseconds: 300),
                      top: topOffset,
                      left: 0,
                      right: 0,
                      child: ProjectChip(
                        title: project['title'] as String,
                        daysLeft: project['daysLeft'] as int,
                        color: project['color'] as Color,
                      ),
                    );
                  }),
                  // 하단 중앙 회색 라인 항상 표시
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16), // 간격 조정
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 캘린더 영역
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                child: CalendarGrid(
                  month: currentMonth,
                  year: currentYear,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => (AddSchedulePage())),
          );
        },
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),

      // 하단 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '프로젝트 보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, size: 40, color: Colors.blue),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProjectsPage()),
            );
          } else if (index == 1) {
            // 캘린더 버튼은 현재 화면 유지
          } else if (index == 2) {
            // 설정 페이지로 이동하도록 구현
          }
        },
      ),
    );
  }
}

class ProjectChip extends StatelessWidget {
  final String title;
  final int daysLeft;
  final Color color;

  ProjectChip(
      {required this.title, required this.daysLeft, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Text(
            '$daysLeft}일 남음',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class CalendarGrid extends StatelessWidget {
  final int month;
  final int year;

  CalendarGrid({required this.month, required this.year});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // scheduleProvider에서 데이터 읽기
        final schedules = ref.watch(scheduleProvider);

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['일', '월', '화', '수', '목', '금', '토']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: day == '일'
                                  ? Colors.red
                                  : (day == '토' ? Colors.blue : Colors.black),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 7열(요일 기준)
                  childAspectRatio: 0.8, // 세로 길이를 가로보다 더 길게 설정 (0.8은 세로가 더 길어짐)
                  crossAxisSpacing: 0, // 블록 간격
                  mainAxisSpacing: 0, // 블록 간격
                ),
                itemCount: 42, // 7 x 6 그리드
                itemBuilder: (context, index) {
                  final startWeekday = getStartWeekday(year, month);
                  final totalDays = getTotalDays(year, month);

                  // 현재 날짜 계산
                  DateTime currentDate;

                  if (index < startWeekday - 1) {
                    // 전달 날짜
                    final previousMonth = month == 1 ? 12 : month - 1;
                    final previousYear = month == 1 ? year - 1 : year;
                    final previousMonthTotalDays =
                        getTotalDays(previousYear, previousMonth);
                    final day =
                        previousMonthTotalDays - (startWeekday - 2 - index);
                    currentDate = DateTime(previousYear, previousMonth, day);
                  } else if (index >= startWeekday - 1 + totalDays) {
                    // 다음 달 날짜
                    final day = index - (startWeekday - 1 + totalDays) + 1;
                    final nextMonth = month == 12 ? 1 : month + 1;
                    final nextYear = month == 12 ? year + 1 : year;
                    currentDate = DateTime(nextYear, nextMonth, day);
                  } else {
                    // 현재 달 날짜
                    final day = index - (startWeekday - 2);
                    currentDate = DateTime(year, month, day);
                  }

                  // currentDate를 사용해 일정을 필터링
                  final daySchedules = schedules.where((schedule) {
                    final scheduleDate = DateTime.parse(schedule['date']);
                    return scheduleDate.year == currentDate.year &&
                        scheduleDate.month == currentDate.month &&
                        scheduleDate.day == currentDate.day;
                  }).toList();

                  // UI 반환
                  return Container(
                    alignment: Alignment.topCenter,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color.fromARGB(255, 247, 247, 247)),
                      color: currentDate.month == month
                          ? Colors.white
                          : const Color.fromARGB(255, 250, 250, 250),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${currentDate.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentDate.month == month
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        ...daySchedules.map((schedule) => Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: schedule['color'] != null
                                          ? Color(schedule['color'])
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    schedule['title'],
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
