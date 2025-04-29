import 'package:flutter/material.dart';


class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitInquiry() {
    if (_formKey.currentState!.validate()) {
      // 실제 구현에서는 여기서 문의사항을 서버로 전송
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문의가 접수되었습니다. 빠른 시일 내에 답변 드리겠습니다.'),
          backgroundColor: Colors.indigo,
        ),
      );

      // 폼 초기화
      _titleController.clear();
      _contentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문의하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.indigo.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.indigo,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '서비스 이용 중 궁금하신 점이나 불편한 사항을 남겨주시면 빠르게 답변 드리겠습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 문의 방법 섹션
              const Text(
                '문의 방법',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

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
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 입력
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.indigo, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '제목을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 내용 입력
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.indigo, width: 2),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '문의 내용을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitInquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '문의하기',
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
            ],
          ),
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.indigo,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
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