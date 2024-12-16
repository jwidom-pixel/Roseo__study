import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roseo_study/schedule/add_schedule.dart';
import 'schedule/schedule_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final Map<int, Map<int, List<Map<String, dynamic>>>> projectDates = {
  2024:{
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

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      final response = await http.get(Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Seoul'));

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
      {'title': '신세계 백화점 연말 전시 포스터/리플렛', 'daysLeft': 17, 'color': Color(0xFFFF776A)},
      {'title': '신세계 백화점 연초 아트월', 'daysLeft': 40, 'color': Color.fromARGB(255, 255, 81, 87)},
      {'title': '팟캐스트', 'daysLeft': 83, 'color': Color.fromARGB(255, 255, 164, 6)},
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
              height: isExpanded ? MediaQuery.of(context).size.height * 0.27 : 90,
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
                    final topOffset = isExpanded ? reverseIndex * 40.0 : reverseIndex * stackSpacing;

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
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40, color: Colors.blue),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class ProjectChip extends StatelessWidget {
  final String title;
  final int daysLeft;
  final Color color;

  ProjectChip({required this.title, required this.daysLeft, required this.color});

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
              style: TextStyle(color: Colors.white,),
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
                              color: day == '일' ? Colors.red : (day == '토' ? Colors.blue : Colors.black),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: DateTime(year, month + 1, 0).day, // 월의 총 일 수
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final currentDate = DateTime(year, month, day);

                  // 현재 날짜에 해당하는 일정 필터링
                  final daySchedules = schedules.where((schedule) {
                    final scheduleDate = DateTime.parse(schedule['date']);
                    return scheduleDate.year == year &&
                        scheduleDate.month == month &&
                        scheduleDate.day == day;
                  }).toList();

                  return Container(
                    alignment: Alignment.topCenter,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('$day', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...daySchedules.map((schedule) => Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: schedule['color'] ?? Colors.grey,
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
