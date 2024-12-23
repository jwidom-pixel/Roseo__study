import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'calendar/calendar_page.dart';

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
