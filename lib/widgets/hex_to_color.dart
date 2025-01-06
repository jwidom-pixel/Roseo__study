//파이어베이스에 저장된 색상 코드 변환
import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  if (hex.isEmpty || !hex.startsWith('#') || (hex.length != 7 && hex.length != 9)) {
    debugPrint('Invalid hex color format: $hex');
    return const Color(0xFF000000); // 기본값 반환
  }
  
  final hexCode = hex.replaceFirst('#', '');
  final colorValue = int.parse(hexCode, radix: 16);
  
  if (hexCode.length == 6) {
    // #RRGGBB 형식인 경우
    return Color(0xFF000000 | colorValue); // 알파 채널 추가
  } else if (hexCode.length == 8) {
    // #AARRGGBB 형식인 경우
    return Color(colorValue);
  } else {
    debugPrint('Unhandled hex color format: $hex');
    return const Color(0xFF000000);
  }
}