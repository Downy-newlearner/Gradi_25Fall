import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter/material.dart'; // debugPrint

void appLog(String message) {
  if (!kDebugMode) return; // 디버그 모드가 아니면 바로 종료

  debugPrint('[APP] $message');
}
