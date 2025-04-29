import 'package:flutter/material.dart';

/// 화면 이동 애니메이션을 위한 유틸리티 클래스
class NavigationUtils {
  /// 수평 슬라이드 애니메이션으로 화면 이동
  ///
  /// [context] - 현재 컨텍스트
  /// [destination] - 이동할 목적지 위젯
  /// [isFromLeft] - 왼쪽에서 시작할지 여부 (true: 왼쪽에서 슬라이드, false: 오른쪽에서 슬라이드)
  /// [duration] - 애니메이션 지속 시간
  static void slideHorizontal({
    required BuildContext context,
    required Widget destination,
    bool isFromLeft = true,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final begin = Offset(isFromLeft ? -1.0 : 1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  /// 수직 슬라이드 애니메이션으로 화면 이동
  ///
  /// [context] - 현재 컨텍스트
  /// [destination] - 이동할 목적지 위젯
  /// [isFromBottom] - 아래에서 시작할지 여부 (true: 아래에서 슬라이드, false: 위에서 슬라이드)
  /// [duration] - 애니메이션 지속 시간
  /// [withFade] - 페이드 효과 추가 여부
  static void slideVertical({
    required BuildContext context,
    required Widget destination,
    bool isFromBottom = true,
    Duration duration = const Duration(milliseconds: 300),
    bool withFade = true,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final begin = Offset(0.0, isFromBottom ? 1.0 : -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          if (withFade) {
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          } else {
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          }
        },
        transitionDuration: duration,
      ),
    );
  }
}