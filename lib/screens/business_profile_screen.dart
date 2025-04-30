import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import './business_info_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({Key? key}) : super(key: key);

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> with SingleTickerProviderStateMixin {
  String _businessNumber = '';
  String _ownerName = '';
  String _businessType = '';
  String _businessCategory = '';
  String? _businessImagePath;
  bool _isLoading = true;
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    _scrollController.addListener(_scrollListener);
    _loadBusinessInfo();
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  // 사업자번호 포맷팅 함수
  String _formatBusinessNumber(String value) {
    value = value.replaceAll('-', ''); // 기존 대시 제거

    if (value.length > 10) {
      value = value.substring(0, 10); // 최대 10자리로 제한
    }

    // 포맷팅: XXX-XX-XXXXX
    if (value.length >= 3) {
      String first = value.substring(0, 3);
      String rest = value.substring(3);

      if (rest.length >= 2) {
        String second = rest.substring(0, 2);
        String third = rest.substring(2);
        return '$first-$second-$third';
      } else {
        return '$first-$rest';
      }
    }

    return value;
  }

  Future<void> _loadBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 현재 로그인된 이메일 가져오기
    String currentEmail = prefs.getString('userEmail') ?? '';

    // 사업자번호 가져오기 및 포맷팅
    String businessNumber = prefs.getString('businessNumber_$currentEmail') ?? '';
    if (businessNumber.isNotEmpty) {
      businessNumber = _formatBusinessNumber(businessNumber);
    }

    setState(() {
      _businessNumber = businessNumber;
      _ownerName = prefs.getString('ownerName_$currentEmail') ?? '';
      _businessType = prefs.getString('businessType_$currentEmail') ?? '';
      _businessCategory = prefs.getString('businessCategory_$currentEmail') ?? '';
      _businessImagePath = prefs.getString('businessImagePath_$currentEmail');
      _isLoading = false;
    });
  }

  void _editBusinessInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusinessInfoScreen(isEditing: true),
      ),
    ).then((_) {
      // 편집 화면에서 돌아온 후 정보 다시 로드
      _loadBusinessInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.indigo,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            _buildBusinessInfoCard(),
          ],
        ),
      ),
    );
  }

  // 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: _isScrolled ? 4.0 : 0.0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: _isScrolled ? Colors.indigo : Colors.white,
      title: FadeIn(
        child: Text(
          '사업자 정보',
          style: TextStyle(
            color: _isScrolled ? Colors.white : Colors.indigo,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: _isScrolled ? Colors.white : Colors.indigo,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _editBusinessInfo,
          child: Text(
            '수정',
            style: TextStyle(
              color: _isScrolled ? Colors.white : Colors.indigo,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // 헤더 위젯
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
      ),
      child: FadeInDown(
        delay: const Duration(milliseconds: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '등록된 사업자 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '근로계약서 작성에 사용되는 사업자 정보입니다. 수정이 필요한 경우 우측 상단의 [수정] 버튼을 눌러주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 사업자 정보 카드 위젯
  Widget _buildBusinessInfoCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사업자 등록증 이미지
                if (_businessImagePath != null && _businessImagePath!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('사업자 등록증'),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.file(
                            File(_businessImagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),

                // 사업자 등록번호
                _buildInfoField(
                  label: '사업자 등록번호',
                  value: _businessNumber,
                  icon: Icons.business,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 20),

                // 사업주 성명
                _buildInfoField(
                  label: '사업주 성명',
                  value: _ownerName,
                  icon: Icons.person,
                  color: Colors.teal,
                ),
                const SizedBox(height: 20),

                // 업종
                _buildInfoField(
                  label: '업종',
                  value: _businessType,
                  icon: Icons.category,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),

                // 업태
                _buildInfoField(
                  label: '업태',
                  value: _businessCategory,
                  icon: Icons.store,
                  color: Colors.orange[700]!,
                ),
                const SizedBox(height: 32),

                // 수정 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _editBusinessInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      '사업자 정보 수정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 타이틀 위젯
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.indigo,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 정보 필드 위젯
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1.0,
            ),
          ),
          child: Text(
            value.isEmpty ? '정보 없음' : value,
            style: TextStyle(
              fontSize: 16,
              color: value.isEmpty ? Colors.grey[400] : Colors.black87,
              fontWeight: value.isEmpty ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}