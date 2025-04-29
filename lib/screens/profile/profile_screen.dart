import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contact/screens/login_screen.dart';
import 'package:contact/screens/business_profile_screen.dart';
import 'package:contact/screens/profile/support/faq_screen.dart';
import 'package:contact/screens/profile/support/notice_screen.dart';
import 'package:contact/screens/profile/support/terms_screen.dart';
import 'package:contact/screens/profile/support/contact_screen.dart';
import 'package:contact/screens/profile/support/support_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  String _userName = '';
  String _userEmail = '';
  String _userPhoto = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '사용자';
      _userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      _userPhoto = prefs.getString('userPhoto') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _logOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // Google 로그아웃 추가
              await _googleSignIn.signOut();

              // 로그아웃 처리
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('userName');
              await prefs.remove('userEmail');
              await prefs.remove('userPhoto');
              // await prefs.remove('businessNumber');

              // 로그인 화면으로 이동
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.indigo,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 정보 헤더
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 프로필 이미지
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage: _userPhoto.isNotEmpty ? NetworkImage(_userPhoto) : null,
                      child: _userPhoto.isEmpty
                          ? Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    // 이름 및 이메일
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userEmail,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 계정 관리 섹션
              _buildSectionHeader('계정 관리'),

              SettingsMenuItem(
                icon: Icons.business,
                title: '사업자 정보 관리',
                description: '사업자 정보를 등록하고 관리합니다',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusinessProfileScreen()),
                  );
                },
              ),

              SettingsMenuItem(
                icon: Icons.logout,
                title: '로그아웃',
                description: '계정에서 안전하게 로그아웃합니다',

                onTap: _logOut,
                isDestructive: true,
              ),

              const SizedBox(height: 8),

              // 앱 정보 섹션
              _buildSectionHeader('앱 정보'),

              SettingsMenuItem(
                icon: Icons.announcement,
                title: '공지사항',
                description: '서비스 업데이트 및 주요 공지를 확인',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NoticeScreen()),
                  );
                },
              ),

              SettingsMenuItem(
                icon: Icons.help,
                title: '자주 묻는 질문',
                description: '서비스 이용 관련 자주 묻는 질문을 확인',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FAQScreen()),
                  );
                },
              ),

              SettingsMenuItem(
                icon: Icons.description,
                title: '이용약관',
                description: '서비스 이용 약관을 확인',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsScreen()),
                  );
                },
              ),

              SettingsMenuItem(
                icon: Icons.mail,
                title: '문의하기',
                description: '고객 지원팀에 문의',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactScreen()),
                  );
                },
              ),

              // 앱 버전
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    '버전 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}