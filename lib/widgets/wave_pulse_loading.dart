import 'package:flutter/material.dart';

class WavePulseLoading extends StatefulWidget {
  final String? message;
  final Color? baseColor;

  const WavePulseLoading({
    Key? key,
    this.message = '음성 번역 중',
    this.baseColor = const Color(0xFF2196F3), // 더 강한 파란색 사용
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
    final Color waveColor = widget.baseColor ?? Colors.blue;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 어두운 배경으로 변경하여 파동 효과가 더 잘 보이게 함
        Container(
          color: Colors.black.withOpacity(0.3),
        ),

        // 파동 효과 및 중앙 컨텐츠
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 세 번째 파동 (더 큰 파동 추가)
                  Container(
                    width: 250 * _animation.value,
                    height: 250 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: waveColor.withOpacity(
                          (1.0 - _animation.value).clamp(0.0, 1.0) * 0.3
                      ),
                    ),
                  ),

                  // 두 번째 파동 (더 선명하게 만듦)
                  Container(
                    width: 200 * _animation.value,
                    height: 200 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: waveColor.withOpacity(
                          (1.0 - _animation.value).clamp(0.0, 1.0) * 0.5
                      ),
                    ),
                  ),

                  // 첫 번째 파동 (더 선명하게 만듦)
                  Container(
                    width: 150 * _animation.value,
                    height: 150 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: waveColor.withOpacity(
                          (1.0 - _animation.value).clamp(0.0, 1.0) * 0.7
                      ),
                    ),
                  ),

                  // 중앙 내용 배경 (더 불투명하게 만듦)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.85),
                      // 테두리 추가하여 더 잘 보이게 함
                      border: Border.all(
                        color: waveColor.withOpacity(0.8),
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.g_translate,
                          color: waveColor,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: waveColor.withBlue(waveColor.blue - 40),
                            fontWeight: FontWeight.bold, // 텍스트 굵게 표시
                            fontSize: 12,
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