import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ProjectsPage extends StatefulWidget {
  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _revenueController =
      TextEditingController(text: "0");

  String _selectedCategory = '개인';
  DateTime? _lastProjectDate;
  Color _labelColor = Color.fromARGB(255, 65, 65, 65); // Default label color
  Color _newProjectLabelColor = Color.fromARGB(255, 65, 65, 65);

  String _selectedCurrency = '원';

  final List<String> _categories = ['개인', '연재', '외주', '제작', '행사'];
  final List<String> _currencies = ['원', '\$', '€', '¥', '元'];

  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'ko_KR', symbol: '', decimalDigits: 0);

  Future<void> _saveProject() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트 제목을 입력하세요.')),
      );
      return;
    }

    final projectData = {
      'title': _titleController.text,
      'category': _selectedCategory,
      'lastProjectDate': _lastProjectDate?.toIso8601String() ?? '',
      'description': _descriptionController.text,
      'client': _clientController.text.isEmpty ? '없음' : _clientController.text,
      'revenue': int.tryParse(_revenueController.text.replaceAll(',', '')) ?? 0,
      'currency': _selectedCurrency,
      'labelColor':
          '#${_newProjectLabelColor.value.toRadixString(16).padLeft(8, '0')}',
    };

    try {
      await FirebaseFirestore.instance.collection('projects').add(projectData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트가 저장되었습니다.')),
      );
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트 저장에 실패했습니다: $e')),
      );
    }
  }

  void _clearFields() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _clientController.clear();
      _revenueController.text = "0";
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
        stream: FirebaseFirestore.instance.collection('projects').snapshots(),
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

          final projects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index].data() as Map<String, dynamic>;
              final labelColor = project['labelColor'] != null
                  ? Color(int.parse(project['labelColor']!.substring(1, 7),
                          radix: 16) +
                      0xFF000000)
                  : Colors.grey; // 기본 색상

              final lastDate = project['lastProjectDate'] != ''
                  ? DateTime.parse(project['lastProjectDate'])
                  : null;
              final daysRemaining = lastDate != null
                  ? lastDate.difference(DateTime.now()).inDays
                  : null;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                        color: labelColor, // 라벨 컬러 적용
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            project['title'] ?? '제목 없음',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (daysRemaining != null && daysRemaining >= 0)
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
                        project['description'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),

                    // Category, Client, Revenue Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
                          children: [
                            Chip(
                              backgroundColor: labelColor,
                              label: Text(
                                project['category'] ?? '',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12), // 텍스트 크기 축소
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4), // 패딩 축소
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(50), // 둥글게 설정
                              ),
                              side: BorderSide.none, // 테두리 제거
                            ),
                            SizedBox(width: 8), // 칩 간 간격
                            Chip(
                              backgroundColor: labelColor,
                              label: Text(
                                project['client'] ?? '',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12), // 텍스트 크기 축소
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4), // 패딩 축소
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              side: BorderSide.none, // 테두리 제거
                            ),
                            SizedBox(width: 8),
                            Chip(
                              backgroundColor: labelColor,
                              label: Text(
                                '${currencyFormatter.format(project['revenue'] ?? 0)} ${project['currency'] ?? ''}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12), // 텍스트 크기 축소
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4), // 패딩 축소
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              side: BorderSide.none, // 테두리 제거
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Center(child: Text('새 프로젝트 추가')),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '프로젝트 제목',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setStateDialog(() {}); // UI 업데이트
                  },
                ),
                SizedBox(height: 16),
                Text('프로젝트 성격', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categories.map((category) {
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        if (selected) {
                          setStateDialog(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      selectedColor: Color.fromARGB(255, 65, 65, 65),
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? Colors.white
                            : Colors.black,
                      ),
                      backgroundColor: Colors.grey[200],
                      showCheckmark: false, // 체크 아이콘 제거
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '프로젝트 내용',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _clientController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: '클라이언트',
                    border: OutlineInputBorder(),
                  ),
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
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          String newValue = value.replaceAll(',', '');
                          if (int.tryParse(newValue) != null) {
                            setStateDialog(() {
                              _revenueController.text =
                                  currencyFormatter.format(int.parse(newValue));
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
                SizedBox(height: 16),
                Text('라벨 색상', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              title: Text('라벨 색상 선택'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 50,
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color:
                                            _newProjectLabelColor, // 즉시 업데이트된 색상 적용
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: Colors.black54),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _titleController.text.isEmpty
                                              ? '프로젝트 제목'
                                              : _titleController.text,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    ColorPicker(
                                      pickerColor: _newProjectLabelColor,
                                      onColorChanged: (color) {
                                        setStateDialog(() {
                                          _newProjectLabelColor =
                                              color; // 즉시 UI 업데이트
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
                                  child: Text('확인'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _newProjectLabelColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black54),
                    ),
                    child: Center(
                      child: Text(
                        _titleController.text.isEmpty
                            ? '프로젝트 제목'
                            : _titleController.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveProject();
              },
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
