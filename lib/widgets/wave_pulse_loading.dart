import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavePulseLoading extends StatefulWidget {
  final String? message;
  final Color? baseColor;

  const WavePulseLoading({
    Key? key,
    this.message = '음성 번역 중',
    this.baseColor = const Color(0xFF3F51B5), // 인디고 색상 사용
  }) : super(key: key);

  @override
  _WavePulseLoadingState createState() => _WavePulseLoadingState();
}

class _WavePulseLoadingState extends State<WavePulseLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _barHeights;
  final int _barCount = 7; // 음성 파형 막대 개수

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // 막대 높이 초기화 (랜덤 값으로)
    _initializeBarHeights();

    // 애니메이션 리스너 추가
    _controller.addListener(_updateBarHeights);
  }

  void _initializeBarHeights() {
    final random = math.Random();
    _barHeights = List.generate(_barCount, (_) => random.nextDouble() * 0.7 + 0.3);
  }

  void _updateBarHeights() {
    if (mounted) {
      setState(() {
        final random = math.Random();
        for (var i = 0; i < _barCount; i++) {
          // 애니메이션 진행 상태에 따라 막대 높이 업데이트
          if (random.nextDouble() > 0.7) {
            _barHeights[i] = random.nextDouble() * 0.7 + 0.3;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color waveColor = widget.baseColor ?? const Color(0xFF3F51B5);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 어두운 배경 (약간 투명하게)
        Container(
          color: Colors.black.withOpacity(0.3),
        ),

        // 중앙 컨텐츠
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘
                Icon(
                  Icons.mic, // 음성 인식에 더 적합한 아이콘
                  color: waveColor,
                  size: 40,
                ),
                const SizedBox(height: 20),

                // 음성 파형 효과
                SizedBox(
                  height: 60,
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      _barCount,
                          (index) => AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return _buildBar(index, waveColor);
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 메시지
                Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 8),

                // 부가 설명
                Text(
                  '잠시만 기다려주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(int index, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 15,
      height: 60 * _barHeights[index],
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(3),
      ),
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