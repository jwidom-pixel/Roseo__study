import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roseo_study/schedule/add_schedule_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roseo_study/project/projects_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roseo_study/widgets/hex_to_color.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // 초기 선택된 인덱스 (캘린더 페이지)

  final List<Widget> _pages = [
    ProjectsPage(), // 프로젝트 페이지
    CalendarPage(), // 캘린더 페이지
    Placeholder(), // 세 번째 페이지 (예: 설정 페이지)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: null, // 선택된 텍스트 색상이 이 값에 영향을 받지 않도록 설정
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템 색상
        selectedLabelStyle: TextStyle(
          color: Color.fromARGB(255, 65, 65, 65), // 원하는 선택된 텍스트 색상
          fontWeight: FontWeight.bold,
          fontSize: 12,
          height: 2,
        ),
        unselectedLabelStyle: TextStyle(
          color: const Color.fromARGB(255, 100, 100, 100), // 선택되지 않은 텍스트 색상
          fontSize: 12,
          height: 0,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 0 ? Colors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.list,
                  color: _currentIndex == 0 ? Colors.white : Colors.grey),
            ),
            label: '프로젝트',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? Colors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.calendar_today,
                  color: _currentIndex == 1 ? Colors.white : Colors.grey),
            ),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? Colors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.settings,
                  color: _currentIndex == 2 ? Colors.white : Colors.grey),
            ),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, List<Map<String, dynamic>>>(
  (ref) => ScheduleNotifier(),
);

class ScheduleNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ScheduleNotifier() : super([]) {
    fetchSchedules(); // 초기화 시 데이터를 로드
  }

  // Firestore에서 일정 실시간 가져오기
  void fetchSchedules() {
    FirebaseFirestore.instance
        .collection('schedules')
        .snapshots()
        .listen((scheduleSnapshot) {
      FirebaseFirestore.instance
          .collection('projects')
          .snapshots()
          .listen((projectSnapshot) {
        try {
          // 'projects' 컬렉션 데이터 가져오기
          final projects = projectSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'labelColor': data['labelColor'] ?? '#FF000000',
            };
          }).toList();

          // 'schedules' 컬렉션 데이터 가져오기
          final schedules = scheduleSnapshot.docs.map((doc) {
            final data = doc.data();
            final projectId = data['projectId'] ?? '';

            // 프로젝트와 일정 매칭
            final project = projects.firstWhere(
              (project) => project['id'] == projectId,
              orElse: () => {'labelColor': '#000000'},
            );

            return {
              'id': doc.id,
              'title': data['title'] ?? '제목 없음',
              'startDate': data['startDate'],
              'endDate': data['endDate'],
              'color': project['labelColor'],
            };
          }).toList();

          // 상태 업데이트
          state = schedules;
        } catch (error) {
          debugPrint('Error syncing schedules and projects: $error');
        }
      });
    });
  }

  // Public 메서드로 초기화 트리거
  void initializeSchedules() {
    fetchSchedules();
  }
}

//일자 표시용 밸류
int getStartWeekday(int year, int month) {
  return DateTime(year, month, 2).weekday; // 1일의 요일 (일요일=2)
}

int getTotalDays(int year, int month) {
  return DateTime(year, month + 1, 0).day; // 해당 월의 총 일 수
}
//

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;
  bool isExpanded = false; // 드래그 상태 확인 변수
  List<Map<String, dynamic>> filteredProjects = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentDateFromServer();
    fetchProjectsForCurrentMonth();

    // Firestore 데이터 초기 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(scheduleProvider.notifier).initializeSchedules(); // 메서드 호출
    });
  }

  Future<void> fetchCurrentDateFromServer() async {
    try {
      final response = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Seoul'));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final currentDateTime = DateTime.parse(data['datetime']);
          setState(() {
            currentMonth = currentDateTime.month;
            currentYear = currentDateTime.year;
          });
        } catch (jsonError) {
          print('JSON decoding error: $jsonError');
        }
      } else {
        print('Failed to load current date. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error fetching current date: $error');
    }
  }

  Future<void> fetchProjectsForCurrentMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(currentYear, currentMonth, 1);
    final endOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    FirebaseFirestore.instance
        .collection('projects')
        .snapshots()
        .listen((projectSnapshot) {
      FirebaseFirestore.instance
          .collection('schedules')
          .where('startDate',
              isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('startDate', isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .snapshots()
          .listen((scheduleSnapshot) {
        final List<Map<String, dynamic>> tempProjects = [];

        for (var projectDoc in projectSnapshot.docs) {
          final projectData = projectDoc.data();
          if (projectData['isCompleted'] == true) continue;

          final projectSchedules = scheduleSnapshot.docs.where((scheduleDoc) {
            final scheduleData = scheduleDoc.data();
            return scheduleData['projectId'] == projectDoc.id;
          }).toList();

          if (projectSchedules.isNotEmpty) {
            final daysLeft = projectSchedules
                .map((scheduleDoc) {
                  final scheduleData = scheduleDoc.data();
                  final endDate =
                      DateTime.tryParse(scheduleData['endDate'] ?? '');
                  return endDate != null
                      ? endDate.difference(now).inDays
                      : null;
                })
                .whereType<int>()
                .reduce((a, b) => a < b ? a : b); // 가장 짧은 남은 일자 선택

            tempProjects.add({
              'title': projectData['title'] ?? '제목 없음',
              'daysLeft': daysLeft,
              'color': hexToColor(projectData['labelColor'] ?? '#000000'),
            });
          }
        }

        tempProjects.sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));

        setState(() {
          filteredProjects = tempProjects;
        });
      });
    });
  }

  void goToNextMonth() {
    setState(() {
      if (currentYear == 2099 && currentMonth == 12) return;
      currentMonth = (currentMonth % 12) + 1;
      if (currentMonth == 1) currentYear++;
    });
    fetchProjectsForCurrentMonth(); // 데이터 갱신
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
    fetchProjectsForCurrentMonth(); // 데이터 갱신
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ...List.generate(filteredProjects.length, (index) {
                    final reverseIndex =
                        filteredProjects.length - index - 1; // 역순 인덱스
                    final project = filteredProjects[reverseIndex];
                    final stackSpacing = 3.0;
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
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
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
                child: Consumer(
                  builder: (context, ref, child) {
                    // Firestore에서 가져온 schedules 데이터 구독
                    final schedules = ref.watch(scheduleProvider);

                    // Firestore에서 projects 데이터 가져오기
                    final projectsSnapshot = FirebaseFirestore.instance
                        .collection('projects')
                        .snapshots();

                    return StreamBuilder(
                      stream: projectsSnapshot,
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                              child: CircularProgressIndicator()); // 로딩 상태 표시
                        }

                        // projects 데이터를 변환
                        final projects = snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'id': doc.id,
                            'title': data['title'] ?? '제목 없음',
                            'labelColor':
                                data['labelColor'] ?? '#FF000000', // 기본값
                          };
                        }).toList();

                        // 캘린더 그리드에 데이터를 전달
                        return CalendarGrid(
                          month: currentMonth,
                          year: currentYear,
                          projects: projects,
                          schedules: schedules,
                        );
                      },
                    );
                  },
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
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
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
        borderRadius: BorderRadius.circular(30),
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
  daysLeft != null
      ? (daysLeft > 0
          ? '${daysLeft}일 남음'
          : (daysLeft == 0 ? '오늘 마감' : '${-daysLeft}일 지남'))
      : '일정 없음',
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
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> schedules;

  CalendarGrid({
    required this.month,
    required this.year,
    required this.projects,
    required this.schedules,
  });

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
                  //
                  debugPrint('here2 $schedules');
                  //
                  DateTime currentDate;

                  if (index < startWeekday - 1) {
                    final previousMonth = month == 1 ? 12 : month - 1;
                    final previousYear = month == 1 ? year - 1 : year;
                    final previousMonthTotalDays =
                        getTotalDays(previousYear, previousMonth);
                    final day =
                        previousMonthTotalDays - (startWeekday - 2 - index);
                    currentDate = DateTime(previousYear, previousMonth, day);
                  } else if (index >= startWeekday - 1 + totalDays) {
                    final day = index - (startWeekday - 1 + totalDays) + 1;
                    final nextMonth = month == 12 ? 1 : month + 1;
                    final nextYear = month == 12 ? year + 1 : year;
                    currentDate = DateTime(nextYear, nextMonth, day);
                  } else {
                    final day = index - (startWeekday - 2);
                    currentDate = DateTime(year, month, day);
                  }

                  final daySchedules = schedules.where((schedule) {
                    final startDateStr = schedule['startDate'] ?? '';
                    final endDateStr = schedule['endDate'] ?? '';
                    if (startDateStr.isEmpty || endDateStr.isEmpty)
                      return false;

                    final startDate = DateTime.tryParse(startDateStr);
                    final endDate = DateTime.tryParse(endDateStr);
                    if (startDate == null || endDate == null) return false;

                    return currentDate
                            .isAfter(startDate.subtract(Duration(days: 1))) &&
                        currentDate.isBefore(endDate.add(Duration(seconds: 1)));
                  }).toList();

                  final sortedSchedules = daySchedules.toList()
                    ..sort((a, b) {
                      final aStartDateStr = a['startDate'] ?? '';
                      final aEndDateStr = a['endDate'] ?? '';
                      final bStartDateStr = b['startDate'] ?? '';
                      final bEndDateStr = b['endDate'] ?? '';

                      final aStartDate = DateTime.tryParse(aStartDateStr);
                      final aEndDate = DateTime.tryParse(aEndDateStr);
                      final bStartDate = DateTime.tryParse(bStartDateStr);
                      final bEndDate = DateTime.tryParse(bEndDateStr);

                      final aDuration = aEndDate != null && aStartDate != null
                          ? aEndDate.difference(aStartDate).inDays
                          : 0;
                      final bDuration = bEndDate != null && bStartDate != null
                          ? bEndDate.difference(bStartDate).inDays
                          : 0;

                      return bDuration
                          .compareTo(aDuration); // 긴 일정이 위로 오도록 내림차순 정렬
                    });

// UI 생성
                  return Stack(
                    children: [
                      // 날짜와 그리드 배경
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color.fromARGB(255, 247, 247, 247)),
                          color: currentDate.month == month
                              ? Colors.white
                              : const Color.fromARGB(255, 250, 250, 250),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            '${currentDate.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentDate.month == month
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // 정렬된 일정 UI
                      ...sortedSchedules
                          .take(2)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final scheduleIndex = entry.key; // 일정 리스트에서의 인덱스를 따로 관리
                        final schedule = entry.value;

                        final startDateStr = schedule['startDate'] ?? '';
                        final endDateStr = schedule['endDate'] ?? '';
                        final title = schedule['title'] ?? '제목 없음';
                        final startDate = DateTime.tryParse(startDateStr);
                        final endDate = DateTime.tryParse(endDateStr);
                        if (startDate == null || endDate == null)
                          return SizedBox();

                        final scheduleColor = hexToColor(schedule['color']);
                        //스케쥴의 color값 활용

                        final isStartDate = DateTime(currentDate.year,
                                currentDate.month, currentDate.day)
                            .isAtSameMomentAs(DateTime(startDate.year,
                                startDate.month, startDate.day));

                        final isEndDate = DateTime(currentDate.year,
                                currentDate.month, currentDate.day)
                            .isAtSameMomentAs(DateTime(
                                endDate.year, endDate.month, endDate.day));

                        // 첫 번째 열인지 확인 (그리드 셀 인덱스 사용)
                        final isFirstColumn =
                            index % 7 == 0; // GridView.builder의 index로 판단

                        // 각 일정의 위치를 위아래로 나누기 위해 top 값 조정
                        final topOffset =
                            scheduleIndex * 23.0; // 일정 간의 수직 간격 조정
                        return Positioned(
                          top: 20 + topOffset, // 일정의 수직 위치 조정
                          left: isStartDate ? 0 : -2, // 시작 날짜라면 왼쪽 여백 0
                          right: isEndDate ? 0 : -2, // 종료 날짜라면 오른쪽 여백 0
                          child: Container(
                            height: 20, // 일정 높이
                            decoration: BoxDecoration(
                              //here 유아이에 라벨컬러를 지정하는 곳
                              color: scheduleColor,
                              //
                              borderRadius: BorderRadius.horizontal(
                                left: isStartDate
                                    ? Radius.circular(12)
                                    : Radius.zero,
                                right: isEndDate
                                    ? Radius.circular(12)
                                    : Radius.zero,
                              ),
                            ),
                            child: Center(
                              child: (isStartDate ||
                                      isFirstColumn) // 시작 날짜이거나 첫 번째 열인 경우
                                  ? Text(
                                      title.length > 5
                                          ? title.substring(0, 5)
                                          : title, // 제목 5글자로 제한
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : SizedBox.shrink(), // 조건을 만족하지 않으면 빈 위젯
                            ),
                          ),
                        );
                      }).toList(),
                    ],
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
