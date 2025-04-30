import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import './main_screen.dart';

class BusinessInfoScreen extends StatefulWidget {
  final bool isEditing;

  const BusinessInfoScreen({Key? key, this.isEditing = false}) : super(key: key);

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNumberController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _businessCategoryController = TextEditingController();

  File? _businessImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isScrolled = false;
  String? _currentImagePath;

  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _scrollController.addListener(_scrollListener);

    if (widget.isEditing) {
      _loadBusinessInfo();
    }
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

  Future<void> _loadBusinessInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 현재 로그인된 이메일 가져오기
      String currentEmail = prefs.getString('userEmail') ?? '';

      // 저장된 사업자 정보 가져오기
      String businessNumber = prefs.getString('businessNumber_$currentEmail') ?? '';
      String ownerName = prefs.getString('ownerName_$currentEmail') ?? '';
      String businessType = prefs.getString('businessType_$currentEmail') ?? '';
      String businessCategory = prefs.getString('businessCategory_$currentEmail') ?? '';
      _currentImagePath = prefs.getString('businessImagePath_$currentEmail');

      // 사업자번호 포맷팅
      if (businessNumber.isNotEmpty) {
        _businessNumberController.text = _formatBusinessNumber(businessNumber);
      } else {
        _businessNumberController.text = businessNumber;
      }

      _ownerNameController.text = ownerName;
      _businessTypeController.text = businessType;
      _businessCategoryController.text = businessCategory;

      // 이미지 경로가 있으면 이미지 로드
      if (_currentImagePath != null && _currentImagePath!.isNotEmpty) {
        _businessImage = File(_currentImagePath!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보 로드 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        // 사업자번호에서 하이픈 제거 (저장 시)
        String businessNumber = _businessNumberController.text.replaceAll('-', '');

        // Shared Preferences에 사업자 정보 저장
        final prefs = await SharedPreferences.getInstance();

        // 현재 로그인된 이메일 가져오기
        String currentEmail = prefs.getString('userEmail') ?? '';

        // 이메일별로 사업자 정보 저장
        await prefs.setString('businessNumber_$currentEmail', businessNumber);
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
          if (widget.isEditing) {
            Navigator.pop(context); // 수정 모드일 경우 이전 화면으로 돌아감
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보 저장 중 오류가 발생했습니다: ${e.toString()}'),
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
  }

  @override
  void dispose() {
    _businessNumberController.dispose();
    _ownerNameController.dispose();
    _businessTypeController.dispose();
    _businessCategoryController.dispose();
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.isEditing) {
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
            _buildFormCard(),
          ],
        ),
      ),
    );
  }

  // AppBar 위젯
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: _isScrolled ? 4.0 : 0.0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: _isScrolled ? Colors.indigo : Colors.white,
      title: FadeIn(
        child: Text(
          widget.isEditing ? '사업자 정보 수정' : '사업자 정보 입력',
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
        delay: const Duration(milliseconds: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? '사업자 정보 수정' : '사업자 정보 등록',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '근로계약서 작성에 필요한 사업자 정보를 입력해주세요. 모든 정보는 계약서 작성에만 사용됩니다.',
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

  // 폼 카드 위젯
  Widget _buildFormCard() {
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사업자 번호
                  _buildFormField(
                    controller: _businessNumberController,
                    label: '사업자 등록번호',
                    hint: '000-00-00000',
                    icon: Icons.business,
                    color: Colors.indigo,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '사업자 등록번호를 입력해주세요';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 사업자번호 입력 시 자동 포맷팅
                      String formattedNumber = _formatBusinessNumber(value);
                      if (formattedNumber != value) {
                        _businessNumberController.value = TextEditingValue(
                          text: formattedNumber,
                          selection: TextSelection.collapsed(offset: formattedNumber.length),
                        );
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(12), // "000-00-00000" 형식으로 최대 12자
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), // 숫자와 하이픈만 허용
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 사업주 정보
                  _buildFormField(
                    controller: _ownerNameController,
                    label: '사업주 성명',
                    hint: '홍길동',
                    icon: Icons.person,
                    color: Colors.teal,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '사업주 성명을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 업종
                  _buildFormField(
                    controller: _businessTypeController,
                    label: '업종',
                    hint: '예: 서비스업',
                    icon: Icons.category,
                    color: Colors.deepPurple,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '업종을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 업태
                  _buildFormField(
                    controller: _businessCategoryController,
                    label: '업태',
                    hint: '예: 소프트웨어 개발',
                    icon: Icons.store,
                    color: Colors.orange[700]!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '업태를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 사업자 등록증 이미지 업로드
                  _buildSectionTitle(
                    '사업자 등록증 첨부',
                    Icons.file_upload,
                    Colors.blue[700]!,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '사업자 등록증 사본을 업로드해주세요. (선택사항)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 이미지 업로드 영역
                  FadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
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
                            ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _businessImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // 이미지 삭제 버튼
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _businessImage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.upload_file,
                                size: 32,
                                color: Colors.indigo[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '이미지 업로드하기',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.indigo[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '클릭하여 갤러리에서 선택',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 카메라 버튼
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.photo_camera, size: 20),
                      label: const Text('카메라로 촬영하기'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 확인 버튼
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBusinessInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
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
                            : Text(
                          widget.isEditing ? '저장' : '확인',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 타이틀 위젯
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
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

  // 입력 필드 위젯
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨과 아이콘
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 입력 필드
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
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
                color: Colors.grey[200]!,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: color,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[400]!,
                width: 1.5,
              ),
            ),
            errorStyle: TextStyle(
              color: Colors.red[400],
              fontSize: 12,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                icon,
                color: color.withOpacity(0.5),
                size: 18,
              ),
            ),
          ),
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
          ),
          onChanged: onChanged,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}