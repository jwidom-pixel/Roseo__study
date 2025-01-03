import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

// 모델 클래스 생성 (그룹화)
class EditLabel {
  final Color color;
  final String label;

  EditLabel(this.color, this.label);
}
//

// 컬러 변환 헬퍼 메서드
Color parseColor(String colorString) {
  return Color(
    int.parse(colorString.replaceFirst('#', ''), radix: 16),
  );
}

class EditProjectPage extends StatefulWidget {
  final DocumentSnapshot project;

  EditProjectPage({required this.project});

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _clientController;
  late TextEditingController _revenueController;

  String _selectedCategory = '';
  String _selectedCurrency = '';
  Color _labelColor = const Color.fromARGB(255, 65, 65, 65);

  final List<String> _categories = ['개인', '연재', '외주', '제작', '행사'];
  final List<String> _currencies = ['원', '\$', '€', '¥', '元'];

  @override
  void initState() {
    super.initState();

    final data = widget.project.data() as Map<String, dynamic>;

    _titleController = TextEditingController(text: data['title']);
    _descriptionController = TextEditingController(text: data['description']);
    _clientController = TextEditingController(text: data['client']);
    _revenueController = TextEditingController(
        text: data['revenue'] != null
            ? NumberFormat('#,###').format(data['revenue'])
            : '0');
    _selectedCategory = data['category'] ?? '개인';
    _selectedCurrency = data['currency'] ?? '원';
    _labelColor = parseColor(data['labelColor']!);
    ; // 라벨 컬러 변환
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clientController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('프로젝트 편집'),
          actions: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('삭제 확인'),
                    content: Text('이 프로젝트를 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirm ?? false) {
                  await FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.project.id)
                      .delete();
                  Navigator.of(context).pop();
                }
              },
            )
          ],
        ),
        body: SafeArea(
          child: Container(
            height: double.infinity,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 프로젝트 성격 선택
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 16.0,
                        children: _categories.map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(50), // 모서리를 둥글게 설정
                            ),
                            selectedColor: _labelColor,
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : _labelColor,
                            ),
                            backgroundColor: Colors.grey[200],
                            showCheckmark: false, // 체크 아이콘 제거
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),

                      // 프로젝트 제목
                      GestureDetector(
                        onTap: () async {
                          final editLabel = await showDialog<EditLabel>(
                            context: context,
                            builder: (context) {
                              Color tempColor = _labelColor; // 다이얼로그에서만 사용하는 색상
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
                                                borderRadius:
                                                    BorderRadius.circular(
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
                                              fontWeight:
                                                  FontWeight.bold, // 텍스트 두께
                                            ),
                                            textAlign: TextAlign
                                                .center, // 3. 텍스트 가운데 정렬
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
                                          Navigator.of(context)
                                              .pop(); // 다이얼로그 닫기
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
                                            EditLabel(
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

                          if (editLabel == null) {
                            return;
                          }
                          setState(() {
                            _labelColor = editLabel.color; // 최종 색상 업데이트
                            _titleController.text =
                                editLabel.label; // 부모 상태 제목 업데이트
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
                                color: _labelColor,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: _labelColor),
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
                      SizedBox(height: 30),

                      // 프로젝트 내용
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
                              color: _labelColor, // 비활성화 상태 보더 색상
                              width: 1.0, // 비활성화 상태 보더 두께
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                            borderSide: BorderSide(
                              color: _labelColor, // 포커스 상태 보더 색상
                              width: 2.0, // 포커스 상태 보더 두께
                            ),
                          ),
                        ),
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: 16),

                      // 클라이언트 입력
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
                              color: _labelColor, // 비활성화 상태 보더 색상
                              width: 1.0, // 비활성화 상태 보더 두께
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20), // 모서리 둥글게
                            borderSide: BorderSide(
                              color: _labelColor, // 포커스 상태 보더 색상
                              width: 2.0, // 포커스 상태 보더 두께
                            ),
                          ),
                        ),
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: 16),

                      // 수익 입력
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _revenueController,
                              keyboardType: TextInputType.number,
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
                                  borderRadius: BorderRadius.circular(
                                      20), // 비활성화 상태 모서리 둥글게
                                  borderSide: BorderSide(
                                    color: _labelColor, // 비활성화 상태 보더 색상
                                    width: 1.0, // 비활성화 상태 보더 두께
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      20), // 포커스 상태 모서리 둥글게
                                  borderSide: BorderSide(
                                    color: _labelColor, // 포커스 상태 보더 색상
                                    width: 2.0, // 포커스 상태 보더 두께
                                  ),
                                ),
                                contentPadding:
                                    EdgeInsets.fromLTRB(20, 8, 20, 8), // 내부 패딩
                              ),
                              onChanged: (value) {
                                String newValue = value.replaceAll(',', '');
                                if (int.tryParse(newValue) != null) {
                                  setState(() {
                                    _revenueController.text =
                                        NumberFormat('#,###')
                                            .format(int.parse(newValue));
                                    _revenueController.selection =
                                        TextSelection.collapsed(
                                      offset: _revenueController.text.length,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedCurrency,
                            onChanged: (value) {
                              setState(() {
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
                      SizedBox(height: 16),
                    ],
                  ),
                ),
                // 저장 버튼
                Positioned(
                  bottom: 16, // 화면 아래 16px
                  right: 16, // 화면 오른쪽 16px
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(widget.project.id)
                          .update({
                        'title': _titleController.text,
                        'description': _descriptionController.text,
                        'client': _clientController.text,
                        'revenue': int.tryParse(
                                _revenueController.text.replaceAll(',', '')) ??
                            0,
                        'currency': _selectedCurrency,
                        'category': _selectedCategory,
                        'labelColor':
                            '#${_labelColor.value.toRadixString(16).padLeft(8, '0')}',
                      });
                      Navigator.of(context).pop(); // 업데이트 후 이전 페이지로 돌아감
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _labelColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('저장', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
