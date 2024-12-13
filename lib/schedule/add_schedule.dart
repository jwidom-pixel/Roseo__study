import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class AddSchedulePage extends StatefulWidget {
  @override
  _AddSchedulePageState createState() => _AddSchedulePageState();
}

class Project {
  final String name;
  final bool isCompleted;
  final Color color;

  Project({
    required this.name,
    required this.isCompleted,
    required this.color,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'],
      isCompleted: json['isCompleted'],
      color: Color(int.parse(json['color'].substring(1, 7), radix: 16) + 0xFF000000), // #RRGGBB -> ARGB
    );
  }
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  String selectedType = '일정'; // Default selected type
  bool isAllDay = false; // Default all-day toggle
  DateTime? startDate;
  DateTime? endDate;

  List<Project> projectList = []; // 프로젝트 데이터 저장
  String? selectedLabel; // 선택된 프로젝트 이름

  final TextEditingController titleController = TextEditingController(); // 제목 컨트롤러

  @override
  void initState() {
    super.initState();
    _loadProjects(); // JSON 데이터를 로드
  }

  // JSON 파일 읽기
  Future<void> _loadProjects() async {
    final String response =
        await DefaultAssetBundle.of(context).loadString('assets/projects.json');
    final data = json.decode(response);
    setState(() {
      projectList = (data['projects'] as List)
          .map((json) => Project.fromJson(json))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 추가'),
        actions: [
          TextButton(
            onPressed: () {
              // Save functionality here
            },
            child: ElevatedButton(
              onPressed: () {
                // 1. 입력한 데이터를 수집
                final newSchedule = {
                  'title': titleController.text,
                  'type': selectedType,
                  'label': selectedLabel,
                  'date': startDate,
                };

                // 2. 메인 페이지로 데이터 전달
                Navigator.pop(context, newSchedule);
              },
              child: Text('저장'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '제목 추가',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: Text('일정'),
                  selected: selectedType == '일정',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedType = '일정';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text('할 일'),
                  selected: selectedType == '할 일',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedType = '할 일';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text('프로젝트'),
                  selected: selectedType == '프로젝트',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedType = '프로젝트';
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            if (selectedType == '프로젝트') ...[
              Text('라벨 선택', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              DropdownButtonFormField<Project>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                value: projectList.firstWhereOrNull((project) => project.name == selectedLabel),
                items: projectList
                    .where((project) => !project.isCompleted) // 완료되지 않은 프로젝트만 필터링
                    .map((project) {
                  return DropdownMenuItem<Project>(
                    value: project, // 각 DropdownMenuItem에 project 객체를 전달
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: project.color, // 프로젝트 색상 표시
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(project.name), // 프로젝트 이름 표시
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Project? value) {
                  setState(() {
                    selectedLabel = value?.name; // 선택된 프로젝트의 이름 저장
                  });
                },
              ),
              SizedBox(height: 16),
            ],
            Row(
              children: [
                Text('종일', style: TextStyle(fontSize: 16)),
                Spacer(),
                Switch(
                  value: isAllDay,
                  onChanged: (value) {
                    setState(() {
                      isAllDay = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('시작', style: TextStyle(fontSize: 16)),
                Spacer(),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        startDate = date;
                      });
                    }
                  },
                  child: Text(
                    startDate != null
                        ? '${startDate!.year}-${startDate!.month}-${startDate!.day}'
                        : '날짜 선택',
                  ),
                ),
              ],
            ),
            if (!isAllDay) ...[
              Row(
                children: [
                  Text('종료', style: TextStyle(fontSize: 16)),
                  Spacer(),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          endDate = date;
                        });
                      }
                    },
                    child: Text(
                      endDate != null
                          ? '${endDate!.year}-${endDate!.month}-${endDate!.day}'
                          : '날짜 선택',
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}