import 'package:flutter/material.dart';
import 'package:contact/screens/worker_info_screen.dart';
import 'package:contact/screens/language_selection_screen.dart';
import 'package:contact/screens/profile/profile_screen.dart';
import 'package:contact/screens/utils/navigation_utils.dart';
import 'package:animate_do/animate_do.dart'; // 애니메이션 효과를 위한 패키지 추가

class MainScreen extends StatefulWidget { // StatefulWidget으로 변경
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin { // TickerProviderStateMixin 추가
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward(); // 애니메이션 시작
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildBanner(),
          Expanded(
            child: _buildMenuButtons(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.settings, color: Colors.indigo),
        onPressed: () {
          NavigationUtils.slideHorizontal(
            context: context,
            destination: const ProfileScreen(),
            isFromLeft: true,
          );
        },
      ),
      elevation: 0,
      centerTitle: true,
      title: FadeIn( // 애니메이션 적용
        child: const Text(
          '말로하는 계약서',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w900, // 더 굵게
            fontSize: 24, // 조금 더 크게
            letterSpacing: 1.2, // 자간 조정
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  // 상단 배너 위젯
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient( // 그라데이션 배경
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), // 상하 패딩 증가
      child: FadeInDown( // 애니메이션 적용
        delay: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Colors.white, size: 28), // 아이콘 변경
                const SizedBox(width: 12),
                Text(
                  '음성으로 만드는 간편 계약', // 제목 변경
                  style: const TextStyle(
                    fontSize: 24, // 크기 증가
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '한국어로 말하면 영어와 베트남어로 자동 번역! 복잡한 계약서 작성, 이제 음성으로 쉽고 빠르게 해결하세요.', // 설명 변경
              style: TextStyle(
                fontSize: 16, // 크기 증가
                color: Colors.white.withOpacity(0.9),
                height: 1.6, // 줄 간격 조정
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 메뉴 버튼 영역 위젯
  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInLeft( // 애니메이션 적용
            delay: const Duration(milliseconds: 200),
            child: _buildMenuButton(
              context,
              title: '새로운 계약서 작성', // 제목 변경
              subtitle: '음성으로 간편하게 시작하세요', // 부제목 변경
              icon: Icons.mic, // 아이콘 변경
              color: Colors.indigo,
              onPressed: () {
                NavigationUtils.slideVertical(
                  context: context,
                  destination: const WorkerInfoScreen(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          FadeInRight( // 애니메이션 적용
            delay: const Duration(milliseconds: 400),
            child: _buildMenuButton(
              context,
              title: '기존 계약서 조회', // 제목 변경
              subtitle: '작성했던 계약서 목록을 확인하세요', // 부제목 변경
              icon: Icons.library_books, // 아이콘 변경
              color: Colors.teal,
              onPressed: () {
                NavigationUtils.slideVertical(
                  context: context,
                  destination: const LanguageSelectionScreen(isViewMode: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 버튼 위젯
  Widget _buildMenuButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return InkWell( // InkWell로 변경하여 onTap 효과 추가
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20), // 패딩 조정
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15), // 둥글기 증가
          boxShadow: [ // 그림자 추가
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2), // 색상 변경
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20, // 크기 증가
                      fontWeight: FontWeight.w900,
                      color: color, // 색상 변경
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700], // 색상 변경
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20, // 크기 증가
            ),
          ],
        ),
      ),
    );
  }

  // 하단 푸터 위젯
  Widget _buildFooter() {
    return FadeInUp( // 애니메이션 적용
      delay: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20), // 패딩 조정
        decoration: BoxDecoration(
          color: Colors.indigo[50],
          border: Border(top: BorderSide(color: Colors.indigo[100]!, width: 1)), // 테두리 추가
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
          children: [
            Icon(Icons.copyright, size: 20, color: Colors.indigo[400]), // 아이콘 변경
            const SizedBox(height: 8),
            Text(
              'ⓒ 2024 Voice Contract. All rights reserved.', // 연도 변경
              style: TextStyle(
                fontSize: 14, // 크기 증가
                color: Colors.indigo[600], // 색상 변경
                fontWeight: FontWeight.w500, // 굵기 조정
              ),
              textAlign: TextAlign.center, // 텍스트 가운데 정렬
            ),
            const SizedBox(height: 4),
            Text(
              'Made with by 에이아이에스(주)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.indigo[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}