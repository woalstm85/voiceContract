import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import './business_info_screen.dart';
import './main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  GoogleSignInAccount? _currentUser;
  late StreamSubscription<GoogleSignInAccount?> _subscription;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();

    // 로그인 상태 변화 감지
    _subscription = _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
        });
      }
      if (account != null) {
        _saveUserInfo(account);
      }
    });
    // 자동 로그인 시도 (선택적)
    _googleSignIn.signInSilently();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo(GoogleSignInAccount account) async {
    final prefs = await SharedPreferences.getInstance();

    // 현재 로그인한 이메일로 사업자 정보 키 생성
    String businessInfoKey = 'businessNumber_${account.email}';

    // 기존에 저장된 해당 이메일의 사업자 정보 확인
    String? savedBusinessNumber = prefs.getString(businessInfoKey);

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', account.email);
    await prefs.setString('userName', account.displayName ?? '');
    await prefs.setString('userPhoto', account.photoUrl ?? '');

    // 사업자 정보가 없으면 사업자 정보 입력 화면으로
    if (savedBusinessNumber == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BusinessInfoScreen(),
        ),
      );
    } else {
      // 사업자 정보가 있으면 메인 화면으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _googleSignIn.signIn();
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 로고 영역
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo, Colors.indigoAccent],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 1,
                              )
                            ]
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 이미지 위젯을 사용하여 마이크 아이콘 표시
                            Image.asset(
                              'assets/app_icon.png', // 이미지 경로는 실제 파일 위치에 맞게 조정하세요
                              width: 80,
                              height: 80,

                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeIn(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        '음성계약', // 앱 이름 변경
                        style: TextStyle(
                          fontSize: 36, // 폰트 크기 증가
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5, // 자간 조정
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          '말하면 자동으로 번역되는\n다국어 근로계약서 작성 서비스',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 로그인 영역
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(32.0),

                child: FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '서비스 이용을 위해 로그인해주세요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? Container(
                        width: 250,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                            strokeWidth: 3,
                          ),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),

                        ),
                        child: SizedBox(
                          width: 250,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google_login_icon.png',
                                height: 30,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Google 계정으로 로그인',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 하단 정보
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copyright, size: 16, color: Colors.indigo[400]),
                        const SizedBox(width: 8),
                        Text(
                          '2025 Voice Contract. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Made with by 에이아이에스(주)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}