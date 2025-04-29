import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_list_screen.dart';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final bool isViewMode;

  const LanguageSelectionScreen({
    Key? key,
    this.isViewMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildLanguageButtons(context),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.white,
      title: FadeIn(
        child: const Text(
          '언어 선택',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: FadeInDown(
        delay: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildLanguageIcons(),
                const SizedBox(width: 12),
                Text(
                  '언어를 선택하세요',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '선택한 언어로 계약서를 확인하고, 음성 듣기 및 PDF 변환 기능을 사용할 수 있습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageIcons() {
    return SizedBox(
      width: 55,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 4,
            child: _buildHeaderFlagIcon('assets/images/korean_flag.png'), // 변경된 함수 호출
          ),
          Positioned(
            left: 16,
            bottom: 4,
            child: _buildHeaderFlagIcon('assets/images/usa_flag.png'), // 변경된 함수 호출
          ),
          Positioned(
            left: 32,
            bottom: 4,
            child: _buildHeaderFlagIcon('assets/images/vietnam_flag.png'), // 변경된 함수 호출
          ),
        ],
      ),
    );
  }

  // 상단 겹치는 국기 아이콘 위젯 (테두리 제거)
  Widget _buildHeaderFlagIcon(String imagePath) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 테두리 제거
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLanguageButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInLeft(
            delay: const Duration(milliseconds: 400),
            child: _buildLanguageButton(
              context,
              '한국어',
              'ko',
              Colors.indigo,
              'assets/images/korean_flag.png',
            ),
          ),
          const SizedBox(height: 20),
          FadeInRight(
            delay: const Duration(milliseconds: 600),
            child: _buildLanguageButton(
              context,
              '영어 (English)',
              'en',
              Colors.teal,
              'assets/images/usa_flag.png',
            ),
          ),
          const SizedBox(height: 20),
          FadeInLeft(
            delay: const Duration(milliseconds: 800),
            child: _buildLanguageButton(
              context,
              '베트남어 (Tiếng Việt)',
              'vi',
              Colors.deepPurple,
              'assets/images/vietnam_flag.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context,
      String label,
      String langCode,
      Color color,
      String flagImagePath,
      ) {
    return InkWell(
      onTap: () => _onLanguageSelected(context, langCode),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.5), // 기존 테두리 유지
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              child: Center(
                child: ClipOval(  // 기존처럼 둥글게 유지
                  child: Image.asset(
                    flagImagePath,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _onLanguageSelected(BuildContext context, String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    final contracts = prefs.getStringList('contracts') ?? [];

    if (contracts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장된 계약서가 없습니다'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    String flagImagePath = '';
    switch (langCode) {
      case 'ko':
        flagImagePath = 'assets/images/korean_flag.png';
        break;
      case 'en':
        flagImagePath = 'assets/images/usa_flag.png';
        break;
      case 'vi':
        flagImagePath = 'assets/images/vietnam_flag.png';
        break;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => WorkerListScreen(
          langCode: langCode,
          contracts: contracts.map((e) => json.decode(e)).toList(),
          flagImagePath: flagImagePath,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 100),
      ),
    );
  }
}