import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './main_screen.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({Key? key}) : super(key: key);

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNumberController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _businessCategoryController = TextEditingController();

  File? _businessImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _businessImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _businessImage = File(photo.path);
      });
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Shared Preferences에 사업자 정보 저장
        final prefs = await SharedPreferences.getInstance();

        // 현재 로그인된 이메일 가져오기
        String currentEmail = prefs.getString('userEmail') ?? '';

        // 이메일별로 사업자 정보 저장
        await prefs.setString('businessNumber_$currentEmail', _businessNumberController.text);
        await prefs.setString('ownerName_$currentEmail', _ownerNameController.text);
        await prefs.setString('businessType_$currentEmail', _businessTypeController.text);
        await prefs.setString('businessCategory_$currentEmail', _businessCategoryController.text);

        // 이미지 경로가 있으면 저장 (실제 앱에서는 Firebase Storage 등에 저장 필요)
        if (_businessImage != null) {
          await prefs.setString('businessImagePath_$currentEmail', _businessImage!.path);
        }

        // 데이터 저장 시뮬레이션을 위한 딜레이
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보 저장 중 오류가 발생했습니다: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _businessNumberController.dispose();
    _ownerNameController.dispose();
    _businessTypeController.dispose();
    _businessCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '사업자 정보 입력',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            fontFamily: 'NanumGothic',
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.indigo),
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
                        '사업자 정보 등록',
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
                    '근로계약서 작성에 필요한 사업자 정보를 입력해주세요. 모든 정보는 계약서 작성에만 사용됩니다.',
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

            // 폼 영역
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사업자 번호
                    _buildTextField(
                      controller: _businessNumberController,
                      label: '사업자 등록번호',
                      hint: '000-00-00000',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '사업자 등록번호를 입력해주세요';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // 사업주 정보
                    _buildTextField(
                      controller: _ownerNameController,
                      label: '사업주 성명',
                      hint: '홍길동',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '사업주 성명을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 업종
                    _buildTextField(
                      controller: _businessTypeController,
                      label: '업종',
                      hint: '예: 서비스업',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '업종을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 업태
                    _buildTextField(
                      controller: _businessCategoryController,
                      label: '업태',
                      hint: '예: 소프트웨어 개발',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '업태를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // 사업자 등록증 이미지 업로드
                    const Text(
                      '사업자 등록증 첨부',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'NanumGothic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '사업자 등록증 사본을 업로드해주세요. (선택사항)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'NanumGothic',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 이미지 업로드 영역
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: _businessImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _businessImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 48,
                              color: Colors.indigo[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '이미지 업로드하기',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.indigo[400],
                                fontWeight: FontWeight.w500,
                                fontFamily: 'NanumGothic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카메라 버튼
                    Center(
                      child: TextButton.icon(
                        onPressed: _takePhoto,
                        icon: Icon(Icons.photo_camera, color: Colors.indigo),
                        label: Text(
                          '카메라로 촬영하기',
                          style: TextStyle(
                            color: Colors.indigo,
                            fontFamily: 'NanumGothic',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBusinessInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          '확인',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
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
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'NanumGothic',
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.indigo,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
          ),
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'NanumGothic',
          ),
        ),
      ],
    );
  }
}