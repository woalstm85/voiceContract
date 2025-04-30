import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contact/screens/login_screen.dart';
import 'package:contact/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // 애니메이션이 자연스럽게 보이도록 최소 지연 시간 설정
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 로그인 상태 체크
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    // 적절한 화면으로 네비게이션
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => isLoggedIn ? const MainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F51B5), // indigo 색상
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 (애니메이션 효과 적용)
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Image.asset(
                'assets/splash_icon.png',
                width: 120,
                height: 120,
              ),
            ),

            const SizedBox(height: 24),

            // 앱 이름 텍스트
            FadeIn(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 800),
              child: const Text(
                '근로계약서 도우미',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 슬로건 텍스트
            FadeIn(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 800),
              child: const Text(
                '외국인 근로자를 위한 쉬운 계약서 작성',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // 로딩 인디케이터
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}