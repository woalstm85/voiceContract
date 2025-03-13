import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './business_info_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({Key? key}) : super(key: key);

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  String _businessNumber = '';
  String _ownerName = '';
  String _businessType = '';
  String _businessCategory = '';
  String? _businessImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
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
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.indigo,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '사업자 정보',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            fontFamily: 'NanumGothic',
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.indigo),
        actions: [
          TextButton(
            onPressed: _editBusinessInfo,
            child: const Text(
              '수정',
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'NanumGothic',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 설명 영역
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.indigo,
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        '사업자 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NanumGothic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '등록된 사업자 정보를 확인합니다. 수정이 필요한 경우 우측 상단의 수정 버튼을 눌러주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      fontFamily: 'NanumGothic',
                    ),
                  ),
                ],
              ),
            ),

            // 사업자 정보
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사업자 등록증 이미지
                  if (_businessImagePath != null && _businessImagePath!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '사업자 등록증',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'NanumGothic',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_businessImagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // 사업자 등록번호
                  _buildInfoSection(
                    label: '사업자 등록번호',
                    value: _businessNumber,
                  ),
                  const SizedBox(height: 24),

                  // 사업주 성명
                  _buildInfoSection(
                    label: '사업주 성명',
                    value: _ownerName,
                  ),
                  const SizedBox(height: 24),

                  // 업종
                  _buildInfoSection(
                    label: '업종',
                    value: _businessType,
                  ),
                  const SizedBox(height: 24),

                  // 업태
                  _buildInfoSection(
                    label: '업태',
                    value: _businessCategory,
                  ),
                  const SizedBox(height: 36),

                  // 수정 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _editBusinessInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        '사업자 정보 수정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NanumGothic',
                        ),
                      ),
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

  Widget _buildInfoSection({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'NanumGothic',
          ),
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
              color: Colors.grey[300]!,
            ),
          ),
          child: Text(
            value.isEmpty ? '정보 없음' : value,
            style: TextStyle(
              fontSize: 16,
              color: value.isEmpty ? Colors.grey[400] : Colors.black87,
              fontFamily: 'NanumGothic',
            ),
          ),
        ),
      ],
    );
  }
}