import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './login_screen.dart';
import './business_profile_screen.dart';

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

  void _showNoticeBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoticeBoardScreen()),
    );
  }

  void _showFAQ() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQScreen()),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  void _showContactUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactUsScreen()),
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
                padding: const EdgeInsets.all(24),
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
              const Divider(),

              // 메뉴 섹션
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '계정 관리',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // 계정 관리 메뉴
              _buildMenuItem(
                icon: Icons.business,
                title: '사업자 정보 관리',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusinessProfileScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: '로그아웃',
                onTap: _logOut,
                isDestructive: true,
              ),

              const Divider(height: 32),

              // 앱 정보 섹션
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '앱 정보',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // 앱 정보 메뉴
              _buildMenuItem(
                icon: Icons.announcement,
                title: '공지사항',
                onTap: _showNoticeBoard,
              ),
              _buildMenuItem(
                icon: Icons.help,
                title: '자주 묻는 질문',
                onTap: _showFAQ,
              ),
              _buildMenuItem(
                icon: Icons.description,
                title: '이용약관',
                onTap: _showTermsOfService,
              ),
              _buildMenuItem(
                icon: Icons.mail,
                title: '문의하기',
                onTap: _showContactUs,
              ),

              const SizedBox(height: 16),

              // 앱 버전
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(  // Material 위젯 추가
      color: Colors.transparent,  // 배경색을 투명으로 설정
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isDestructive ? Colors.red : Colors.indigo,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDestructive ? Colors.red : Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 공지사항 화면
class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 공지사항 예시 데이터
    final List<Map<String, dynamic>> notices = [
      {
        'title': '서비스 업데이트 안내',
        'date': '2025.02.20',
        'content': '음성 인식 기능이 개선되었습니다. 이제 더 정확한 인식이 가능합니다.'
      },
      {
        'title': '베트남어 번역 지원 확대',
        'date': '2025.02.15',
        'content': '베트남어 번역 지원 항목이 추가되었습니다.'
      },
      {
        'title': '서비스 오픈 안내',
        'date': '2025.02.01',
        'content': 'Voice Contract 서비스가 정식 오픈하였습니다.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: ListView.separated(
        itemCount: notices.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notice = notices[index];
          return ExpansionTile(
            title: Text(
              notice['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              notice['date'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  notice['content'],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 자주 묻는 질문 화면
class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FAQ 예시 데이터
    final List<Map<String, String>> faqs = [
      {
        'question': '어떤 언어로 번역이 가능한가요?',
        'answer': '현재 한국어, 영어, 베트남어 번역을 지원하고 있습니다. 추후 더 많은 언어를 추가할 예정입니다.'
      },
      {
        'question': '계약서 작성 후 수정이 가능한가요?',
        'answer': '네, 작성내역 메뉴에서 이전에 작성한 계약서를 확인하고 수정할 수 있습니다.'
      },
      {
        'question': '음성 인식이 잘 되지 않을 때는 어떻게 해야 하나요?',
        'answer': '조용한 환경에서 천천히 또박또박 말씀해주시면 인식률이 향상됩니다. 그래도 인식이 안 될 경우 직접 텍스트를 입력하실 수도 있습니다.'
      },
      {
        'question': '작성한 계약서를 인쇄할 수 있나요?',
        'answer': '네, 작성이 완료된 계약서는 PDF로 저장하여 인쇄하거나 이메일로 공유할 수 있습니다.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('자주 묻는 질문'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: ListView.separated(
        itemCount: faqs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return ExpansionTile(
            title: Text(
              faq['question']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 이용약관 화면
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '이용약관',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '제1조 (목적)\n\n'
                  '이 약관은 에이아이에스 주식회사(이하 "회사")가 제공하는 Voice Contract 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'
                  '제2조 (정의)\n\n'
                  '1. "서비스"란 회사가 제공하는 근로계약서 작성 및 번역 서비스를 의미합니다.\n'
                  '2. "이용자"란 이 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.\n\n'
                  '제3조 (약관의 효력 및 변경)\n\n'
                  '1. 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.\n'
                  '2. 회사는 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 서비스 내에 공지함으로써 효력이 발생합니다.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 문의하기 화면
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '서비스 이용 중 궁금하신 점이나 불편한 사항이 있으신가요?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // 이메일 문의
            _buildContactMethod(
              icon: Icons.email,
              title: '이메일 문의',
              detail: 'support@voicecontract.com',
            ),
            const SizedBox(height: 16),
            // 전화 문의
            _buildContactMethod(
              icon: Icons.phone,
              title: '전화 문의',
              detail: '02-123-4567 (평일 09:00 ~ 18:00)',
            ),
            const SizedBox(height: 16),
            // 채팅 문의
            _buildContactMethod(
              icon: Icons.chat,
              title: '채팅 문의',
              detail: '앱 내 채팅 상담 (평일 09:00 ~ 18:00)',
            ),
            const SizedBox(height: 32),
            // 문의하기 폼
            const Text(
              '문의하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('문의가 접수되었습니다. 빠른 시일 내에 답변 드리겠습니다.'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
                child: const Text('문의하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}