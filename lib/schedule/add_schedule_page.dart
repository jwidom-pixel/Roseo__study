import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'schedule_provider.dart';
import 'add_schedule_service.dart';
import 'package:roseo_study/widgets/hex_to_color.dart';




class AddSchedulePage extends StatefulWidget {
  @override
  _AddSchedulePageState createState() => _AddSchedulePageState();
}

class Project {
  final String id; // Firestore 문서 ID
  final String name;
  final bool isCompleted;
  final Color color;

  Project({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.color,
  });

  factory Project.fromFirebase(String id, Map<String, dynamic> data) {
    final labelColor = hexToColor(data['labelColor'] ?? '#FF000000');
    return Project(
      id: id, // Firestore 문서 ID 저장
      name: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      color: labelColor,
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

  final TextEditingController titleController =
      TextEditingController(); // 제목 컨트롤러

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = now;
    endDate = now.add(Duration(hours: 1));
    _loadProjects(); // Firestore에서 프로젝트 데이터를 로드
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ScheduleService.fetchProjects();
      setState(() {
        // isCompleted가 false인 프로젝트만 필터링
        projectList =
            projects.where((project) => !project.isCompleted).toList();
      });
      debugPrint("로드된 유효한 프로젝트: ${projectList.length}개");
    } catch (e) {
      debugPrint("프로젝트 로드 오류: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 추가'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final scheduleState = ref.watch(scheduleProvider);

              return ElevatedButton(
                onPressed: () async {
  if (endDate != null && startDate != null && endDate!.isBefore(startDate!)) {
    setState(() {
      startDate = endDate;
    });
  }

  final selectedProject = projectList.firstWhereOrNull(
    (project) => project.name == selectedLabel,
  );

  final newSchedule = {
    'title': titleController.text.isEmpty ? '제목 없음' : titleController.text,
    'type': selectedType,
    'projectId': selectedProject?.id ?? '', // 프로젝트 ID 저장
    'startDate': isAllDay
        ? DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0)
            .toIso8601String()
        : (startDate ?? DateTime.now()).toIso8601String(),
    'endDate': isAllDay
        ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
            .toIso8601String()
        : (endDate ?? startDate ?? DateTime.now()).toIso8601String(),
    'isAllDay': isAllDay,
  };

                  debugPrint("전송하려는 데이터: ${jsonEncode(newSchedule)}");

                  try {
                    debugPrint("Firestore 저장 시작...");
                    await ScheduleService.addSchedule(newSchedule);
                    debugPrint("Firestore 저장 성공");

                    // 상태 업데이트는 저장 성공 후에만 실행
                    ref
                        .read(scheduleProvider.notifier)
                        .saveSchedule(newSchedule);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장 완료!')),
                    );
                    Navigator.pop(context);
                  } catch (error, stackTrace) {
                    debugPrint("Firestore 저장 오류: $error");
                    debugPrint("StackTrace: $stackTrace");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
                    );
                  }
                },
                child: scheduleState is AsyncLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('저장'),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
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
                _buildChoiceChips(),
                SizedBox(height: 16),
                if (selectedType == '프로젝트') ...[
                  Text('라벨 선택', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  _buildProjectDropdown(),
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
      if (isAllDay) {
        // 시작일자와 종료일자의 시간 초기화
        startDate = DateTime(startDate!.year, startDate!.month, startDate!.day, 0, 0, 0);
        if (endDate != null) {
          endDate = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
        }
      }
    });
  },
),

                  ],
                ),
                SizedBox(height: 16),
                _buildDateTimePicker('시작', startDate, (date) {
  setState(() {
    startDate = date;
    if (endDate != null && endDate!.isBefore(startDate!)) {
      endDate = startDate; // 종료일자가 시작일자보다 빠를 경우 동기화
    }
  });
}),
_buildDateTimePicker('종료', endDate, (date) {
  setState(() {
    endDate = date;
    if (endDate!.isBefore(startDate!)) {
      startDate = endDate; // 시작일자가 종료일자보다 느릴 경우 동기화
    }
  });
}),

                SizedBox(height: 16),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final scheduleState = ref.watch(scheduleProvider);
              if (scheduleState is AsyncLoading) {
                return Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChips() {
    return Row(
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
    );
  }

  Widget _buildProjectDropdown() {
    if (projectList.isEmpty) {
      return Text('프로젝트 데이터를 로드 중입니다...');
    }

    return DropdownButtonFormField<Project>(
      decoration: InputDecoration(
        border: OutlineInputBorder(),
      ),
      value: projectList
          .firstWhereOrNull((project) => project.name == selectedLabel),
      items: projectList.map((project) {
        return DropdownMenuItem<Project>(
          value: project,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: project.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(project.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (Project? value) {
        setState(() {
          selectedLabel = value?.name;
        });
      },
    );
  }

  Widget _buildDateTimePicker(String label, DateTime? date, ValueChanged<DateTime> onDateSelected) {
  return Row(
    children: [
      Text(label, style: TextStyle(fontSize: 16)),
      Spacer(),
      TextButton(
        onPressed: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            if (isAllDay) {
              // 시간 초기화
              onDateSelected(DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
            } else {
              // 시간 포함
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()),
              );
              if (pickedTime != null) {
                onDateSelected(DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                ));
              }
            }
          }
        },
        child: Text(
          date != null
              ? isAllDay
                  ? '${date.year}-${date.month}-${date.day}' // '종일' 활성화 시 시간 제외
                  : '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
              : '날짜 및 시간 선택',
        ),
      ),
    ],
  );
}

}
