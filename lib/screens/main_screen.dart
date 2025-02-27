import 'package:flutter/material.dart';
import './worker_info_screen.dart';
import './language_selection_screen.dart';
import './profile_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(  // 드로어 추가
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Text(
                'Voice Contract',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('프로필'),
              onTap: () {
                // 프로필 화면으로 이동
                Navigator.pop(context);  // 드로어 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            // 다른 메뉴 항목들 추가 가능
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(  // leading 속성 추가
          icon: Icon(Icons.settings, color: Colors.indigo),
          onPressed: () {
            // 프로필 화면으로 바로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
        ),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Voice Contract',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [

          // 상단 배너/설명 영역
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.indigo, // 배경색을 인디고로 변경

            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.white, size: 24), // 아이콘 색상을 흰색으로 변경
                    const SizedBox(width: 12),
                    const Text(
                      '근로계약서 간편 작성',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // 텍스트 색상을 흰색으로 변경
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '음성 인식 기술을 통해 한국어로 말하면 영어와 베트남어로 자동 번역되는 편리한 근로계약서 작성 서비스입니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9), // 설명 텍스트도 흰색으로 변경 (약간 투명도 추가)
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 메뉴 버튼 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(
                    context,
                    title: '근로계약서 작성',
                    subtitle: '음성 인식으로 간편하게 작성하기',
                    icon: Icons.edit_document,
                    color: Colors.indigo,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkerInfoScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildMenuButton(
                    context,
                    title: '작성내역 확인',
                    subtitle: '저장된 근로계약서 내역 보기',
                    icon: Icons.history,
                    color: Colors.teal,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionScreen(isViewMode: true),
                        ),
                      );
                    },
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
                  ),
                ),
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
        ],
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}