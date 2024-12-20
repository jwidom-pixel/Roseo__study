import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProjectsPage extends StatefulWidget {
  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Map<String, dynamic>> projects = [];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  // 서버에서 프로젝트 데이터를 불러오는 함수
  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('https://your-server-api.com/projects'));
      if (response.statusCode == 200) {
        setState(() {
          projects = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 서버에 새 프로젝트 데이터를 추가하는 함수
  Future<void> _addProject(Map<String, dynamic> newProject) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-server-api.com/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newProject),
      );

      if (response.statusCode == 201) {
        _fetchProjects(); // 새로고침
      } else {
        throw Exception('Failed to add project');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // 입력 다이얼로그를 띄우는 함수
  void _showAddProjectDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController clientController = TextEditingController();
    final TextEditingController costController = TextEditingController();

    Color selectedColor = Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('새 프로젝트 추가'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: '프로젝트 제목'),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(labelText: '마감 날짜 (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: '내용'),
                ),
                TextField(
                  controller: clientController,
                  decoration: InputDecoration(labelText: '클라이언트'),
                ),
                TextField(
                  controller: costController,
                  decoration: InputDecoration(labelText: '외주비'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('라벨 색상'),
                    DropdownButton<Color>(
                      value: selectedColor,
                      items: [
                        Colors.purple,
                        Colors.red,
                        Colors.orange,
                        Colors.green,
                        Colors.blue,
                      ].map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Container(
                            width: 20,
                            height: 20,
                            color: color,
                          ),
                        );
                      }).toList(),
                      onChanged: (color) {
                        setState(() {
                          selectedColor = color!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final newProject = {
                  'title': titleController.text,
                  'date': dateController.text,
                  'description': descriptionController.text,
                  'client': clientController.text,
                  'cost': costController.text,
                  'color': selectedColor.value.toString(),
                };
                _addProject(newProject);
                Navigator.pop(context);
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse(project['color'])),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project['title'],
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            project['date'],
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            project['description'],
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                project['client'],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                project['cost'],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('프로젝트 관리', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: projects.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return _buildProjectCard(projects[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        backgroundColor: Colors.black,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
