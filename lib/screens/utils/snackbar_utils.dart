import 'package:flutter/material.dart';

/// 스낵바 표시 유틸리티 함수
void showSnackBar(BuildContext context, String message, {int seconds = 1}) {
  // 기존 스낵바 제거
  ScaffoldMessenger.of(context).removeCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: seconds),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
    ),
  );
}