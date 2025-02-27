import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './business_info_screen.dart';
import './main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  GoogleSignInAccount? _currentUser;
  late StreamSubscription<GoogleSignInAccount?> _subscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
        SnackBar(content: Text('로그인 중 오류가 발생했습니다: ${e.toString()}')),
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
      body: SafeArea(
        child: Column(
          children: [
            // 상단 로고 영역
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 72,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Voice Contract',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NanumGothic',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        '음성 인식 기술을 통한 다국어 근로계약서 작성 서비스',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          fontFamily: 'NanumGothic',
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '서비스 이용을 위해 로그인해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        fontFamily: 'NanumGothic',
                      ),
                    ),
                    const SizedBox(height: 40),
                    _isLoading
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                    )
                        : InkWell(
                      onTap: _handleSignIn,
                      child: Image.asset(
                        'assets/google_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.indigo[50],
              child: Column(
                children: [
                  Icon(Icons.lightbulb, size: 20, color: Colors.indigo[300]),
                  const SizedBox(height: 8),
                  Text(
                    '2025 Voice Contract. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo[400],
                      fontFamily: 'NanumGothic',
                    ),
                  ),
                  Text(
                    'Made with by 에이아이에스(주)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo[400],
                      fontFamily: 'NanumGothic',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}