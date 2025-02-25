import 'package:flutter/material.dart';

class WavePulseLoading extends StatefulWidget {
  final String? message;
  final Color? baseColor;

  const WavePulseLoading({
    Key? key,
    this.message = '음성 번역 중',
    this.baseColor = Colors.blue,
  }) : super(key: key);

  @override
  _WavePulseLoadingState createState() => _WavePulseLoadingState();
}

class _WavePulseLoadingState extends State<WavePulseLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 흐릿한 배경 (약간의 흰색 톤)
        Container(
          color: Colors.grey.withOpacity(0.5),
        ),

        // 파동 효과 및 중앙 컨텐츠
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 첫 번째 파동 (파란색 계열)
                  Container(
                    width: 200 * _animation.value,
                    height: 200 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(
                          (1.0 - _animation.value).clamp(0.0, 1.0) * 0.2
                      ),
                    ),
                  ),
                  // 두 번째 파동 (파란색 계열)
                  Container(
                    width: 150 * _animation.value,
                    height: 150 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(
                          (1.0 - _animation.value).clamp(0.0, 1.0) * 0.4
                      ),
                    ),
                  ),

                  // 중앙 내용 배경 추가 (약간 흰색 배경)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.g_translate,
                          color: Colors.blue,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.message!,
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬

                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 14,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// 로딩 오버레이를 쉽게 보여주고 숨길 수 있는 확장 함수
extension LoadingOverlay on BuildContext {
  void showWavePulseLoading({String? message, Color? baseColor}) {
    showDialog(
      context: this,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => WavePulseLoading(
        message: message,
        baseColor: baseColor,
      ),
    );
  }

  void hideWavePulseLoading() {
    Navigator.of(this, rootNavigator: true).pop();
  }
}