import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:roseo_study/project/project_edit_page.dart';
import 'package:roseo_study/widgets/hex_to_color.dart';

// 모델 클래스 생성 (그룹화)
class NewLabel {
  final Color color;
  final String label;

  NewLabel(this.color, this.label);
}
//

class ProjectsPage extends StatefulWidget {
  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _titleController = TextEditingController();
  bool _isSaveButtonEnabled = false; // 저장 버튼 상태

  @override
  void initState() {
    super.initState();

    // 제목 필드 변경 감지
    _titleController.addListener(() {
      _isSaveButtonEnabled = _titleController.text.isNotEmpty; // 제목이 비어있는지 확인
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _revenueController =
      TextEditingController(text: null);

  String _selectedCategory = '개인';
  DateTime? _lastProjectDate;
  Color _newProjectLabelColor = Color.fromARGB(255, 65, 65, 65);

  String _selectedCurrency = '원';

  final List<String> _categories = ['개인', '연재', '외주', '제작', '행사'];
  final List<String> _currencies = ['원', '\$', '€', '¥', '元'];

  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0);

  Future<int?> calculateDaysRemaining(String projectId) async {
    final today = DateTime.now();
    try {
      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('projectId', isEqualTo: projectId) // 프로젝트 ID와 일치하는 일정 필터링
          .get();

      if (schedulesSnapshot.docs.isEmpty) {
        return null; // 일정이 없으면 null 반환
      }

      // 가장 마지막 일자 계산
      final lastDate = schedulesSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return DateTime.tryParse(data['endDate'] ?? '');
          })
          .whereType<DateTime>()
          .reduce((a, b) => a.isAfter(b) ? a : b);

      return lastDate.difference(today).inDays; // D-Day 계산
    } catch (e) {
      debugPrint("D-Day 계산 중 오류 발생: $e");
      return null;
    }
  }

  Future<void> _saveProject() async {
    final projectData = {
      'createdAt': DateTime.now().toIso8601String(),
      'title': _titleController.text,
      'category': _selectedCategory,
      'lastProjectDate': _lastProjectDate?.toIso8601String() ?? '',
      'description': _descriptionController.text,
      'client': _clientController.text.isEmpty ? '없음' : _clientController.text,
      'revenue': int.tryParse(_revenueController.text.replaceAll(',', '')) ?? 0,
      'currency': _selectedCurrency,
      'labelColor':
          '#${_newProjectLabelColor.value.toRadixString(16).padLeft(8, '0')}',
      'isCompleted': false, // 기본값: 진행중
    };

    try {
      await FirebaseFirestore.instance.collection('projects').add(projectData);
      // 성공 메시지 다이얼로그 표시
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent, // 배경 투명화
        barrierColor: Colors.transparent,
        builder: (context) {
          // 1초 후 팝업 닫기
          Future.delayed(Duration(milliseconds: 1300), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // 팝업 닫기
            }
          });
          return Container(
            margin: EdgeInsets.all(30),
            padding: EdgeInsets.fromLTRB(30, 16, 30, 16), // 내부 여백
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230), // 팝업 배경색
              borderRadius: BorderRadius.circular(30), // 둥근 모서리
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2), // 그림자 위치
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 팝업 높이를 내용에 맞게 최소화
              children: [
                Text(
                  '새로운 프로젝트가 생성되었습니다.',
                  textAlign: TextAlign.center, // 텍스트 정 가운데 정렬
                  style: TextStyle(fontSize: 16), // 텍스트 스타일 설정
                ),
              ],
            ),
          );
        },
      );
      _clearFields();
    } catch (e) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent, // 배경 투명화
        builder: (context) {
          // 1초 후 팝업 닫기
          Future.delayed(Duration(milliseconds: 1300), () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // 팝업 닫기
            }
          });
          return Container(
            margin: EdgeInsets.all(30),
            padding: EdgeInsets.fromLTRB(30, 16, 30, 16), // 내부 여백
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230), // 팝업 배경색
              borderRadius: BorderRadius.circular(30), // 둥근 모서리
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2), // 그림자 위치
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 팝업 높이를 내용에 맞게 최소화
              children: [
                Text(
                  '새로운 프로젝트 생성에 실패했습니다.',
                  textAlign: TextAlign.center, // 텍스트 정 가운데 정렬
                  style: TextStyle(fontSize: 16), // 텍스트 스타일 설정
                ),
              ],
            ),
          );
        },
      );
    }
  }


  void _clearFields() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _clientController.clear();
      _revenueController.text = "";
      _selectedCategory = '개인';
      _selectedCurrency = '원';
      _lastProjectDate = null;
      _newProjectLabelColor = Color.fromARGB(255, 65, 65, 65); // 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로젝트 관리'),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('projects')
              .orderBy('createdAt', descending: true) // 생성일시 기준 내림차순 정렬
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  '생성된 프로젝트가 없습니다.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final project = snapshot.data!.docs[index];
                  final labelColor =
                      hexToColor(project['labelColor'] ?? '#FF000000');
                  final isCompleted = project['isCompleted'] ?? false;

                  return FutureBuilder<int?>(
                    future: calculateDaysRemaining(project.id),
                    builder: (context, dDaySnapshot) {
                      if (dDaySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return SizedBox.shrink(); // 로딩 상태에서는 아무것도 표시하지 않음
                      }

                      if (dDaySnapshot.hasError) {
                        debugPrint(
                            "Error calculating D-Day: ${dDaySnapshot.error}");
                        return Text('오류 발생',
                            style: TextStyle(color: Colors.red));
                      }

                      final daysRemaining = dDaySnapshot.data;

                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProjectPage(project: project),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.transparent, // Card 배경 제거
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? labelColor.withOpacity(0.5)
                                        : labelColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(2),
                                      topRight: Radius.circular(2),
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                  ),
                                  padding: EdgeInsets.fromLTRB(
                                      20, 10, 20, 10), // 왼쪽, 위, 오른쪽, 아래 설정
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        project['title'] ?? '제목 없음',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (isCompleted == true)
                                        Text('완료됨',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            )),
                                      if (daysRemaining != null && !isCompleted)
                                        Text(
                                          '${daysRemaining}일 남음',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Project Description
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    project['description'] != null &&
                                            project['description'].isNotEmpty
                                        ? project['description']
                                        : '프로젝트 내용이 없습니다.', // 기본 메시지,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: project['description'] != null &&
                                              project['description'].isNotEmpty
                                          ? Color.fromARGB(255, 65, 65, 65)
                                          : Colors.grey[500], // 기본 메시지는 흐린 색상
                                    ),
                                  ),
                                ),

                                // Category, Client, Revenue Section
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end, // 오른쪽 정렬
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end, // 오른쪽 정렬
                                      children: [
                                        Chip(
                                          backgroundColor: isCompleted
                                              ? labelColor.withOpacity(0.5)
                                              : labelColor,
                                          label: Text(
                                            project['category'] ?? '',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12), // 텍스트 크기 축소
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4), // 패딩 축소
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                50), // 둥글게 설정
                                          ),
                                          side: BorderSide.none, // 테두리 제거
                                        ),
                                        SizedBox(width: 8), // 칩 간 간격
                                        project['client'] != null &&
                                                project['client'].isNotEmpty
                                            ? Chip(
                                                backgroundColor: isCompleted
                                                    ? labelColor
                                                        .withOpacity(0.5)
                                                    : labelColor,
                                                label: Text(
                                                  project['client'],
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                side: BorderSide.none, // 테두리 제거
                                              )
                                            : SizedBox
                                                .shrink(), // 내용이 없으면 아무것도 렌더링하지 않음

                                        project['client'] != null &&
                                                project['client'].isNotEmpty
                                            ? SizedBox(width: 8)
                                            : SizedBox.shrink(),
                                        Chip(
                                          backgroundColor: isCompleted
                                              ? labelColor.withOpacity(0.5)
                                              : labelColor,
                                          label: Text(
                                            '${currencyFormatter.format(project['revenue'] ?? 0)} ${project['currency'] ?? ''}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12), // 텍스트 크기 축소
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4), // 패딩 축소
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          side: BorderSide.none, // 테두리 제거
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ));
                    },
                  );
                });
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        backgroundColor: Colors.black,
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Center(
              child: Text('새 프로젝트 추가',
                  style: TextStyle(
                    fontSize: 18, // 타이틀 폰트 크기
                  ))),
          content: Container(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: _categories.map((category) {
                      return ChoiceChip(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4), // 내부 패딩 축소
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          if (selected) {
                            setStateDialog(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(50), // 모서리를 둥글게 설정
                        ),
                        selectedColor: _newProjectLabelColor,
                        labelStyle: TextStyle(
                          color: _selectedCategory == category
                              ? Colors.white
                              : _newProjectLabelColor,
                        ),
                        backgroundColor: Colors.grey[200],
                        showCheckmark: false, // 체크 아이콘 제거
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final newLabel = await showDialog<NewLabel>(
                        context: context,
                        builder: (context) {
                          Color tempColor =
                              _newProjectLabelColor; // 다이얼로그에서만 사용하는 색상
                          String tempTitle =
                              _titleController.text; // 다이얼로그에서만 사용하는 제목

                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
                              final textController =
                                  TextEditingController.fromValue(
                                TextEditingValue(
                                  text: tempTitle,
                                  selection: TextSelection.collapsed(
                                    offset: tempTitle.length,
                                  ),
                                ),
                              );

                              return AlertDialog(
                                title: Text('프로젝트 제목 및 라벨 컬러',
                                    style: TextStyle(
                                      fontSize: 18, // 타이틀 폰트 크기
                                    )),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // TextField 입력 (텍스트 상태 관리)
                                      TextField(
                                        controller: _titleController,
                                        onChanged: (value) {
                                          setStateDialog(() {
                                            tempTitle = value; // 로컬 상태 업데이트
                                          });
                                        },
                                        decoration: InputDecoration(
                                          // 1. 호버링 텍스트 제거
                                          hintText:
                                              _titleController.text.isEmpty
                                                  ? '여기에 프로젝트 제목을 입력해 주세요'
                                                  : null,
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14, // 힌트 텍스트 크기
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                50), // 모서리 둥글게
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            borderSide: BorderSide(
                                                width: 0.0), // 기본 외곽선
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            borderSide: BorderSide(
                                                width: 0.0), // 포커스 시 외곽선
                                          ),
                                          fillColor: tempColor, // 배경색 설정
                                          filled: true, // 배경색 활성화
                                        ),
                                        // 2. 디폴트 텍스트 표시
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 255, 255, 255), // 텍스트 색상
                                          fontSize: 16, // 텍스트 크기
                                          fontWeight: FontWeight.bold, // 텍스트 두께
                                        ),
                                        textAlign:
                                            TextAlign.center, // 3. 텍스트 가운데 정렬
                                      ),

                                      SizedBox(height: 16),
                                      // ColorPicker (색상 상태 관리)
                                      ColorPicker(
                                        pickerColor: tempColor,
                                        onColorChanged: (color) {
                                          setStateDialog(() {
                                            tempColor = color; // 색상 변경
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // 다이얼로그 닫기
                                    },
                                    child: Text('취소'),
                                  ),
                                  ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                tempColor ??
                                                    const Color.fromARGB(
                                                        255, 65, 65, 65))),
                                    onPressed: () {
                                      Navigator.of(context).pop(
                                        NewLabel(
                                            tempColor, textController.text),
                                      );
                                      // 다이얼로그 닫기
                                    },
                                    child: Text('확인'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      if (newLabel == null) {
                        return;
                      }
                      setStateDialog(() {
                        _newProjectLabelColor = newLabel.color; // 최종 색상 업데이트
                        _titleController.text = newLabel.label; // 부모 상태 제목 업데이트
                      });
                    },
                    child: // 겹쳐진 위젯 구조로 컨테이너와 텍스트 관리
                        Stack(
                      alignment: Alignment.center,
                      children: [
                        // 배경 색상 컨테이너
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _newProjectLabelColor,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: _newProjectLabelColor),
                          ),
                        ),
                        // 텍스트 (TextField와 동기화)
                        Text(
                          _titleController.text.isEmpty
                              ? '프로젝트 제목'
                              : _titleController.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '프로젝트 내용',
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14, // 힌트 텍스트 크기
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                        borderSide: BorderSide(
                          color: _newProjectLabelColor, // 비활성화 상태 보더 색상
                          width: 1.0, // 비활성화 상태 보더 두께
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                        borderSide: BorderSide(
                          color: _newProjectLabelColor, // 포커스 상태 보더 색상
                          width: 2.0, // 포커스 상태 보더 두께
                        ),
                      ),
                    ),
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _clientController,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: '클라이언트',
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14, // 힌트 텍스트 크기
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                        borderSide: BorderSide(
                          color: _newProjectLabelColor, // 비활성화 상태 보더 색상
                          width: 1.0, // 비활성화 상태 보더 두께
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                        borderSide: BorderSide(
                          color: _newProjectLabelColor, // 포커스 상태 보더 색상
                          width: 2.0, // 포커스 상태 보더 두께
                        ),
                      ),
                    ),
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _revenueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            labelText: '프로젝트 수익',
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14, // 힌트 텍스트 크기
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(20), // 기본 보더 둥글게
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(20), // 비활성화 상태 모서리 둥글게
                              borderSide: BorderSide(
                                color: _newProjectLabelColor, // 비활성화 상태 보더 색상
                                width: 1.0, // 비활성화 상태 보더 두께
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(20), // 포커스 상태 모서리 둥글게
                              borderSide: BorderSide(
                                color: _newProjectLabelColor, // 포커스 상태 보더 색상
                                width: 2.0, // 포커스 상태 보더 두께
                              ),
                            ),
                            contentPadding:
                                EdgeInsets.fromLTRB(20, 8, 20, 8), // 내부 패딩
                          ),
                          onChanged: (value) {
                            String newValue = value.replaceAll(',', '');
                            if (int.tryParse(newValue) != null) {
                              setStateDialog(() {
                                _revenueController.text = currencyFormatter
                                    .format(int.parse(newValue));
                                _revenueController.selection =
                                    TextSelection.collapsed(
                                  offset: _revenueController.text.length,
                                );
                              });
                            }
                          },
                          textAlign: TextAlign.right, // 입력 텍스트 오른쪽 정렬
                        ),
                      ),
                      SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        onChanged: (value) {
                          setStateDialog(() {
                            _selectedCurrency = value!;
                          });
                        },
                        items: _currencies.map((currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearFields();
              },
              child: Text('취소'),
            ),
            GestureDetector(
              onTap: () {
                if (!_isSaveButtonEnabled) {
                  // 하단 팝업 표시
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent, // 배경 투명화
                    builder: (context) {
                      // 1초 후 팝업 닫기
                      Future.delayed(Duration(milliseconds: 1300), () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(); // 팝업 닫기
                        }
                      });
                      return Container(
                        margin: EdgeInsets.all(30),
                        padding: EdgeInsets.fromLTRB(30, 16, 30, 16), // 내부 여백
                        decoration: BoxDecoration(
                          color: Colors.white, // 팝업 배경색
                          borderRadius: BorderRadius.circular(30), // 둥근 모서리
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, -2), // 그림자 위치
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // 팝업 높이를 내용에 맞게 최소화
                          children: [
                            Text(
                              '프로젝트 제목을 입력해 주세요.',
                              textAlign: TextAlign.center, // 텍스트 정 가운데 정렬
                              style: TextStyle(fontSize: 16), // 텍스트 스타일 설정
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
              child: ElevatedButton(
                onPressed: _isSaveButtonEnabled
                    ? () {
                        Navigator.of(context).pop();
                        _saveProject();
                      }
                    : null, // 비활성화 상태 처리
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey; // 비활성화 상태 색상
                    }
                    return _newProjectLabelColor; // 활성화 상태 색상
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.white; // 비활성화 상태 텍스트 색상
                    }
                    return Colors.white; // 활성화 상태 텍스트 색상
                  }),
                ),
                child: Text(
                  '저장',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
